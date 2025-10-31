#!/bin/bash

# RNA-seq Pipeline Runner for AWS Batch
# This script sets up infrastructure and runs the nf-core RNA-seq pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"
CONFIG_DIR="$SCRIPT_DIR/config"
PIPELINE_URL="https://github.com/nf-core/rnaseq"
PROFILE="test"
CFN_TEMPLATE="$CONFIG_DIR/cloudformation.yaml"
STACK_NAME="tracer-rnaseq-batch"

# Default bucket names (can be overridden by environment variables)
WORK_BUCKET_NAME="${WORK_BUCKET_NAME:-tracer-nxf-work}"
OUTPUTS_BUCKET_NAME="${OUTPUTS_BUCKET_NAME:-tracer-nxf-outputs}"
ENVIRONMENT_NAME="${ENVIRONMENT_NAME:-rnaseq}"
CREATE_INSTANCE_CONNECT_ENDPOINT="${CREATE_INSTANCE_CONNECT_ENDPOINT:-false}"
BUCKET_SUFFIX="${BUCKET_SUFFIX:-}"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check Nextflow
    if ! command -v nextflow &> /dev/null; then
        print_warning "Nextflow is not installed. Installing now..."
        curl -s https://get.nextflow.io | bash
        export PATH="$PWD:$PATH"
    fi
    
    print_success "Prerequisites check completed"
}

# Function to setup infrastructure
setup_infrastructure() {
    print_status "Setting up AWS infrastructure..."
    
    if [[ "${USE_CFN:-false}" == "true" ]]; then
        print_status "Deploying CloudFormation stack: $STACK_NAME"
        # aws cloudformation deploy \
        #     --stack-name "$STACK_NAME" \
        #     --template-file "$CFN_TEMPLATE" \
        #     --capabilities CAPABILITY_NAMED_IAM \
        #     --no-fail-on-empty-changeset | cat

        print_status "Retrieving CloudFormation resources..."
        # Buckets are static names in template
        WORK_BUCKET="tracer-nxf-work"
        OUTPUTS_BUCKET="tracer-nxf-outputs"
        # Queue name from template
        BATCH_QUEUE="NextflowCPU"
    else
        cd "$TERRAFORM_DIR"
        print_status "Initializing Terraform..."
        terraform init
        print_status "Planning Terraform deployment..."
        terraform plan \
            -var="work_bucket_name=$WORK_BUCKET_NAME" \
            -var="outputs_bucket_name=$OUTPUTS_BUCKET_NAME" \
            -var="environment_name=$ENVIRONMENT_NAME" \
            -var="create_instance_connect_endpoint=$CREATE_INSTANCE_CONNECT_ENDPOINT" \
            -var="bucket_suffix=$BUCKET_SUFFIX" \
            -var="create_batch_service_linked_role=false" \
            -out=tfplan
        print_status "Applying Terraform configuration..."
        terraform apply tfplan
        print_status "Getting infrastructure outputs..."
        WORK_BUCKET=$(terraform output -raw work_bucket)
        OUTPUTS_BUCKET=$(terraform output -raw outputs_bucket)
        BATCH_QUEUE=$(terraform output -raw batch_cpu_job_queue_name)
        cd "$SCRIPT_DIR"
    fi

    export WORK_BUCKET
    export OUTPUTS_BUCKET
    export BATCH_QUEUE

    print_success "Infrastructure setup completed"
    print_status "Work bucket: $WORK_BUCKET"
    print_status "Outputs bucket: $OUTPUTS_BUCKET"
    print_status "Batch queue: $BATCH_QUEUE"
}

# Function to create sample data
create_sample_data() {
    print_status "Creating sample data..."
    
    # Create samplesheet if it doesn't exist
    if [ ! -f "samplesheet.csv" ]; then
        cat > samplesheet.csv << 'EOF'
sample,fastq_1,fastq_2,strandedness
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz,forward
CONTROL_REP2,AEG588A1_S1_L003_R1_001.fastq.gz,AEG588A1_S1_L003_R2_001.fastq.gz,forward
EOF
        print_success "Created samplesheet.csv"
    fi
    
    # Create test fastq files (empty for testing)
    mkdir -p fastq
    touch fastq/AEG588A1_S1_L002_R1_001.fastq.gz
    touch fastq/AEG588A1_S1_L002_R2_001.fastq.gz
    touch fastq/AEG588A1_S1_L003_R1_001.fastq.gz
    touch fastq/AEG588A1_S1_L003_R2_001.fastq.gz
    
    print_success "Sample data created"
}

# Function to validate infrastructure
validate_infrastructure() {
    print_status "Validating AWS Batch infrastructure..."
    
    # Check if AWS Batch queues exist and are available
    print_status "Checking AWS Batch queue: $BATCH_QUEUE"
    if aws batch describe-job-queues --job-queues "$BATCH_QUEUE" --query 'jobQueues[0].state' --output text 2>/dev/null | grep -q "ENABLED"; then
        print_success "Batch queue $BATCH_QUEUE is ENABLED"
    else
        print_error "Batch queue $BATCH_QUEUE is not available or not enabled"
        return 1
    fi
    
    # Check compute environment
    COMPUTE_ENV=$(aws batch describe-job-queues --job-queues "$BATCH_QUEUE" --query 'jobQueues[0].computeEnvironmentOrder[0].computeEnvironment' --output text 2>/dev/null)
    if [ -n "$COMPUTE_ENV" ]; then
        print_status "Checking compute environment: $COMPUTE_ENV"
        COMPUTE_STATE=$(aws batch describe-compute-environments --compute-environments "$COMPUTE_ENV" --query 'computeEnvironments[0].state' --output text 2>/dev/null)
        if [ "$COMPUTE_STATE" = "ENABLED" ]; then
            print_success "Compute environment is ENABLED"
        else
            print_warning "Compute environment state: $COMPUTE_STATE"
        fi
    fi
    
    # Check S3 buckets
    print_status "Checking S3 buckets..."
    if aws s3 ls "s3://$WORK_BUCKET" >/dev/null 2>&1; then
        print_success "Work bucket s3://$WORK_BUCKET is accessible"
    else
        print_error "Cannot access work bucket s3://$WORK_BUCKET"
        return 1
    fi
    
    if aws s3 ls "s3://$OUTPUTS_BUCKET" >/dev/null 2>&1; then
        print_success "Outputs bucket s3://$OUTPUTS_BUCKET is accessible"
    else
        print_error "Cannot access outputs bucket s3://$OUTPUTS_BUCKET"
        return 1
    fi
    
    print_success "Infrastructure validation completed"
}

# Function to run the pipeline
run_pipeline() {
    print_status "Running RNA-seq pipeline..."
    
    # Check if infrastructure variables are set, if not fetch them from terraform
    if [ -z "$WORK_BUCKET" ] || [ -z "$BATCH_QUEUE" ]; then
        print_status "Infrastructure variables not found in environment. Fetching from Terraform..."
        
        if [ -d "$TERRAFORM_DIR" ] && [ -f "$TERRAFORM_DIR/terraform.tfstate" ]; then
            cd "$TERRAFORM_DIR"
            
            # Get the outputs
            WORK_BUCKET=$(terraform output -raw work_bucket)
            OUTPUTS_BUCKET=$(terraform output -raw outputs_bucket)
            BATCH_QUEUE=$(terraform output -raw batch_cpu_job_queue_name)
            
            # Export variables for the pipeline
            export WORK_BUCKET
            export OUTPUTS_BUCKET
            export BATCH_QUEUE
            
            print_success "Retrieved infrastructure variables:"
            print_status "Work bucket: $WORK_BUCKET"
            print_status "Outputs bucket: $OUTPUTS_BUCKET"
            print_status "Batch queue: $BATCH_QUEUE"
            
            cd "$SCRIPT_DIR"
        else
            print_error "No infrastructure found. Run './run.sh setup' first."
            exit 1
        fi
    fi
    
    # Validate infrastructure before running pipeline
    if ! validate_infrastructure; then
        print_error "Infrastructure validation failed. Please check your AWS Batch setup."
        exit 1
    fi
    
    # Job definitions are now unique per run - no cleanup needed
    
    # Update the parameters file with the actual output bucket
    if [ -f "$CONFIG_DIR/rnaseq-params.json" ]; then
        print_status "Updating parameters file with S3 bucket information..."
        sed -i.bak "s/OUTPUTS_BUCKET_PLACEHOLDER/$OUTPUTS_BUCKET/g" "$CONFIG_DIR/rnaseq-params.json"
    fi
    
    # Clean up any previous runs
    print_status "Cleaning up previous run artifacts..."
    rm -f .nextflow.log*
    rm -rf .nextflow/
    rm -rf work/
    
    # Run the pipeline with better error handling
    print_status "Starting nf-core RNA-seq pipeline..."
    print_status "Pipeline configuration:"
    print_status "  Config: $CONFIG_DIR/batch.config"
    print_status "  Params: $CONFIG_DIR/rnaseq-params.json"
    print_status "  Profile: $PROFILE"
    print_status "  Work dir: s3://$WORK_BUCKET/work"
    print_status "  Queue: $BATCH_QUEUE"
    
    # Set Nextflow configuration with unique work directory
    WORK_DIR_TIMESTAMP="run-$(date +%Y%m%d-%H%M%S)"
    
    # Run the pipeline with original biocontainers
    if nextflow -c $CONFIG_DIR/batch.config run https://github.com/nf-core/rnaseq \
        -r 3.20.0 \
        -params-file "$CONFIG_DIR/rnaseq-params.json" \
        -profile "$PROFILE" \
        -work-dir "s3://$WORK_BUCKET/work/$WORK_DIR_TIMESTAMP" \
        -with-trace \
        -with-report \
        -with-timeline \
        -with-dag; then

        print_success "Pipeline completed successfully"
        
        # Copy outputs to S3
        if [ -d "output" ]; then
            print_status "Uploading outputs to S3..."
            aws s3 sync output/ "s3://$OUTPUTS_BUCKET/output/" --delete
            print_success "Outputs uploaded to s3://$OUTPUTS_BUCKET/output/"
        fi
    else
        print_error "Pipeline failed. Check .nextflow.log for details"
        
        # Show recent log entries for debugging
        if [ -f ".nextflow.log" ]; then
            print_status "Last 50 lines of .nextflow.log:"
            tail -50 .nextflow.log
        fi
        
        exit 1
    fi
}

# Function to cleanup infrastructure
cleanup_infrastructure() {
    print_warning "This will destroy all AWS resources. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_status "Cleaning up infrastructure..."
        cd "$TERRAFORM_DIR"
        terraform destroy -auto-approve -refresh=false
        cd "$SCRIPT_DIR"
        print_success "Infrastructure cleaned up"
    else
        print_status "Cleanup cancelled"
    fi
}

# Function to show status
show_status() {
    print_status "Checking infrastructure status..."
    
    if [ -d "$TERRAFORM_DIR" ] && [ -f "$TERRAFORM_DIR/terraform.tfstate" ]; then
        cd "$TERRAFORM_DIR"
        terraform show
        cd "$SCRIPT_DIR"
    else
        print_warning "No infrastructure found. Run './run.sh setup' first."
    fi
}

# Function to debug AWS Batch
debug_batch() {
    print_status "Debugging AWS Batch infrastructure..."
    
    if [ -z "$BATCH_QUEUE" ]; then
        refresh_variables
    fi
    
    # Check job queue details
    print_status "Job Queue Details:"
    aws batch describe-job-queues --job-queues "$BATCH_QUEUE" --output table
    
    # Check compute environment
    COMPUTE_ENV=$(aws batch describe-job-queues --job-queues "$BATCH_QUEUE" --query 'jobQueues[0].computeEnvironmentOrder[0].computeEnvironment' --output text 2>/dev/null)
    if [ -n "$COMPUTE_ENV" ]; then
        print_status "Compute Environment Details:"
        aws batch describe-compute-environments --compute-environments "$COMPUTE_ENV" --output table
    fi
    
    # Check recent job submissions
    print_status "Recent Job Submissions (last 10):"
    aws batch list-jobs --job-queue "$BATCH_QUEUE" --max-items 10 --output table
    
    # Check ECS cluster
    print_status "ECS Cluster Details:"
    aws ecs describe-clusters --clusters tracer-batch-cluster --output table
    
    # Check container instances
    print_status "ECS Container Instances:"
    aws ecs list-container-instances --cluster tracer-batch-cluster --output table
    
    # Check if there are any instances registered
    INSTANCE_ARNS=$(aws ecs list-container-instances --cluster tracer-batch-cluster --query 'containerInstanceArns' --output text)
    if [ -n "$INSTANCE_ARNS" ] && [ "$INSTANCE_ARNS" != "None" ]; then
        print_status "Container Instance Details:"
        aws ecs describe-container-instances --cluster tracer-batch-cluster --container-instances $INSTANCE_ARNS --output table
    else
        print_warning "No container instances registered with ECS cluster"
    fi
}

# Function to clean up old job definitions
cleanup_job_definitions() {
    print_status "Cleaning up old job definitions..."
    
    # List all active job definitions
    JOB_DEFS=$(aws batch describe-job-definitions --status ACTIVE --query 'jobDefinitions[].jobDefinitionName' --output text 2>/dev/null)
    
    if [ -n "$JOB_DEFS" ]; then
        for job_def in $JOB_DEFS; do
            # Deregister old job definitions that might contain Wave entrypoints
            if [[ "$job_def" == *"nf-"* ]] || [[ "$job_def" == *"nextflow"* ]] || [[ "$job_def" == *"tracer"* ]]; then
                print_status "Deregistering old job definition: $job_def"
                aws batch deregister-job-definition --job-definition "$job_def" 2>/dev/null || true
            fi
        done
        print_success "Cleaned up old job definitions"
    else
        print_status "No job definitions found to clean up"
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup     - Setup AWS infrastructure (VPC, S3, Batch, etc.)"
    echo "  run       - Run the RNA-seq pipeline with local config"
    echo "  tracer run - Run the RNA-seq pipeline with shared batch config"
    echo "  tracer run prod - Run the RNA-seq pipeline with production batch config"
    echo "  cleanup   - Destroy AWS infrastructure"
    echo "  status    - Show infrastructure status"
    echo "  config    - Show current configuration"
    echo "  refresh   - Refresh infrastructure variables from Terraform"
    echo "  debug     - Debug AWS Batch infrastructure"
    echo "  validate  - Validate infrastructure without running pipeline"
    echo "  clean-jobs - Clean up old job definitions"
    echo "  help      - Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  WORK_BUCKET_NAME    - S3 work bucket name (default: tracer-nxf-work)"
    echo "  OUTPUTS_BUCKET_NAME - S3 outputs bucket name (default: tracer-nxf-outputs)"
    echo "  ENVIRONMENT_NAME    - Environment name (default: rnaseq)"
    echo "  BUCKET_SUFFIX       - Custom suffix for bucket names (default: auto-generated)"
    echo "  CREATE_INSTANCE_CONNECT_ENDPOINT - Create EC2 Instance Connect Endpoint (default: false)"
    echo ""
    echo "Examples:"
    echo "  $0 setup          # Setup infrastructure first"
    echo "  $0 run            # Run the pipeline with local config"
    echo "  $0 tracer run     # Run the pipeline with shared batch config"
    echo "  $0 tracer run prod # Run the pipeline with production batch config"
    echo "  $0 debug          # Debug AWS Batch issues"
    echo "  $0 validate       # Validate infrastructure"
    echo "  $0 cleanup        # Clean up everything"
    echo "  WORK_BUCKET_NAME=my-work-bucket $0 setup  # Custom bucket names"
}

# Function to show current configuration
show_config() {
    print_status "Current Configuration:"
    echo "  Work Bucket: $WORK_BUCKET_NAME"
    echo "  Outputs Bucket: $OUTPUTS_BUCKET_NAME"
    echo "  Environment: $ENVIRONMENT_NAME"
    echo "  Bucket Suffix: ${BUCKET_SUFFIX:-auto-generated}"
    echo "  Create Instance Connect Endpoint: $CREATE_INSTANCE_CONNECT_ENDPOINT"
    echo "  Pipeline URL: $PIPELINE_URL"
    echo "  Profile: $PROFILE"
    echo ""
    print_status "To customize, set environment variables:"
    echo "  export WORK_BUCKET_NAME=my-custom-work-bucket"
    echo "  export OUTPUTS_BUCKET_NAME=my-custom-outputs-bucket"
    echo "  export ENVIRONMENT_NAME=my-environment"
    echo "  export BUCKET_SUFFIX=my-suffix"
    echo "  export CREATE_INSTANCE_CONNECT_ENDPOINT=true"
}

# Function to refresh infrastructure variables
refresh_variables() {
    print_status "Refreshing infrastructure variables from Terraform..."
    
    if [ -d "$TERRAFORM_DIR" ] && [ -f "$TERRAFORM_DIR/terraform.tfstate" ]; then
        cd "$TERRAFORM_DIR"
        
        # Get the outputs
        WORK_BUCKET=$(terraform output -raw work_bucket)
        OUTPUTS_BUCKET=$(terraform output -raw outputs_bucket)
        BATCH_QUEUE=$(terraform output -raw batch_cpu_job_queue_name)
        
        # Export variables for the pipeline
        export WORK_BUCKET
        export OUTPUTS_BUCKET
        export BATCH_QUEUE
        
        print_success "Infrastructure variables refreshed:"
        print_status "Work bucket: $WORK_BUCKET"
        print_status "Outputs bucket: $OUTPUTS_BUCKET"
        print_status "Batch queue: $BATCH_QUEUE"
        
        cd "$SCRIPT_DIR"
    else
        print_error "No infrastructure found. Run './run.sh setup' first."
        exit 1
    fi
}

# Function to run pipeline in Tracer AWS account
run_tracer_pipeline() {
    local environment="${1:-dev}"
    
    if [ "$environment" = "prod" ]; then
        print_status "Running RNA-seq pipeline with Tracer production configuration"
        SHARED_BATCH_CONFIG="$SCRIPT_DIR/../../nextflow/config/batch.prod.config"
    else
        print_status "Running RNA-seq pipeline with Tracer configuration"
        SHARED_BATCH_CONFIG="$SCRIPT_DIR/../../shared/nextflow/config/batch.config"
    fi
    
    # Validate config file exists
    if [ ! -f "$SHARED_BATCH_CONFIG" ]; then
        print_error "Config file not found: $SHARED_BATCH_CONFIG"
        exit 1
    fi
    
    print_status "Using config: $SHARED_BATCH_CONFIG"
    
    # Run the pipeline with shared batch configuration
    if nextflow -c "$SHARED_BATCH_CONFIG" run https://github.com/nf-core/rnaseq \
        -r 3.20.0 \
        -params-file "$CONFIG_DIR/rnaseq-params.json" \
        -profile "$PROFILE" \
        -with-dag; then

        print_success "Pipeline completed successfully"
   
    else
        print_error "Pipeline failed. Check .nextflow.log for details"
        
        # Show recent log entries for debugging
        if [ -f ".nextflow.log" ]; then
            print_status "Last 50 lines of .nextflow.log:"
            tail -50 .nextflow.log
        fi
        
        exit 1
    fi
}

# Main script logic
case "${1:-help}" in
    setup)
        check_prerequisites
        setup_infrastructure
        create_sample_data
        ;;
    run)
        run_pipeline
        ;;
    tracer)
        if [ "$2" = "run" ]; then
            if [ "$3" = "prod" ]; then
                run_tracer_pipeline "prod"
            else
                run_tracer_pipeline "dev"
            fi
        else
            print_error "Usage: $0 tracer run [prod]"
            exit 1
        fi
        ;;
    cleanup)
        cleanup_infrastructure
        ;;
    status)
        show_status
        ;;
    config)
        show_config
        ;;
    refresh)
        refresh_variables
        ;;
    debug)
        debug_batch
        ;;
    validate)
        refresh_variables
        validate_infrastructure
        ;;
    clean-jobs)
        cleanup_job_definitions
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac

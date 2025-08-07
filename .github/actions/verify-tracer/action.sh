#!/bin/bash

# Inline version of verify-tracer action for just amazon linux
BINARY="tracer"

# Parse command line arguments
REQUIRED_PROCESSES_EBPF="${1:-samtools faidx, samtools flagstat, samtools view, FastQC, samtools merge, samtools index, samtools sort, samtools cat, samtools idxstats, samtools stats}"
REQUIRED_PROCESSES_POLLING="${2:-samtools faidx, samtools flagstat, samtools view, FastQC, samtools merge, samtools index, samtools sort, samtools cat, samtools idxstats, samtools stats}"
IS_EBPF="${3:-true}"

# Select required processes based on eBPF mode
if [ "$IS_EBPF" = "true" ]; then
  REQUIRED_PROCESSES="$REQUIRED_PROCESSES_EBPF"
  echo "Using eBPF mode - Required processes: $REQUIRED_PROCESSES"
else
  REQUIRED_PROCESSES="$REQUIRED_PROCESSES_POLLING"
  echo "Using non-eBPF mode - Required processes: $REQUIRED_PROCESSES"
fi

sudo yum install -y jq findutils

echo "=== Waiting 10 seconds for tracer to gather process information ==="
sleep 10

echo "=== Running tracer info --json ==="

CMD="sudo $BINARY info --json"

echo "Running command: $CMD"

OUTPUT=$($CMD)
echo "$OUTPUT"

echo ""
echo "=== Verifying required processes ==="

# Parse the processes field from the JSON output
PROCESSES=$(echo "$OUTPUT" | jq -r '.run.processes // empty')

if [ -z "$PROCESSES" ]; then
  echo "❌ ERROR: Could not find 'processes' in output"
  echo "This might indicate the pipeline cannot find any processes at all"
  exit 1
fi

echo "Found processes: $PROCESSES"

# Convert comma-separated required processes to array
IFS=',' read -ra REQUIRED_ARRAY <<< "$REQUIRED_PROCESSES"

# Check each required process (exact match, order-independent)
MISSING_PROCESSES=()

for required_process in "${REQUIRED_ARRAY[@]}"; do
  # Trim whitespace
  required_process=$(echo "$required_process" | xargs)
  
  # Check if this required process exists in the processes string
  if echo "$PROCESSES" | grep -q "$required_process"; then
    echo "✅ Found required process: $required_process"
  else
    echo "❌ Missing required process: $required_process"
    MISSING_PROCESSES+=("$required_process")
  fi

done

# Report results
if [ ${#MISSING_PROCESSES[@]} -eq 0 ]; then
  echo ""
  echo "🎉 SUCCESS: All required processes found in processes"
  echo "Required: $REQUIRED_PROCESSES"
  echo "Found: $PROCESSES"
else
  echo ""
  echo "❌ FAILURE: Missing required processes"
  echo "Required: $REQUIRED_PROCESSES"
  echo "Found: $PROCESSES"
  echo "Missing: $(IFS=','; echo "${MISSING_PROCESSES[*]}")"
  exit 1
fi

#!/bin/bash

# Inline version of verify-tracer action for just amazon linux
BINARY="/usr/local/bin/tracer"

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

echo "=== Installing jq ==="
if command -v jq >/dev/null 2>&1; then
  echo "jq is already installed"
elif command -v yum >/dev/null 2>&1; then
  if yum install -y jq findutils 2>/dev/null; then
    echo "Installed jq without sudo"
  else
    echo "Attempting to install jq with sudo..."
    if sudo yum install -y jq findutils 2>/dev/null; then
      echo "Installed jq with sudo"
    else
      echo "Warning: Could not install jq. Will try to use alternative JSON parsing."
    fi
  fi
elif command -v apt-get >/dev/null 2>&1; then
  if apt-get update && apt-get install -y jq 2>/dev/null; then
    echo "Installed jq without sudo"
  else
    echo "Warning: Could not install jq. Will try to use alternative JSON parsing."
  fi
else
  echo "Warning: Could not install jq. Will try to use alternative JSON parsing."
fi

echo "=== Waiting 10 seconds for tracer to gather process information ==="
sleep 10

echo "=== Running tracer info --json ==="

CMD="$BINARY info --json"
echo "Running command: $CMD"

OUTPUT=$($CMD 2>/dev/null)

if [ $? -ne 0 ]; then
  echo "❌ ERROR: Failed to run tracer command"
  echo "Output: $OUTPUT"
  exit 1
fi

echo ""
echo "=== Verifying required processes ==="

# Parse the processes field from the JSON output
if command -v jq >/dev/null 2>&1; then
  PROCESSES=$(echo "$OUTPUT" | jq -r '.run.processes // empty')
else
  # Fallback JSON parsing using grep and sed
  echo "Using fallback JSON parsing (jq not available)"
  PROCESSES=$(echo "$OUTPUT" | grep -o '"processes":[^,}]*' | sed 's/"processes":"//' | sed 's/"//')
fi

if [ -z "$PROCESSES" ]; then
  echo "❌ ERROR: Could not find 'processes' in output"
  echo "This might indicate the pipeline cannot find any processes at all"
  echo "Raw output: $OUTPUT"
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

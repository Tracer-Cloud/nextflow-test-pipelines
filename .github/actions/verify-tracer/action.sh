#!/bin/bash

# Inline version of verify-tracer action for just amazon linux
BINARY="/root/.tracerbio/bin/tracer"

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

# Convert processes to array (split by comma and trim whitespace)
IFS=',' read -ra PROCESSES_ARRAY <<< "$PROCESSES"
PROCESSES_SET=()
for proc in "${PROCESSES_ARRAY[@]}"; do
  # Trim whitespace and add to set
  trimmed=$(echo "$proc" | xargs)
  if [ -n "$trimmed" ]; then
    PROCESSES_SET+=("$trimmed")
  fi
done

echo "Parsed processes: ${PROCESSES_SET[*]}"

# Convert comma-separated required processes to array
IFS=',' read -ra REQUIRED_ARRAY <<< "$REQUIRED_PROCESSES"

# Check each required process (exact match, order-independent)
MISSING_PROCESSES=()

IS_MACOS=false
if [ "$(uname)" = "Darwin" ]; then
  IS_MACOS=true
fi

if [ "$IS_EBPF" = "false" ] && [ "$IS_MACOS" = "true" ]; then
  PROC_COUNT=${#PROCESSES_SET[@]}
  echo "macOS process polling mode: found $PROC_COUNT processes"
  if [ "$PROC_COUNT" -ge 3 ] && [ "$PROC_COUNT" -le 4 ]; then
    echo "\n SUCCESS: Found $PROC_COUNT processes (in allowed range 3-4)"
    echo "Found: $PROCESSES"
    exit 0
  else
    echo "\n FAILURE: Found $PROC_COUNT processes (not in allowed range 3-4)"
    echo "Found: $PROCESSES"
    exit 1
  fi
fi

for required_process in "${REQUIRED_ARRAY[@]}"; do
  # Trim whitespace
  required_process=$(echo "$required_process" | xargs)
  
  # Check if this required process exists in the set
  found=false
  for process in "${PROCESSES_SET[@]}"; do
    if [ "$required_process" = "$process" ]; then
      found=true
      break
    fi
  done
  
  if [ "$found" = true ]; then
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

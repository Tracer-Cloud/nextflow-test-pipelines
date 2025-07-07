#!/bin/bash

# Inline version of verify-tracer action
# Usage: ./verify-tracer.sh [IS_EBPF] [USE_SUDO] [BINARY]

# Set input parameters (can be overridden by command line args or env vars)
IS_EBPF="${1:-${IS_EBPF:-true}}"
USE_SUDO="${3:-${USE_SUDO:-true}}"
BINARY="${4:-${BINARY:-/root/.tracerbio/bin/tracer}}"

# Set environment variables
TRACER_REQUIRED_PROCESSES_EBPF='STAR,FastQC,samtools sort'
TRACER_REQUIRED_PROCESSES_POLLING='STAR,FastQC,salmon'

echo "=== Verify Tracer Packages ==="
echo "Parameters: IS_EBPF=$IS_EBPF, USE_SUDO=$USE_SUDO, BINARY=$BINARY"

# Install jq if needed
if command -v apt-get &> /dev/null; then
  echo "Using apt-get (Debian/Ubuntu)..."
  sudo apt-get update && sudo apt-get install -y jq
fi

echo "=== Waiting 5 seconds for tracer to gather process information ==="
sleep 5

echo "=== Running tracer info --json ==="

# Build tracer command
TRACER_CMD="$BINARY info --json"

if [ "$USE_SUDO" = "true" ]; then
  TRACER_CMD="sudo $TRACER_CMD"
fi 

echo "Running tracer command: $TRACER_CMD"

TRACER_OUTPUT=$($TRACER_CMD)
echo "$TRACER_OUTPUT"

echo ""
echo "=== Verifying required processes ==="

# Parse the processes field from the JSON output
PROCESSES=$(echo "$TRACER_OUTPUT" | jq -r '.run.processes // empty')

if [ -z "$PROCESSES" ]; then
  echo "❌ ERROR: Could not find 'processes' in tracer output"
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

# Select required processes based on eBPF mode
if [ "$IS_EBPF" = "true" ]; then
  required_processes="$TRACER_REQUIRED_PROCESSES_EBPF"
  echo "Using eBPF mode - Required processes: $required_processes"
else
  required_processes="$TRACER_REQUIRED_PROCESSES_POLLING"
  echo "Using non-eBPF mode - Required processes: $required_processes"
fi

# Convert comma-separated required processes to array
IFS=',' read -ra REQUIRED_ARRAY <<< "$required_processes"

# Check each required process (exact match, order-independent)
MISSING_PROCESSES=()
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
  echo "Required: $required_processes"
  echo "Found: $PROCESSES"
else
  echo ""
  echo "❌ FAILURE: Missing required processes"
  echo "Required: $required_processes"
  echo "Found: $PROCESSES"
  echo "Missing: $(IFS=','; echo "${MISSING_PROCESSES[*]}")"
  exit 1
fi

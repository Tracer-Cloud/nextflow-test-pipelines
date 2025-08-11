#!/bin/bash

BINARY="tracer"

REQUIRED_PROCESSES_EBPF="${1:-samtools faidx, samtools flagstat, samtools view, FastQC, samtools merge, samtools index, samtools sort, samtools cat, samtools idxstats, samtools stats}"
REQUIRED_PROCESSES_POLLING="${2:-samtools faidx, samtools flagstat, samtools view, FastQC, samtools merge, samtools index, samtools sort, samtools cat, samtools idxstats, samtools stats}"
IS_EBPF="${3:-true}"

if [ "$IS_EBPF" = "true" ]; then
  REQUIRED_PROCESSES="$REQUIRED_PROCESSES_EBPF"
  echo "Using eBPF mode - Required processes: $REQUIRED_PROCESSES"
else
  REQUIRED_PROCESSES="$REQUIRED_PROCESSES_POLLING"
  echo "Using non-eBPF mode - Required processes: $REQUIRED_PROCESSES"
fi

echo "Installing jq"
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

echo "Waiting 10 seconds for tracer to gather process information"
sleep 10

echo "Running tracer info --json"

CMD="$BINARY info --json"
echo "Running command: $CMD"

OUTPUT=$($CMD 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "First attempt failed with exit code: $EXIT_CODE"
  echo "Output: $OUTPUT"
  echo ""
  echo "Trying with sudo..."
  
  CMD="sudo $BINARY info --json"
  echo "Running command: $CMD"
  
  OUTPUT=$(sudo $BINARY info --json 2>&1)
  EXIT_CODE=$?
  
  if [ $EXIT_CODE -ne 0 ]; then
    echo "ERROR: Failed to run tracer command with both regular and sudo"
    echo "Exit code: $EXIT_CODE"
    echo "Output: $OUTPUT"
    echo ""
    echo "Checking if tracer binary exists and is executable..."
    ls -la $(which tracer 2>/dev/null || echo "tracer not found in PATH")
    exit 1
  else
    echo "Successfully ran tracer with sudo"
  fi
else
  echo "Successfully ran tracer without sudo"
fi

echo ""
echo "Full JSON Output from tracer info --json"
echo "$OUTPUT"
echo "End of JSON Output"
echo ""

if command -v jq >/dev/null 2>&1; then
  echo "Validating JSON format"
  if echo "$OUTPUT" | jq . >/dev/null 2>&1; then
    echo "JSON is valid"
  else
    echo "ERROR: Invalid JSON format"
    echo "Raw output: $OUTPUT"
    exit 1
  fi
  
  echo ""
  echo "Pretty-printed JSON"
  echo "$OUTPUT" | jq .
  echo "End of Pretty-printed JSON"
  echo ""
else
  echo "jq not available, skipping JSON validation and pretty-printing"
fi

echo "Verifying required processes"

if command -v jq >/dev/null 2>&1; then
  PROCESSES=$(echo "$OUTPUT" | jq -r '.run.processes // empty')
  
  RUN_INFO=$(echo "$OUTPUT" | jq -r '.run // empty')
  VERSION=$(echo "$OUTPUT" | jq -r '.version // empty')
  
  echo "Tracer version: $VERSION"
  echo "Run information: $RUN_INFO"
  
else
  echo "Using fallback JSON parsing (jq not available)"
  PROCESSES=$(echo "$OUTPUT" | grep -o '"processes":[^,}]*' | sed 's/"processes":"//' | sed 's/"//')
fi

if [ -z "$PROCESSES" ]; then
  echo "ERROR: Could not find 'processes' in output"
  echo "This might indicate the pipeline cannot find any processes at all"
  echo "Raw output: $OUTPUT"
  exit 1
fi

echo "Found processes: $PROCESSES"

IFS=',' read -ra REQUIRED_ARRAY <<< "$REQUIRED_PROCESSES"

MISSING_PROCESSES=()

for required_process in "${REQUIRED_ARRAY[@]}"; do
  required_process=$(echo "$required_process" | xargs)
  
  if echo "$PROCESSES" | grep -q "$required_process"; then
    echo "Found required process: $required_process"
  else
    echo "Missing required process: $required_process"
    MISSING_PROCESSES+=("$required_process")
  fi

done

if [ ${#MISSING_PROCESSES[@]} -eq 0 ]; then
  echo ""
  echo "SUCCESS: All required processes found in processes"
  echo "Required: $REQUIRED_PROCESSES"
  echo "Found: $PROCESSES"
else
  echo ""
  echo "FAILURE: Missing required processes"
  echo "Required: $REQUIRED_PROCESSES"
  echo "Found: $PROCESSES"
  echo "Missing: $(IFS=','; echo "${MISSING_PROCESSES[*]}")"
  exit 1
fi

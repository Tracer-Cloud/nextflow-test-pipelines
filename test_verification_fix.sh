#!/bin/bash

# Test script to verify the verification logic fix

# Simulate the tracer output format
PROCESSES="STAR align, samtools sort, samtools idxstats, samtools stats, samtools flagstat, samtools view, samtools index, samtools faidx, samtools merge, samtools cat, FastQC"

# Test required processes (from one of the failing workflows)
REQUIRED_PROCESSES="samtools faidx, samtools flagstat, samtools view, FastQC, samtools merge, samtools index, samtools sort, samtools cat, samtools idxstats, samtools stats"

echo "=== Testing verification logic fix ==="
echo "Found processes: $PROCESSES"
echo "Required processes: $REQUIRED_PROCESSES"
echo ""

# Convert comma-separated required processes to array
IFS=',' read -ra REQUIRED_ARRAY <<< "$REQUIRED_PROCESSES"

# Check each required process (exact match, order-independent)
MISSING_PROCESSES=()
for required_process in "${REQUIRED_ARRAY[@]}"; do
  # Trim whitespace
  required_process=$(echo "$required_process" | xargs)
  
  # Normalize the processes string for better matching (remove extra spaces around commas)
  NORMALIZED_PROCESSES=$(echo "$PROCESSES" | sed 's/, */,/g' | sed 's/ *,/,/g')
  
  # Check if this required process exists in the processes string
  if echo "$NORMALIZED_PROCESSES" | grep -q "$required_process"; then
    echo "✅ Found required process: $required_process"
  else
    echo "❌ Missing required process: $required_process"
    MISSING_PROCESSES+=("$required_process")
  fi
done

# Report results
if [ ${#MISSING_PROCESSES[@]} -eq 0 ]; then
  echo ""
  echo "🎉 SUCCESS: All required processes found!"
else
  echo ""
  echo "❌ FAILURE: Missing required processes"
  echo "Missing: $(IFS=','; echo "${MISSING_PROCESSES[*]}")"
  exit 1
fi 
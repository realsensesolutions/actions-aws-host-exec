#!/bin/bash
# Sample script for demonstration

# Print execution details
echo "========== Script Execution =========="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo "Working Directory: $(pwd)"
echo "Parameters: $@"
echo "======================================="

# Check if parameters were passed
if [ $# -gt 0 ]; then
  echo "Script was called with parameters: $@"
else
  echo "Script was called without parameters"
fi

# Demonstrate artifact usage
echo ""
echo "========== Artifact Files =========="
echo "Files in working directory:"
ls -la
echo "======================================="

# Read config.json if it exists
if [ -f "config.json" ]; then
  echo ""
  echo "Configuration loaded from config.json:"
  cat config.json
  echo ""
fi

# Read data.txt if it exists
if [ -f "data.txt" ]; then
  echo ""
  echo "Data file content:"
  cat data.txt
  echo ""
fi

# Sample operations
echo "Creating test output file..."
echo "This is a test file created by the sample script at $(date)" > test-output.txt
echo "Test file created successfully"

# Print system information
echo ""
echo "System Information:"
echo "-------------------"
uname -a
echo "-------------------"
free -h
echo "-------------------"
df -h
echo "-------------------"

echo ""
echo "Script completed successfully!"
exit 0 
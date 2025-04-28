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

# Sample operations
echo "Creating test file..."
echo "This is a test file created by the sample script" > test-file.txt
echo "Test file created successfully"

# Print system information
echo "System Information:"
echo "-------------------"
uname -a
echo "-------------------"
free -h
echo "-------------------"
df -h
echo "-------------------"

echo "Script completed successfully!"
exit 0 
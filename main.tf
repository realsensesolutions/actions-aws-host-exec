# S3 bucket for artifacts
resource "aws_s3_bucket" "artifacts" {
  bucket = "actions-aws-host-exec-${var.name}-${random_id.bucket_suffix.hex}"

  tags = {
    provisioned-by = "actions-aws-host-exec"
  }
}

# Random ID for S3 bucket name suffix
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# SSM document to download artifacts and execute script
resource "aws_ssm_document" "script" {
  name          = "actions-aws-host-exec-${var.name}-${random_id.doc_suffix.hex}"
  document_type = "Command"
  document_format = "YAML"
  
  content = <<-DOC
    schemaVersion: '2.2'
    description: Download artifacts from S3 and execute script on target instances
    parameters:
      WorkingDirectory:
        type: String
        description: Directory to extract artifacts and execute script in
        default: ${var.working_directory}
      BucketName:
        type: String
        description: S3 bucket containing artifacts
        default: ${aws_s3_bucket.artifacts.id}
      ArtifactKey:
        type: String
        description: S3 key for artifacts archive
        default: ${var.name}/artifacts.tar.gz
      ScriptPath:
        type: String
        description: Path to script within artifacts
        default: ${var.script}
    mainSteps:
      - name: "PrepareDirectory"
        action: "aws:runShellScript"
        inputs:
          runCommand:
            - |
              # Create working directory if it doesn't exist
              mkdir -p {{WorkingDirectory}}
              chmod 755 {{WorkingDirectory}}
              echo "Working directory prepared: {{WorkingDirectory}}"
      - name: "DownloadArtifacts"
        action: "aws:runShellScript"
        inputs:
          runCommand:
            - |
              # Download artifacts from S3
              echo "Downloading artifacts from s3://{{BucketName}}/{{ArtifactKey}}"
              aws s3 cp "s3://{{BucketName}}/{{ArtifactKey}}" "/tmp/artifacts.tar.gz"
              echo "Artifacts downloaded successfully"
      - name: "ExtractArtifacts"
        action: "aws:runShellScript"
        inputs:
          runCommand:
            - |
              # Extract artifacts to working directory
              echo "Extracting artifacts to {{WorkingDirectory}}"
              cd {{WorkingDirectory}}
              tar -xzf /tmp/artifacts.tar.gz
              rm -f /tmp/artifacts.tar.gz
              echo "Artifacts extracted successfully"
              echo "Contents of {{WorkingDirectory}}:"
              ls -la
      - name: "ExecuteScript"
        action: "aws:runShellScript"
        timeoutSeconds: ${var.timeout}
        inputs:
          runCommand:
            - |
              # Execute script from artifacts
              cd {{WorkingDirectory}}
              SCRIPT_PATH="{{ScriptPath}}"
              echo "Executing script: $SCRIPT_PATH"
              
              # Make script executable
              chmod +x "$SCRIPT_PATH"
              
              # Execute the script
              bash "$SCRIPT_PATH"
              
              echo "Script execution completed"
  DOC

  tags = {
    provisioned-by = "actions-aws-host-exec"
  }
}

# IAM role for SSM
resource "aws_iam_role" "ssm" {
  name = "actions-aws-host-exec-${var.name}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    provisioned-by = "actions-aws-host-exec"
  }
}

# Random ID for SSM document name suffix
resource "random_id" "doc_suffix" {
  byte_length = 8
}

# SSM document association
resource "aws_ssm_association" "script" {
  name = aws_ssm_document.script.name
  
  dynamic "targets" {
    for_each = [for target in split("\n", var.targets) : {
      key   = split(":", trimspace(target))[0]
      value = split(":", trimspace(target))[1]
    } if length(split(":", trimspace(target))) == 2]
    
    content {
      key    = "tag:${targets.value.key}"
      values = [targets.value.value]
    }
  }
  
  parameters = {
    WorkingDirectory = var.working_directory
    BucketName      = aws_s3_bucket.artifacts.id
    ArtifactKey     = "${var.name}/artifacts.tar.gz"
    ScriptPath      = var.script
  }
}

# Attach AmazonSSMManagedInstanceCore policy to IAM role
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM policy for S3 access from instances
resource "aws_iam_policy" "s3_artifacts" {
  name        = "actions-aws-host-exec-s3-${var.name}"
  description = "Allow EC2 instances to download artifacts from S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      }
    ]
  })

  tags = {
    provisioned-by = "actions-aws-host-exec"
  }
}

# Attach S3 policy to SSM role
resource "aws_iam_role_policy_attachment" "s3_artifacts" {
  role       = aws_iam_role.ssm.name
  policy_arn = aws_iam_policy.s3_artifacts.arn
}

# Outputs
output "document" {
  value = aws_ssm_document.script.arn
}

output "role_name" {
  value = aws_iam_role.ssm.name
}

output "bucket" {
  value = aws_s3_bucket.artifacts.id
} 
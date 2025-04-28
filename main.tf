# SSM document with embedded script content
resource "aws_ssm_document" "script" {
  name          = "actions-aws-host-exec-${var.name}-${random_id.doc_suffix.hex}"
  document_type = "Command"
  document_format = "YAML"
  
  content = <<-DOC
    schemaVersion: '2.2'
    description: Execute script on target instances
    parameters:
      WorkingDirectory:
        type: String
        description: Directory to execute script in
        default: ${var.working_directory}
    mainSteps:
      - name: "PrepareDirectory"
        action: "aws:runShellScript"
        inputs:
          runCommand:
            - |
              # Create working directory if it doesn't exist
              mkdir -p {{WorkingDirectory}}
              chmod 755 {{WorkingDirectory}}
      - name: "ExecuteCommands"
        action: "aws:runShellScript"
        timeoutSeconds: ${var.timeout}
        inputs:
          runCommand:
            - |
              # Execute commands directly
              cd {{WorkingDirectory}}
              ${indent(14, var.script_content)}
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
  }
}

# Attach AmazonSSMManagedInstanceCore policy to IAM role
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Outputs
output "document" {
  value = aws_ssm_document.script.arn
}

output "role_name" {
  value = aws_iam_role.ssm.name
} 
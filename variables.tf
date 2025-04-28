variable "name" {
  description = "Execution name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "targets" {
  description = "Targets for SSM association in format KEY:VALUE (one per line)"
  type        = string
}

variable "working_directory" {
  description = "Directory to execute script in"
  type        = string
}

variable "timeout" {
  description = "Execution timeout in seconds"
  type        = string
  default     = "3600"
}

variable "script_content" {
  description = "Content of the script to execute"
  type        = string
} 
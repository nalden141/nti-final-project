resource "aws_ecr_repository" "ecr" {
  name                 = "project"
  image_scanning_configuration {
    scan_on_push = true
  }
}
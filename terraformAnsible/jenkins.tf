
locals {
  private_key_path = "~/Downloads/Jenkins.pem"
  key_name         = "Jenkins"
  ssh_user         = "ubuntu"
}

resource "aws_subnet" "jenkins-subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  map_public_ip_on_launch= "true"
  availability_zone = "us-east-1c"

  tags = {
    Name = "jenkins-subnet"
  }
}


resource "aws_route_table_association" "jenkins-subnet" {
  subnet_id      = aws_subnet.jenkins-subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "jenkins_sg" {
  name   = "jenkins_security_group"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins-instance" {
  ami           = "ami-04b70fa74e45c3917"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.jenkins-subnet.id
  associate_public_ip_address = true
  security_groups = [aws_security_group.jenkins_sg.id]
  availability_zone = "us-east-1c"
  key_name      = local.key_name  

  tags = {
    Name = "jenkins-instance"
  }
  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]

    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file(local.private_key_path)
      host        = aws_instance.jenkins-instance.public_ip
    }
  }
  provisioner "local-exec" {
    command = "ansible-playbook  -i ${aws_instance.jenkins-instance.public_ip}, --private-key ${local.private_key_path} jenkins.yaml"
  }
}





resource "aws_ebs_volume" "jenkins_volume" {
  availability_zone = "us-east-1c"
  size              = 20
  type              = "gp2"

  tags = {
    Name = "jenkins-volume"
  }
}

resource "aws_volume_attachment" "ebs_attachment" {
  device_name = "/dev/xvdf"
  instance_id = aws_instance.jenkins-instance.id
  volume_id   = aws_ebs_volume.jenkins_volume.id
}

resource "aws_iam_role" "backup_role" {
  name = "aws_backup_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "backup.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup_role_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# AWS Backup Vault
resource "aws_backup_vault" "backup_vault" {
  name        = "example-backup-vault"
  tags = {
    Name = "example-backup-vault"
  }
}

# AWS Backup Plan
resource "aws_backup_plan" "backup_plan" {
  name = "example-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.backup_vault.name
    schedule          = "cron(0 12 * * ? *)"  # Daily at 12:00 UTC
    lifecycle {
      delete_after = 30  # Retain backups for 30 days
    }
  }
}

# AWS Backup Selection
resource "aws_backup_selection" "backup_selection" {
  name          = "example-backup-selection"
  plan_id       = aws_backup_plan.backup_plan.id
  iam_role_arn  = aws_iam_role.backup_role.arn

  resources = [
    aws_instance.jenkins-instance.arn,
    aws_ebs_volume.jenkins_volume.arn
  ]
}
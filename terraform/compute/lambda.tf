resource "aws_iam_role" "lambda-execution-role" {
  provider = aws.management
  name = "process-data-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda-s3-access" {
  provider = aws.management
  name     = "lambda-s3-cross-account-access"
  role     = aws_iam_role.lambda-execution-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.storage-datasync.arn,
          "${aws_s3_bucket.storage-datasync.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.storage-s3.arn,
          "${aws_s3_bucket.storage-s3.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda-secrets-access" {
  provider = aws.management
  name = "lambda-secrets-manager-access"
  role = aws_iam_role.lambda-execution-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [aws_secretsmanager_secret.db_password.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda-basic-execution" {
  provider = aws.management
  role = aws_iam_role.lambda-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda-zip" {
  type = "zip"
  source_dir = "${path.module}/lambda-src"
  output_path = "${path.module}/lambda-package.zip"
}

data "aws_route_table" "vpn-rt" {
  provider = aws.management

  filter {
    name = "tag:Name"
    values = ["vpn-route-table"]
  }
}

data "aws_vpc" "vpn-vpc" {
  provider = aws.management

  filter {
    name = "tag:Name"
    values = ["vpn-vpc"]
  }
}

data "aws_subnet" "subnet-a" {
  provider = aws.management
  vpc_id = data.aws_vpc.vpn-vpc.id

  filter {
    name = "tag:Name"
    values = ["public-vpn-ad-connector-subnet"]
  }
}

data "aws_subnet" "subnet-b" {
  provider = aws.management
  vpc_id = data.aws_vpc.vpn-vpc.id

  filter {
    name = "tag:Name"
    values = ["public-ad-connector-subnet"]
  }
}

resource "aws_security_group" "vpc_endpoint_sg" {
  provider = aws.management
  vpc_id = data.aws_vpc.vpn-vpc.id
  name = "secretsmanager-endpoint-sg"

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  tags = { Name = "secretsmanager-endpoint-sg" }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  provider = aws.management
  vpc_id = data.aws_vpc.vpn-vpc.id
  service_name = "com.amazonaws.eu-central-1.secretsmanager"
  vpc_endpoint_type = "Interface"
  subnet_ids = [data.aws_subnet.subnet-a.id, data.aws_subnet.subnet-b.id]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true

  tags = { Name = "secretsmanager-vpc-endpoint" }
}

resource "aws_iam_role_policy_attachment" "lambda-vpc-access" {
  provider = aws.management
  role = aws_iam_role.lambda-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_security_group" "lambda-vpc" {
  provider = aws.management
  name = "process-data-lambda-sg"
  vpc_id = data.aws_vpc.vpn-vpc.id

  egress {
    from_port = 53
    to_port = 53
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 53
    to_port = 53
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["10.8.0.0/24"]
  }
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_security_group" "vpn-instance-sg" {
  provider = aws.management

  filter {
    name   = "tag:Name"
    values = ["vpn-instance-sg"]
  }
}

resource "aws_lambda_function" "process-data" {
  provider = aws.management
  function_name = "process-data"
  role = aws_iam_role.lambda-execution-role.arn
  handler = "index.handler"
  runtime = "python3.7"
  filename = data.archive_file.lambda-zip.output_path
  source_code_hash = data.archive_file.lambda-zip.output_base64sha256
  timeout = 30

  vpc_config {
    subnet_ids = [data.aws_subnet.subnet-a.id, data.aws_subnet.subnet-b.id]
    security_group_ids = [data.aws_security_group.vpn-instance-sg.id]
  }

  environment {
    variables = {
      DB_SECRET_ARN = aws_secretsmanager_secret.db_password.arn
      DB_HOST = "db.lab.local"
      OUTPUT_BUCKET = "internalapp-storage-s3"
    }
  }

  layers = ["arn:aws:lambda:eu-central-1:898466741470:layer:psycopg2-py37:6"]
}

resource "aws_lambda_permission" "allow-data-sync-bucket" {
  provider = aws.management
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process-data.function_name
  principal = "s3.amazonaws.com"
  source_arn = aws_s3_bucket.storage-datasync.arn
  source_account = "187069338250"
}

resource "aws_vpc_endpoint" "s3" {
  provider = aws.management
  vpc_id = data.aws_vpc.vpn-vpc.id
  service_name = "com.amazonaws.eu-central-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [data.aws_route_table.vpn-rt.id]

  tags = { Name = "s3-vpc-endpoint" }
}
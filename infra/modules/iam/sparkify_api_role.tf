resource "aws_iam_role" "sparkify_api_role" {
  name = "sparkify_api_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })

  tags = {
    Name    = "sparkify_api_role"
    Project = "sparkify_etl"
    Owner   = "ProductEngg"
    Stage   = "API"
  }
}

resource "aws_iam_role_policy_attachment" "sparkify_api_execution_role_attachment" {
  role       = aws_iam_role.sparkify_api_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "sparkify_api_policy" {
  name = "sparkify_api_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "keyspaces:CreateTable",
          "keyspaces:Select",
          "keyspaces:Update",
          "keyspaces:DeleteTable",
          "keyspaces:BatchWriteItem",
          "keyspaces:SelectTable"
        ],
        "Resource" : [
          "arn:aws:cassandra:${var.aws_region}:${var.aws_account_id}:/keyspace/sparkify_keyspace/",
          "arn:aws:cassandra:${var.aws_region}:${var.aws_account_id}:/keyspace/sparkify_keyspace/table/music_app_history"
        ]
      }
    ]
  })

  tags = {
    Name        = "sparkify_api_policy"
    Project     = "sparkify_etl"
    Owner       = "ProductEngg"
    Stage       = "API"
    Environment = "Production"
  }
}

resource "aws_iam_role_policy_attachment" "sparkify_api_policy_attachment" {
  role       = aws_iam_role.sparkify_api_role.name
  policy_arn = aws_iam_policy.sparkify_api_policy.arn
}

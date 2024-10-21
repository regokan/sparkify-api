resource "aws_iam_role" "sparkify_bronze_etl_role" {
  name = "sparkify_bronze_etl_role"

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
    Name    = "sparkify_bronze_etl_role"
    Project = "AdOracle"
    Owner   = "DataEngg"
    Stage   = "ETL"
  }
}

resource "aws_iam_role_policy_attachment" "sparkify_bronze_etl_execution_role_attachment" {
  role       = aws_iam_role.sparkify_bronze_etl_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "sparkify_bronze_etl_policy" {
  name = "sparkify_bronze_etl_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:HeadObject"
        ]
        Resource = [
          "${var.sparkify_etl_bucket_arn}/*"
        ]
      },
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
    Name        = "sparkify_bronze_etl_policy"
    Project     = "sparkify_etl"
    Owner       = "DataEngg"
    Stage       = "ETL"
    Environment = "Production"
  }
}

resource "aws_iam_role_policy_attachment" "sparkify_bronze_etl_policy_attachment" {
  role       = aws_iam_role.sparkify_bronze_etl_role.name
  policy_arn = aws_iam_policy.sparkify_bronze_etl_policy.arn
}

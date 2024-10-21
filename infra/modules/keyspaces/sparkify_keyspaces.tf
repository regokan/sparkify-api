resource "aws_keyspaces_keyspace" "sparkify_keyspace" {
  name = "sparkify_keyspace"

  tags = {
    Name        = "sparkify_keyspace"
    Project     = "sparkify_etl"
    Owner       = "DataEngg"
    Stage       = "ETL"
    Environment = "Production"
  }
}

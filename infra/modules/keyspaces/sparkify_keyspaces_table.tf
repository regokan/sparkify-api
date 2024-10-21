resource "aws_keyspaces_table" "sparkify_keyspace_table" {
  keyspace_name = aws_keyspaces_keyspace.sparkify_keyspace.name
  table_name    = "music_app_history"

  schema_definition {
    # Partition key definition
    partition_key {
      name = "session_id"
    }

    # Clustering key definition
    clustering_key {
      name     = "item_in_session"
      order_by = "ASC"
    }

    column {
      name = "session_id"
      type = "int"
    }

    column {
      name = "item_in_session"
      type = "int"
    }

    column {
      name = "artist"
      type = "text"
    }

    column {
      name = "auth"
      type = "text"
    }

    column {
      name = "first_name"
      type = "text"
    }

    column {
      name = "gender"
      type = "text"
    }

    column {
      name = "last_name"
      type = "text"
    }

    column {
      name = "length"
      type = "double"
    }

    column {
      name = "level"
      type = "text"
    }

    column {
      name = "location"
      type = "text"
    }

    column {
      name = "method"
      type = "text"
    }

    column {
      name = "page"
      type = "text"
    }

    column {
      name = "registration"
      type = "bigint"
    }

    column {
      name = "song"
      type = "text"
    }

    column {
      name = "status"
      type = "int"
    }

    column {
      name = "ts"
      type = "timestamp"
    }

    column {
      name = "user_id"
      type = "int"
    }
  }

  # Capacity specification (default to pay-per-request)
  capacity_specification {
    throughput_mode = "PAY_PER_REQUEST"
  }

  # Enable point-in-time recovery
  point_in_time_recovery {
    status = "ENABLED"
  }

  tags = {
    Name        = "sparkify_keyspace_table"
    Project     = "sparkify_etl"
    Owner       = "DataEngg"
    Stage       = "ETL"
    Environment = "Production"
  }
}

# Sparkify API and ETL

## Overview

This project provides two primary components for managing and exposing data for Sparkify:

1. **API Service**: A GraphQL API that exposes the `music_app_history` table from the Cassandra Keyspace `sparkify_keyspace`. The API is built using FastAPI, Strawberry for the GraphQL schema, and is deployed as an AWS Lambda function, exposed via API Gateway.
2. **Bronze ETL**: A Lambda function that processes CSV files uploaded to an S3 bucket (`s3://sparkify-etl/ingestion`). The function extracts data from the files and inserts it into the Cassandra Keyspace `sparkify_keyspace`. The function is triggered by S3 new object creation events.

### Project Structure

```
.
├── README.md                        # Project overview and root documentation
├── api                              # API service exposing Cassandra data
│   ├── Makefile                     # Build, package, and deploy API-related code
│   ├── README.md                    # Detailed documentation for API service
│   ├── main.py                      # FastAPI app with Strawberry GraphQL integration
│   ├── requirements.txt             # Python dependencies for the API
│   └── strawberry_schema.py         # GraphQL schema definition
├── etl                              # Bronze ETL Lambda function
│   └── bronze
│       ├── Makefile                 # Build, package, and deploy ETL-related code
│       ├── README.md                # Detailed documentation for ETL service
│       ├── main.py                  # ETL Lambda function for processing CSVs from S3
│       ├── requirements.txt         # Python dependencies for ETL
├── event_data                       # Sample event data for testing
│   ├── 2018-11-08-events.csv        # Sample CSV file
│   ├── 2018-11-09-events.csv        # Sample CSV file
│   └── README.md                    # Description of the event data
├── infra                            # Infrastructure as code (Terraform)
│   ├── config.tf                    # General configuration for Terraform
│   ├── data.tf                      # Data sources for Terraform
│   ├── main.tf                      # Main entry point for Terraform infrastructure
│   ├── modules                      # Terraform modules for IAM, Lambda, API Gateway, S3, and Keyspaces
│   │   ├── gateway                  # API Gateway configuration
│   │   │   ├── output.tf
│   │   │   ├── sparkify_api_gateway.tf
│   │   │   └── variables.tf
│   │   ├── iam                      # IAM roles and policies for API and ETL
│   │   │   ├── api_gateway_cloudwatch_role.tf
│   │   │   ├── output.tf
│   │   │   ├── sparkify_api_role.tf
│   │   │   ├── sparkify_bronze_etl_role.tf
│   │   │   └── variables.tf
│   │   ├── keyspaces                # Keyspace and table definitions
│   │   │   ├── output.tf
│   │   │   ├── sparkify_keyspaces.tf
│   │   │   └── sparkify_keyspaces_table.tf
│   │   ├── lambda                   # Lambda function configuration
│   │   │   ├── output.tf
│   │   │   ├── sparkify_api.tf
│   │   │   ├── sparkify_bronze_etl.tf
│   │   │   ├── sparkify_bronze_etl_notification.tf
│   │   │   └── variables.tf
│   │   └── s3                       # S3 bucket configuration
│   │       ├── output.tf
│   │       └── sparkify_etl.tf
│   └── variables.tf                 # Global variables for Terraform
└── output.tf                        # Global outputs for Terraform
```

### Components

- **API Service**: The API is designed to provide access to the `music_app_history` data stored in Cassandra. It uses Strawberry to define the GraphQL schema and is deployed as a Lambda function using Mangum to interface with API Gateway.

  [See more details in the API README](./api/README.md)

- **Bronze ETL**: The ETL process automatically ingests new CSV files uploaded to the S3 bucket (`s3://sparkify-etl/ingestion`). The data is parsed and inserted into the Cassandra `music_app_history` table in the `sparkify_keyspace`.

  [See more details in the ETL README](./etl/bronze/README.md)

### Infrastructure

The infrastructure for the project is defined using Terraform, including resources such as:

- IAM roles and policies for API and ETL
- Lambda functions for both the API and ETL processes
- API Gateway for exposing the API
- S3 bucket for storing CSV files for ingestion
- Cassandra Keyspace and table definitions

### Event Data

Sample event data for testing purposes is provided in the `event_data` directory. These CSV files can be uploaded to the S3 bucket to trigger the ETL process.

Here is the section on the sample run:

---

## Sample Run

You can try out the API by heading over to the [GraphiQL Playground](https://jgp197bjl5.execute-api.us-east-1.amazonaws.com/prod/graphql). Please note that this link is temporary and is provided only for demo purposes.

Below are three sample queries you can run:

### 1. Give me the artist, song title, and song's length in the music app history that was heard during `sessionId = 338`, and `itemInSession = 4`

**Query:**

```graphql
{
  getMusicAppHistory(
    filters: [
      { column: session_id, operator: EQ, value: "338" }
      { column: item_in_session, operator: EQ, value: "4" }
    ]
    columns: [artist, song, length]
  ) {
    artist
    song
    length
  }
}
```

**Result:**

```json
{
  "data": {
    "getMusicAppHistory": [
      {
        "artist": "Faithless",
        "song": "Music Matters (Mark Knight Dub)",
        "length": 495.3073
      }
    ]
  }
}
```

---

### 2. Give me the following: name of artist, song (sorted by itemInSession), and user (first and last name) for `userid = 10`, `sessionid = 182`

**Query:**

```graphql
{
  getMusicAppHistory(
    filters: [
      { column: session_id, operator: EQ, value: "182" }
      { column: user_id, operator: EQ, value: "10" }
    ]
    sortBy: [{ column: item_in_session, order: "ASC" }]
    columns: [artist, song, first_name, last_name]
  ) {
    artist
    song
    firstName
    lastName
  }
}
```

**Result:**

```json
{
  "data": {
    "getMusicAppHistory": [
      {
        "artist": "Down To The Bone",
        "song": "Keep On Keepin' On",
        "firstName": "Sylvie",
        "lastName": "Cruz"
      },
      {
        "artist": "Three Drives",
        "song": "Greece 2000",
        "firstName": "Sylvie",
        "lastName": "Cruz"
      },
      {
        "artist": "Sebastien Tellier",
        "song": "Kilometer",
        "firstName": "Sylvie",
        "lastName": "Cruz"
      },
      {
        "artist": "Lonnie Gordon",
        "song": "Catch You Baby (Steve Pitron & Max Sanna Radio Edit)",
        "firstName": "Sylvie",
        "lastName": "Cruz"
      }
    ]
  }
}
```

---

### 3. Give me every user name (first and last) in my music app history who listened to the song 'All Hands Against His Own'

**Query:**

```graphql
{
  getMusicAppHistory(
    filters: [
      { column: song, operator: EQ, value: "All Hands Against His Own" }
    ]
    columns: [first_name, last_name]
  ) {
    firstName
    lastName
  }
}
```

**Result:**

```json
{
  "data": {
    "getMusicAppHistory": [
      {
        "firstName": "Tegan",
        "lastName": "Levine"
      },
      {
        "firstName": "Jacqueline",
        "lastName": "Lynch"
      },
      {
        "firstName": "Sara",
        "lastName": "Johnson"
      }
    ]
  }
}
```

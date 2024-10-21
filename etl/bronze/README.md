# ETL Bronze Lambda Function

## Overview

This Lambda function is responsible for processing CSV files uploaded to the S3 bucket (`s3://sparkify-etl/ingestion`). Each time a new file is uploaded, the function is triggered via an S3 new object notification. The data from the CSV is parsed and inserted into the `music_app_history` table within the `sparkify_keyspace` in Amazon Keyspaces (Cassandra).

This ETL (Extract, Transform, Load) process enables efficient data ingestion into the Cassandra table from files dropped into S3.

## Key Components

- **S3 Trigger**: The Lambda function is triggered whenever a new CSV file is uploaded to the S3 bucket.
- **Cassandra Integration**: The function connects to Amazon Keyspaces (Cassandra) using credentials stored in AWS Secrets Manager.
- **CSV Processing**: The function reads and processes each row from the CSV file, transforming and inserting data into the Cassandra table.

## Files

- `Makefile`: Automates the packaging, deployment, and cleanup process for the Lambda function and its dependencies.
- `main.py`: The Python script for the Lambda function that handles reading from S3, processing the CSV file, and inserting data into the Cassandra table.
- `requirements.txt`: Lists the Python dependencies needed for this Lambda function, such as the Cassandra driver.

## How It Works

1. **CSV File Upload**: A CSV file is uploaded to the S3 bucket (`s3://sparkify-etl/ingestion`).
2. **S3 Notification**: The S3 event triggers the Lambda function.
3. **CSV Parsing**: The Lambda function reads the CSV file and processes each row.
4. **Data Insertion**: Each row of data is transformed and inserted into the Cassandra `music_app_history` table.

## Deployment

### Steps:

1. **Create Cassandra Credentials**: The `create-cassandra-credentials` Makefile target fetches or creates service-specific credentials for the Lambda function to connect to Cassandra using IAM.
2. **Package the Code**: The `package` target in the Makefile packages the Lambda function code and SSL certificate into a zip file.

3. **Upload to S3**: The `upload` target uploads the Lambda function zip file to the specified S3 bucket.

4. **Package Lambda Layer**: The `layer_package` target installs the Cassandra driver and packages it into a Lambda Layer zip file.

5. **Deploy**: The `deploy` target packages, uploads, and cleans up the Lambda code and its layers, ensuring that everything is ready for execution.

## Example Makefile Commands

- **Package and Deploy**:

  ```bash
  make deploy
  ```

- **Create Cassandra Credentials**:

  ```bash
  make create-cassandra-credentials
  ```

- **Clean up**:
  ```bash
  make clean
  ```

## Sample Event Flow

1. A CSV file like `2018-11-08-events.csv` is uploaded to the S3 bucket.
2. The Lambda function is triggered, reads the file, and extracts each row.
3. Each row's data is inserted into the `music_app_history` table in Cassandra, making the data available for future queries.

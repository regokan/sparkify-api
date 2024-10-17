# Events Data

This directory provides sample data. The actual data is stored on S3 bucket, named `sparkify-etl-ingestion` on AWS. The dataset consists of CSV files partitioned by date.

## Data Format

Each CSV file contains event data with the following columns:

1. Artist
2. Auth
3. FirstName
4. Gender
5. ItemInSession
6. LastName
7. Length
8. Level
9. Location
10. Method
11. Page
12. Registration
13. SessionId
14. Song
15. Status
16. Ts
17. UserId

## Example Filepaths

Here are examples of filepaths to two files in the dataset:

- `<root>/event_data/2018-11-08-events.csv`
- `<root>/event_data/2018-11-09-events.csv`

The same data in production exists at

- `s3://sparkify-etl/ingestion/2018-11-08-events.csv`
- `s3://sparkify-etl/ingestion/2018-11-09-events.csv`

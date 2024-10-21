import boto3
import csv
import json
from io import StringIO
import logging
from cassandra import ConsistencyLevel
from cassandra.cluster import Cluster, ExecutionProfile, EXEC_PROFILE_DEFAULT
from cassandra.auth import PlainTextAuthProvider
from ssl import SSLContext, PROTOCOL_TLSv1_2, CERT_REQUIRED

# Initialize the S3 client
s3 = boto3.client("s3")
boto_session = boto3.Session()

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


# Retrieve the Cassandra credentials from Secrets Manager
def get_cassandra_credentials():
    secret_client = boto3.client("secretsmanager")
    secret_response = secret_client.get_secret_value(
        SecretId="sparkify_cassandra_credential"
    )
    secret = json.loads(secret_response["SecretString"])
    cassandra_user = secret["ServiceSpecificCredential"]["ServiceUserName"]
    cassandra_password = secret["ServiceSpecificCredential"]["ServicePassword"]
    return cassandra_user, cassandra_password


# Initialize the Cassandra driver to connect to Amazon Keyspaces using credentials from Secrets Manager
def get_cassandra_session():
    # Fetch Cassandra credentials from Secrets Manager
    cassandra_user, cassandra_password = get_cassandra_credentials()

    # Set up SSL context for secure connection
    ssl_context = SSLContext(PROTOCOL_TLSv1_2)
    ssl_context.load_verify_locations("./sf-class2-root.crt")
    ssl_context.verify_mode = CERT_REQUIRED

    # Use PlainTextAuthProvider with credentials from Secrets Manager
    auth_provider = PlainTextAuthProvider(
        username=cassandra_user, password=cassandra_password
    )

    # Create an execution profile with consistency level set to LOCAL_QUORUM
    profile = ExecutionProfile(consistency_level=ConsistencyLevel.LOCAL_QUORUM)

    # Connect to Amazon Keyspaces
    cluster = Cluster(
        ["cassandra.us-east-1.amazonaws.com"],
        auth_provider=auth_provider,
        port=9142,
        ssl_context=ssl_context,
        execution_profiles={EXEC_PROFILE_DEFAULT: profile},
    )
    session = cluster.connect("sparkify_keyspace")
    return session


def process_and_insert_csv_data(session, csv_data):
    # Process and transform the CSV rows
    for row in csv_data:
        try:
            # Conversion handling for numeric and timestamp fields
            session_id = int(row["sessionId"]) if row["sessionId"] else "null"
            item_in_session = (
                int(row["itemInSession"]) if row["itemInSession"] else "null"
            )
            artist = (
                row["artist"].replace("'", "''").strip()
                if row["artist"].strip()
                else "null"
            )
            auth = row["auth"].replace("'", "''")  # Escape any single quotes
            first_name = row["firstName"].replace("'", "''")  # Escape any single quotes
            gender = row["gender"].replace("'", "''")  # Escape any single quotes
            last_name = row["lastName"].replace("'", "''")  # Escape any single quotes

            # Handle length: check if it's empty, convert to float or set to null
            length = float(row["length"]) if row["length"] else "null"

            level = row["level"].replace("'", "''")
            location = row["location"].replace("'", "''")
            method = row["method"].replace("'", "''")
            page = row["page"].replace("'", "''")

            # Convert 'registration' and 'ts' fields (scientific notation) to integers, set to null if empty
            registration = (
                int(float(row["registration"])) if row["registration"] else "null"
            )
            ts = int(float(row["ts"])) if row["ts"] else "null"

            song = (
                row["song"].replace("'", "''").strip()
                if row["song"].strip()
                else "null"
            )
            status = int(row["status"]) if row["status"] else "null"
            user_id = int(row["userId"]) if row["userId"] else "null"

            # Prepare the query with formatted values
            query = f"""
                INSERT INTO sparkify_keyspace.music_app_history (
                    session_id, item_in_session, artist, auth, first_name, gender, last_name, length, level,
                    location, method, page, registration, song, status, ts, user_id
                ) VALUES (
                    {session_id}, {item_in_session}, {f"'{artist}'" if artist != 'null' else 'null'}, 
                    '{auth}', '{first_name}', '{gender}', '{last_name}', 
                    {length}, '{level}', '{location}', '{method}', '{page}', {registration}, 
                    {f"'{song}'" if song != 'null' else 'null'}, {status}, {ts}, {user_id}
                )
            """

            # Execute the CQL statement
            session.execute(query)

        except Exception as e:
            logger.error(
                f"Error processing row {row} and inserting into Keyspaces: {e}"
            )
            continue  # Skip the current row and continue processing


def lambda_handler(event, _):
    try:
        # Extract the S3 bucket and file key from the event
        bucket_name = event["Records"][0]["s3"]["bucket"]["name"]
        file_key = event["Records"][0]["s3"]["object"]["key"]
        logger.info(f"Processing file {file_key} from bucket {bucket_name}")

        # Fetch the CSV file from S3
        response = s3.get_object(Bucket=bucket_name, Key=file_key)
        csv_content = response["Body"].read().decode("utf-8")

        # Parse the CSV content
        csv_data = csv.DictReader(StringIO(csv_content))

    except Exception as e:
        logger.error(f"Error fetching or reading the file from S3: {e}")
        return {
            "statusCode": 500,
            "body": f"Error fetching or reading the file from S3: {e}",
        }

    # Connect to the Cassandra session
    session = get_cassandra_session()

    # Process and insert the CSV data
    process_and_insert_csv_data(session, csv_data)

    # Close the Cassandra session
    session.shutdown()

    return {"statusCode": 200, "body": f"Successfully processed {file_key}."}

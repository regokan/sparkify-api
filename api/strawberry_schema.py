import strawberry
from enum import Enum
from typing import List, Optional
import logging

from cassandra import ConsistencyLevel
from cassandra.cluster import Cluster, ExecutionProfile, EXEC_PROFILE_DEFAULT
from cassandra.auth import PlainTextAuthProvider
from ssl import SSLContext, PROTOCOL_TLSv1_2, CERT_REQUIRED
import boto3
import json

# Initialize logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


# Retrieve Cassandra credentials from AWS Secrets Manager
def get_cassandra_credentials():
    secret_client = boto3.client("secretsmanager")
    secret_response = secret_client.get_secret_value(
        SecretId="sparkify_cassandra_credential"
    )
    secret = json.loads(secret_response["SecretString"])
    cassandra_user = secret["ServiceSpecificCredential"]["ServiceUserName"]
    cassandra_password = secret["ServiceSpecificCredential"]["ServicePassword"]
    return cassandra_user, cassandra_password


# Initialize the Cassandra session
def get_cassandra_session():
    cassandra_user, cassandra_password = get_cassandra_credentials()

    ssl_context = SSLContext(PROTOCOL_TLSv1_2)
    ssl_context.load_verify_locations("./sf-class2-root.crt")
    ssl_context.verify_mode = CERT_REQUIRED

    auth_provider = PlainTextAuthProvider(
        username=cassandra_user, password=cassandra_password
    )

    profile = ExecutionProfile(consistency_level=ConsistencyLevel.LOCAL_QUORUM)

    cluster = Cluster(
        ["cassandra.us-east-1.amazonaws.com"],
        auth_provider=auth_provider,
        port=9142,
        ssl_context=ssl_context,
        execution_profiles={EXEC_PROFILE_DEFAULT: profile},
    )
    session = cluster.connect("sparkify_keyspace")
    return session


# Map column names to their respective data types
COLUMN_TYPE_MAPPING = {
    "session_id": int,
    "item_in_session": int,
    "artist": str,
    "auth": str,
    "first_name": str,
    "gender": str,
    "last_name": str,
    "length": float,
    "level": str,
    "location": str,
    "method": str,
    "page": str,
    "registration": int,
    "song": str,
    "status": int,
    "ts": str,  # Handle as a string initially (timestamp will need special parsing if needed)
    "user_id": int,
}


# Define Enums for columns and filter operators
@strawberry.enum
class ColumnName(Enum):
    session_id = "session_id"
    item_in_session = "item_in_session"
    artist = "artist"
    auth = "auth"
    first_name = "first_name"
    gender = "gender"
    last_name = "last_name"
    length = "length"
    level = "level"
    location = "location"
    method = "method"
    page = "page"
    registration = "registration"
    song = "song"
    status = "status"
    ts = "ts"
    user_id = "user_id"


@strawberry.enum
class FilterOperator(Enum):
    EQ = "="
    NEQ = "!="
    GT = ">"
    GTE = ">="
    LT = "<"
    LTE = "<="


# Define input types for filters and sorting
@strawberry.input
class FilterInput:
    column: ColumnName
    operator: FilterOperator
    value: str


@strawberry.input
class SortInput:
    column: ColumnName
    order: Optional[str] = "ASC"  # Defaults to ascending order


# Define the GraphQL type for the music app history
@strawberry.type
class MusicAppHistory:
    session_id: Optional[int] = None
    item_in_session: Optional[int] = None
    artist: Optional[str] = None
    auth: Optional[str] = None
    first_name: Optional[str] = None
    gender: Optional[str] = None
    last_name: Optional[str] = None
    length: Optional[float] = None
    level: Optional[str] = None
    location: Optional[str] = None
    method: Optional[str] = None
    page: Optional[str] = None
    registration: Optional[int] = None
    song: Optional[str] = None
    status: Optional[int] = None
    ts: Optional[str] = None
    user_id: Optional[int] = None


# Define the Query type with the get_music_app_history field
@strawberry.type
class Query:
    @strawberry.field
    def get_music_app_history(
        self,
        filters: Optional[List[FilterInput]] = None,
        sort_by: Optional[List[SortInput]] = None,
        limit: Optional[int] = 10,
        columns: Optional[List[ColumnName]] = None,
    ) -> List[MusicAppHistory]:
        session = get_cassandra_session()

        if not columns:
            columns = [column for column in ColumnName]

        columns_str = ", ".join([column.value for column in columns])

        query = f"SELECT {columns_str} FROM music_app_history"

        # Build WHERE clause
        where_conditions = []
        values = {}
        allow_filtering = False
        if filters:
            for idx, filter in enumerate(filters):
                placeholder = f"value{idx}"
                column_name = filter.column.value

                # Dynamically convert filter value based on column type
                if column_name in COLUMN_TYPE_MAPPING:
                    filter_value = COLUMN_TYPE_MAPPING[column_name](filter.value)
                else:
                    filter_value = filter.value  # Keep as string for non-mapped columns

                # Allow filtering if sorting or filtering by non-primary key column
                if column_name not in ["session_id", "item_in_session", "user_id"]:
                    allow_filtering = True

                condition = f"{column_name} {filter.operator.value} :{placeholder}"
                where_conditions.append(condition)
                values[placeholder] = filter_value

        if where_conditions:
            query += " WHERE " + " AND ".join(where_conditions)

        # Add ORDER BY clause if needed
        if sort_by:
            order_conditions = [
                f"{sort.column.value} {sort.order.upper()}" for sort in sort_by
            ]
            query += " ORDER BY " + ", ".join(order_conditions)
            allow_filtering = True  # Allow filtering when sorting by non-primary key

        # Add LIMIT clause
        query += f" LIMIT {limit}"

        # ALLOW FILTERING must be the last part of the query
        if allow_filtering:
            query += " ALLOW FILTERING"

        # Prepare and execute the query
        prepared_query = session.prepare(query)
        result = session.execute(prepared_query, values)

        # Map Cassandra rows to GraphQL type
        data = []
        for row in result:
            history_data = {}
            for column in columns:
                history_data[column.value] = getattr(row, column.value, None)
            data.append(MusicAppHistory(**history_data))

        return data


# Create the Strawberry schema
schema = strawberry.Schema(Query)

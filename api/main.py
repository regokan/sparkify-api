from fastapi import FastAPI
from mangum import Mangum
from strawberry.asgi import GraphQL
import logging

from strawberry_schema import schema

# Initialize logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize the FastAPI app
app = FastAPI()

# Add the GraphQL endpoint to FastAPI
graphql_app = GraphQL(schema)
app.add_route("/graphql", graphql_app)

# For AWS Lambda deployment using Mangum
lambda_handler = Mangum(app)

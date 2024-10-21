# Variables
S3_BUCKET=s3://sparkify-etl/lambda/bronze
ZIP_FILE=code.zip
SRC_FILE=main.py
CERT_FILE=sf-class2-root.crt
ZIP_PATH=./$(ZIP_FILE)
IAM_USER=mac
SECRET_NAME=sparkify_cassandra_credential
REGION=us-east-1

# Variables for the Lambda layer
LAYER_ZIP=cassandra_layer.zip
LAYER_DIR=python

# Default target
all: deploy

# Step 0: Create credentials for the Lambda function
create-cassandra-credentials:
	@set -e; \
	echo "Fetching ServiceSpecificCredentialId for IAM user: $(IAM_USER)"; \
	credential_id=$$(aws iam list-service-specific-credentials --user-name $(IAM_USER) --query "ServiceSpecificCredentials[0].ServiceSpecificCredentialId" --output text); \
	if [ "$$credential_id" == "None" ]; then \
		echo "No service-specific credentials found for $(IAM_USER). Exiting."; \
		exit 1; \
	fi; \
	echo "Found ServiceSpecificCredentialId: $$credential_id"; \
	echo "Resetting the service-specific credentials..."; \
	reset_output=$$(aws iam reset-service-specific-credential --service-specific-credential-id $$credential_id); \
	service_username=$$(echo $$reset_output | jq -r '.ServiceSpecificCredential.ServiceUserName'); \
	service_password=$$(echo $$reset_output | jq -r '.ServiceSpecificCredential.ServicePassword'); \
	echo "ServiceUserName: $$service_username"; \
	echo "ServicePassword: $$service_password"; \
	secret_exists=$$(aws secretsmanager describe-secret --secret-id $(SECRET_NAME) --query 'ARN' --output text 2>/dev/null || echo "None"); \
	if [ "$$secret_exists" == "None" ]; then \
		echo "Secret $(SECRET_NAME) does not exist. Creating new secret..."; \
		aws secretsmanager create-secret --name $(SECRET_NAME) --description "Cassandra credentials for IAM user $(IAM_USER)" \
			--secret-string "$$(jq -n --arg u $$service_username --arg p $$service_password '{"ServiceSpecificCredential":{"ServiceUserName":$$u,"ServicePassword":$$p}}')"; \
	else \
		echo "Secret $(SECRET_NAME) already exists. Updating the secret..."; \
		aws secretsmanager put-secret-value --secret-id $(SECRET_NAME) --secret-string "$$(jq -n --arg u $$service_username --arg p $$service_password '{"ServiceSpecificCredential":{"ServiceUserName":$$u,"ServicePassword":$$p}}')"; \
	fi

# Step 1: Create a zip file containing the Lambda code
package:
	@echo "Downloading SSL certificate..."
	curl https://certs.secureserver.net/repository/sf-class2-root.crt -o $(CERT_FILE)
	@echo "Packaging $(SRC_FILE) and $(CERT_FILE) into $(ZIP_FILE)..."
	zip -j $(ZIP_FILE) $(SRC_FILE) $(CERT_FILE)

# Step 2: Upload the zip file to the specified S3 bucket
upload:
	@echo "Uploading $(ZIP_FILE) to $(S3_BUCKET)..."
	aws s3 cp $(ZIP_PATH) $(S3_BUCKET)/$(ZIP_FILE)

# Step 3: Package the Cassandra driver into a Lambda Layer
layer_package:
	@echo "Creating directory for Lambda layer..."
	mkdir -p $(LAYER_DIR)
	@echo "Installing Cassandra driver with Amazon Keyspaces support into layer..."
	pip install -r requirements.txt -t $(LAYER_DIR)
	@echo "Packaging layer into $(LAYER_ZIP)..."
	zip -r $(LAYER_ZIP) $(LAYER_DIR)

# Step 4: Upload the Lambda layer zip to the specified S3 bucket
layer_upload:
	@echo "Uploading $(LAYER_ZIP) to $(S3_BUCKET)..."
	aws s3 cp $(LAYER_ZIP) $(S3_BUCKET)/$(LAYER_ZIP)

# Clean up local zip files
clean:
	@echo "Cleaning up..."
	rm -f $(ZIP_FILE) $(LAYER_ZIP)
	rm -rf $(LAYER_DIR)

# Target to package, upload, and clean up the Lambda Layer
deploy: package upload layer_package layer_upload clean

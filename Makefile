.PHONY: help build deploy clean test lint

# Variables
DOCKER_COMPOSE = docker compose
SERVICE_NAME = lambda-builder
IMAGE_NAME = close-ec2-lambda
COMMIT_ID = $(shell git rev-parse --short=8 HEAD)
PACKAGE_NAME = $(COMMIT_ID).zip

# Default target
help: ## Show this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development
build: ## Build the Docker image
	$(DOCKER_COMPOSE) build $(SERVICE_NAME)

deploy: ## Build and deploy Lambda function to S3
	$(DOCKER_COMPOSE) up $(SERVICE_NAME)

##@ Testing & Quality
test: ## Run tests (placeholder)
	@echo "No tests configured yet"

lint: ## Lint Python code
	@if command -v flake8 >/dev/null 2>&1; then \
		flake8 lambda_function.py; \
	else \
		echo "flake8 not installed, skipping lint"; \
	fi

##@ Maintenance
clean: ## Clean up build artifacts and Docker resources
	@echo "Cleaning up..."
	@rm -f *.zip
	@$(DOCKER_COMPOSE) down --rmi all --volumes --remove-orphans 2>/dev/null || true
	@docker system prune -f

info: ## Show project information
	@echo "Project: Close EC2 Lambda"
	@echo "Git Commit: $(COMMIT_ID)"
	@echo "Package Name: $(PACKAGE_NAME)"
	@echo "Docker Compose Service: $(SERVICE_NAME)"

##@ Environment
setup: ## Setup environment file
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env file from .env.example"; \
		echo "Please edit .env with your AWS configuration"; \
	else \
		echo ".env file already exists"; \
	fi

check-env: ## Check if required environment variables are set
	@echo "Checking environment..."
	@if [ -f .env ]; then \
		echo "✓ .env file exists"; \
	else \
		echo "✗ .env file missing - run 'make setup'"; \
	fi
	@if [ -d ~/.aws ]; then \
		echo "✓ AWS credentials directory exists"; \
	else \
		echo "✗ AWS credentials not found in ~/.aws"; \
	fi

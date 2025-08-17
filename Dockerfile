FROM python:3.9-slim

# Install required system packages
RUN apt-get update && apt-get install -y \
    git \
    zip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY lambda_function.py .
COPY deploy.sh .

# Make deploy script executable
RUN chmod +x deploy.sh

# Default command
CMD ["./deploy.sh"]

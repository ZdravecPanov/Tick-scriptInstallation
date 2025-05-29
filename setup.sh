#!/bin/bash
set -e

echo "Running setup.sh from directory: $(pwd)"
echo "Files here:"
ls -la

echo "Starting TICK stack setup..."

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl enable docker
    sudo systemctl start docker
fi

# Install Docker Compose if not installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose not found. Installing Docker Compose..."
    sudo apt-get install -y docker-compose
fi

# Start the stack
echo "Bringing up containers with docker-compose..."
docker-compose -f "$(dirname "$0")/docker-compose.yml" up -d


# TICK Stack Docker Setup - Commented Guide

## Overview
The TICK stack is a collection of open-source tools for monitoring and alerting:
- **T**elegraf: Data collection agent (metrics from system, applications, etc.)
- **I**nfluxDB: Time-series database for storing metrics
- **C**hronograf: Web UI for visualization (replaced by Grafana in this setup)
- **K**apacitor: Real-time streaming data processing engine for alerts

## Project Structure
```
tick-stack-docker/
├── docker-compose.yml    # Main orchestration file - defines all services
├── setup.sh             # Installation script for Docker and startup
└── telegraf/
    └── telegraf.conf     # Telegraf configuration for data collection
```

---

## 📄 1. docker-compose.yml
*This file orchestrates all the containers and their relationships*

```yaml
services:
  # InfluxDB - Time-series database (stores all your metrics)
  influxdb:
    image: influxdb:1.8              # Using v1.8 (older but stable version)
    container_name: influxdb         # Fixed container name for easy reference
    ports:
      - "8086:8086"                  # Expose port 8086 for HTTP API access
    volumes:
      - influxdb_data:/var/lib/influxdb  # Persist database data between restarts

  # Telegraf - Data collection agent (gathers system metrics)
  telegraf:
    image: telegraf:latest           # Latest Telegraf image
    container_name: telegraf         
    depends_on:
      - influxdb                     # Wait for InfluxDB to start first
    volumes:
      # Mount local config file into container (read-only)
      - ./telegraf/telegraf.conf:/etc/telegraf/telegraf.conf:ro

  # Kapacitor - Stream processing and alerting engine
  kapacitor:
    image: kapacitor:latest
    container_name: kapacitor
    depends_on:
      - influxdb                     # Needs InfluxDB to read data from
    ports:
      - "9092:9092"                  # Expose Kapacitor API port
    environment:
      # Tell Kapacitor where to find InfluxDB (using container name)
      - KAPACITOR_INFLUXDB_0_URLS_0=http://influxdb:8086
      - KAPACITOR_INFLUXDB_0_ENABLED=true

  # Grafana - Web-based visualization dashboard
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    depends_on:
      - influxdb                     # Needs InfluxDB as data source
    ports:
      - "3000:3000"                  # Access Grafana web UI at localhost:3000
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin  # Default admin password (CHANGE THIS!)
    volumes:
      - grafana_data:/var/lib/grafana     # Persist dashboards and settings

# Named volumes for data persistence
volumes:
  influxdb_data:    # Database files survive container restarts
  grafana_data:     # Dashboard configs survive container restarts
```

---

## 📄 2. setup.sh
*Automated installation script that handles Docker setup and container startup*

```bash
#!/bin/bash
set -e                              # Exit on any error

echo "Running setup.sh from directory: $(pwd)"
echo "Files here:"
ls -la                              # Show current directory contents for debugging

echo "Starting TICK stack setup..."

# Check if Docker is installed, install if missing
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    sudo apt-get update             # Update package lists
    sudo apt-get install -y docker.io  # Install Docker from Ubuntu repos
    sudo systemctl enable docker   # Start Docker on boot
    sudo systemctl start docker    # Start Docker service now
fi

# Check if Docker Compose is installed, install if missing
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose not found. Installing Docker Compose..."
    sudo apt-get install -y docker-compose  # Install from Ubuntu repos
fi

# Start all containers defined in docker-compose.yml
echo "Bringing up containers with docker-compose..."
# Use absolute path to docker-compose.yml file
docker-compose -f "$(dirname "$0")/docker-compose.yml" up -d
# -d flag runs containers in background (detached mode)
```

---

## 📄 3. telegraf/telegraf.conf
*Configuration for Telegraf to collect system metrics from Ubuntu host*

```toml
# Agent configuration - how often to collect and send data
[agent]
  interval = "10s"                  # Collect metrics every 10 seconds
  round_interval = true             # Round collection times to interval
  metric_batch_size = 1000          # Send 1000 metrics per batch
  metric_buffer_limit = 10000       # Buffer up to 10000 metrics if output is slow
  collection_jitter = "0s"          # No random delay in collection
  flush_interval = "10s"            # Send data every 10 seconds
  flush_jitter = "0s"              # No random delay in sending
  precision = ""                    # Use default precision
  hostname = ""                     # Use system hostname
  omit_hostname = false             # Include hostname in metrics

# Output plugin - where to send collected data
[[outputs.influxdb]]
  urls = ["http://influxdb:8086"]   # InfluxDB container (using container name)
  database = "telegraf"             # Store data in "telegraf" database

# Input plugins - what data to collect
[[inputs.cpu]]                     # CPU usage metrics
  percpu = true                     # Collect per-core CPU stats
  totalcpu = true                   # Also collect total CPU stats
  collect_cpu_time = false          # Don't collect CPU time counters
  report_active = false             # Don't report active CPU time

[[inputs.mem]]                     # Memory usage metrics (RAM)

[[inputs.disk]]                    # Disk usage and I/O metrics

[[inputs.system]]                  # System-level metrics (load, uptime, etc.)
```

---

## 📦 Installation Steps (Commented)

### 1. Create the Project Structure
```bash
# Create the main directory
mkdir tick-stack-docker
cd tick-stack-docker

# Create the telegraf subdirectory
mkdir telegraf

# Create all the files (docker-compose.yml, setup.sh, telegraf/telegraf.conf)
# Copy the content from above into each file
```

### 2. Package for Transfer (Optional)
```bash
# Create a zip file for easy transfer to another machine
zip -r tick-stack-docker.zip tick-stack-docker/
```

### 3. Deploy on Target Ubuntu Machine
```bash
# Install unzip if needed
sudo apt install unzip -y

# Extract the project
unzip tick-stack-docker.zip
cd tick-stack-docker

# Make setup script executable
chmod +x setup.sh

# Run the setup (installs Docker if needed and starts containers)
./setup.sh
```

---

## 🔧 Useful Docker Commands (From Your History)

```bash
# Check if containers are running
docker ps                          # Show running containers
docker ps -a                       # Show all containers (including stopped)

# Access container shells for debugging
docker exec -it influxdb bash      # Access InfluxDB container
docker exec -it grafana bash       # Access Grafana container
docker exec -it telegraf bash      # Access Telegraf container

# Check Docker installation
docker --version                   # Show Docker version
docker-compose --version           # Show Docker Compose version

# View container logs
docker logs influxdb               # See InfluxDB logs
docker logs telegraf               # See Telegraf logs (useful for debugging)
docker logs grafana                # See Grafana logs
```

---

## 🌐 Access Points

After successful setup, you can access:

- **Grafana Dashboard**: http://localhost:3000
  - Username: `admin`
  - Password: `admin` (change this!)
  
- **InfluxDB API**: http://localhost:8086
  - Used by Telegraf to store data
  - Can be queried directly via HTTP API
  
- **Kapacitor API**: http://localhost:9092
  - For setting up alerts and stream processing

---

## 🚨 Your Installation Troubleshooting Notes
1. **Docker Compose Version Conflicts**: You had to remove old versions and install the official Docker Compose
2. **Permission Issues**: Needed `sudo` to run setup script
3. **Repository Setup**: Had to add official Docker repositories for latest versions

### Key Commands That Fixed Issues:
```bash
# Remove conflicting docker-compose versions
sudo apt remove docker-compose

# Install official Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Add user to docker group (to avoid sudo for docker commands)
sudo usermod -aG docker $USER
```

---

## 📝 Next Steps

1. **Access Grafana** at http://localhost:3000 and set up dashboards
2. **Configure data sources** in Grafana to point to InfluxDB
3. **Customize Telegraf config** to collect additional metrics you need
4. **Set up Kapacitor alerts** for monitoring thresholds
5. **Change default passwords** for security

## 🔍 Monitoring Data Flow

1. **Telegraf** collects system metrics (CPU, memory, disk)
2. **Telegraf** sends data to **InfluxDB** every 10 seconds
3. **Grafana** queries **InfluxDB** to display dashboards
4. **Kapacitor** can read from **InfluxDB** to trigger alerts

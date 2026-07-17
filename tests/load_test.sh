#!/bin/bash
set -e
set -x

echo "=== Load and Stress Test ==="

# Configure apt to use the proxy
echo 'Acquire::HTTP::Proxy "http://apt-cacher-ng:3142";' > /etc/apt/apt.conf.d/01proxy
echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

# Stress test with multiple package installations
packages=(
  "build-essential"
  "git"
  "python3"
  "nodejs"
  "nginx"
  "postgresql-client"
  "redis-tools"
  "jq"
  "tree"
  "vim"
)

for package in "${packages[@]}"; do
  echo "Installing $package..."
  apt-get install -y "$package"
  echo "Successfully installed $package"
done

echo "Load test completed successfully"

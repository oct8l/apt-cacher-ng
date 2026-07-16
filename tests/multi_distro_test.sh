#!/bin/bash
set -e
set -x

echo "=== Multi-Distribution Test ==="

# Configure apt to use the proxy
echo 'Acquire::HTTP::Proxy "http://apt-cacher-ng:3142";' > /etc/apt/apt.conf.d/01proxy
echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

echo "Testing on: $(cat /etc/os-release | grep PRETTY_NAME)"

# Update package lists
apt-get update

# Install common packages
apt-get install -y curl wget htop nano

# Verify installations
curl --version
wget --version
htop --version
nano --version

echo "Multi-distribution test passed for $(cat /etc/os-release | grep PRETTY_NAME)"

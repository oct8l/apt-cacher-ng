#!/bin/bash
set -e

echo "=== Performance and Caching Tests ==="

# Configure apt to use the proxy
echo 'Acquire::HTTP::Proxy "http://apt-cacher-ng:3142";' > /etc/apt/apt.conf.d/01proxy
echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

echo "=== Test cache performance ==="
# First install (cache miss)
echo "First install (cache miss):"
time (apt-get update && apt-get install -y htop)

# Remove and reinstall (cache hit)
apt-get remove -y htop
apt-get clean
echo "Second install (cache hit - should be faster):"
time (apt-get update && apt-get install -y htop)

echo "Performance test completed"

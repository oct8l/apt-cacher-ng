#!/bin/bash
set -e
set -x

echo "=== Reliability Test ==="

# Configure apt to use the proxy
echo 'Acquire::HTTP::Proxy "http://apt-cacher-ng:3142";' > /etc/apt/apt.conf.d/01proxy
echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

# Test cache persistence and performance over time
for i in {1..5}; do
  echo "Reliability test iteration $i/5"

  # Install packages
  apt-get install -y "package-$i" 2>/dev/null || apt-get install -y curl

  # Check proxy health
  if ! curl -f -s "http://apt-cacher-ng:3142/acng-report.html" > /dev/null; then
    echo "ERROR: Proxy health check failed in iteration $i"
    exit 1
  fi

  # Wait between iterations
  sleep 10
done

echo "Reliability test passed"

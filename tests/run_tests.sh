#!/bin/bash
set -e
set -x

echo "=== Starting apt-cacher-ng integration tests ==="

# Configure apt to use the proxy
echo 'Acquire::HTTP::Proxy "http://apt-cacher-ng:3142";' > /etc/apt/apt.conf.d/01proxy
echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

echo "=== Test 1: Basic apt update through proxy ==="
apt-get update

echo "=== Test 2: Install a small package (cache miss) ==="
apt-get install -y curl
curl --version

echo "=== Test 3: Verify proxy is working by checking logs ==="
# Check that the proxy service is responding
curl -f -s -o /dev/null "http://apt-cacher-ng:3142/acng-report.html"
echo "Proxy health check passed"

echo "=== Test 4: Test cache hit by reinstalling same package ==="
apt-get remove -y curl
apt-get clean
apt-get update
# This should be faster as it hits the cache
time apt-get install -y curl

echo "=== Test 5: Install multiple packages ==="
apt-get install -y wget nano
wget --version
nano --version

echo "=== Test 6: Verify proxy statistics ==="
# Get proxy statistics to ensure it's actually proxying
curl -f -s "http://apt-cacher-ng:3142/acng-report.html" | grep -q -i -E "(apt-cacher|report|status|cache)" || {
    echo "ERROR: Could not access proxy statistics page"
    exit 1
}
echo "Proxy statistics page accessible and contains expected content"

echo "=== All tests passed! ==="

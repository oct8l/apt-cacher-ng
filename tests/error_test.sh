#!/bin/bash
set -e

echo "=== Error Handling Tests ==="

# Configure apt to use the proxy
echo 'Acquire::HTTP::Proxy "http://apt-cacher-ng:3142";' > /etc/apt/apt.conf.d/01proxy
echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

echo "=== Test handling of non-existent package ==="
if apt-get install -y nonexistent-package-12345 2>/dev/null; then
    echo "ERROR: Should have failed to install non-existent package"
    exit 1
else
    echo "Correctly handled non-existent package"
fi

echo "Error handling test completed"

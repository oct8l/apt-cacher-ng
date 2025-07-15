#!/bin/bash

# Local test script for apt-cacher-ng
# Run this script to verify your changes work correctly before submitting a PR

set -e

echo "🔧 Building apt-cacher-ng Docker image..."
docker build -t local-apt-cacher-ng:test .

echo "🚀 Starting apt-cacher-ng service..."
docker run -d --name apt-cacher-local-test -p 3142:3142 local-apt-cacher-ng:test

echo "⏳ Waiting for service to be ready..."
timeout 60s bash -c 'while ! curl -f -s http://localhost:3142/acng-report.html > /dev/null; do echo "Waiting..."; sleep 3; done'

echo "✅ Service is ready! Running tests..."

echo ""
echo "🧪 Test 1: Basic functionality test"
docker run --rm --add-host=apt-cacher:host-gateway debian:bookworm-slim bash -c "
  echo 'Acquire::HTTP::Proxy \"http://apt-cacher:3142\";' > /etc/apt/apt.conf.d/01proxy
  echo 'Acquire::HTTPS::Proxy \"false\";' >> /etc/apt/apt.conf.d/01proxy

  echo 'Running apt update through proxy...'
  apt-get update

  echo 'Installing curl...'
  apt-get install -y curl

  echo 'Verifying curl installation...'
  curl --version

  echo 'Test 1 passed!'
"

echo ""
echo "🧪 Test 2: Cache performance test"
docker run --rm --add-host=apt-cacher:host-gateway debian:bookworm-slim bash -c "
  echo 'Acquire::HTTP::Proxy \"http://apt-cacher:3142\";' > /etc/apt/apt.conf.d/01proxy
  echo 'Acquire::HTTPS::Proxy \"false\";' >> /etc/apt/apt.conf.d/01proxy

  echo 'First install (cache miss):'
  time (apt-get update && apt-get install -y cowsay)

  echo 'Removing package...'
  apt-get remove -y cowsay
  apt-get clean

  echo 'Second install (cache hit - should be faster):'
  time (apt-get update && apt-get install -y cowsay)

  echo 'Test 2 passed!'
"

echo ""
echo "🧪 Test 3: Health check verification"
if curl -f -s http://localhost:3142/acng-report.html | grep -q "Apt-Cacher NG"; then
  echo "✅ Health check passed - apt-cacher-ng is responding correctly"
else
  echo "❌ Health check failed - apt-cacher-ng is not responding correctly"
  exit 1
fi

echo ""
echo "🧪 Test 4: Statistics check"
echo "📊 Current cache statistics:"
curl -s http://localhost:3142/acng-report.html | grep -A 10 -B 5 "Statistics" || echo "No statistics found yet"

echo ""
echo "🧹 Cleaning up..."
docker stop apt-cacher-local-test
docker rm apt-cacher-local-test

echo ""
echo "🎉 All tests passed! Your apt-cacher-ng setup is working correctly."
echo ""
echo "📋 Next steps:"
echo "  - Your changes are ready for PR submission"
echo "  - The GitHub Actions will run comprehensive tests when you open a PR"
echo "  - Consider testing with different client distributions if you made major changes"

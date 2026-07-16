#!/bin/bash

# Local test script for apt-cacher-ng
# Run this script to verify your changes work correctly before submitting a PR

set -e

echo "🔧 Building apt-cacher-ng Docker image..."
export TEST_IMAGE="local-apt-cacher-ng:test"
ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/;s/arm64/arm64/')
export TEST_PLATFORM="linux/${ARCH}"

docker build -t "$TEST_IMAGE" .

echo "🚀 Starting apt-cacher-ng service via Docker Compose..."
docker compose -f docker-compose.test.yml up -d

echo "⏳ Waiting for service to be ready..."
for i in {1..20}; do
  if docker compose -f docker-compose.test.yml exec -T apt-cacher-ng wget -q -t1 -O /dev/null http://localhost:3142/acng-report.html; then
    break
  fi
  echo "Waiting..."
  sleep 3
done

echo "✅ Service is ready! Running tests..."

echo ""
echo "🧪 Running tests/run_tests.sh..."
docker compose -f docker-compose.test.yml exec -T test-client /tests/run_tests.sh

echo ""
echo "🧪 Running tests/performance_test.sh..."
docker compose -f docker-compose.test.yml exec -T test-client /tests/performance_test.sh

echo ""
echo "🧪 Running tests/error_test.sh..."
docker compose -f docker-compose.test.yml exec -T test-client /tests/error_test.sh

echo ""
echo "🧹 Cleaning up..."
docker compose -f docker-compose.test.yml down -v

echo ""
echo "🎉 All local tests passed! Your apt-cacher-ng setup is working correctly."
echo ""
echo "📋 Next steps:"
echo "  - Your changes are ready for PR submission"
echo "  - The GitHub Actions will run these same tests, plus comprehensive multi-distro tests"

#!/bin/bash
set -e
APP_DIR="/mnt/c/Users/mitchell/Documents/Projects/Repositories/m-c-b/app"

# Install + start MySQL (idempotent)
sudo apt-get install -y mysql-server >/dev/null 2>&1
sudo service mysql start >/dev/null 2>&1 || true
sleep 3

# Configure a native-password user + test DB
sudo mysql <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'testpw';
CREATE DATABASE IF NOT EXISTS testdb;
FLUSH PRIVILEGES;
SQL
echo "MySQL ready"

# Start the app against the real DB
cd "$APP_DIR"
PORT=4000 DB_HOST=127.0.0.1 DB_USER=root DB_PWD=testpw DB_NAME=testdb node index.js &
APP_PID=$!
sleep 3

echo "=== GET /health ==="
curl -s -w "\nHTTP %{http_code}\n" http://127.0.0.1:4000/health

echo "=== GET / (full chain) ==="
curl -s -w "\nHTTP %{http_code}\n" http://127.0.0.1:4000/

# Clean up
kill $APP_PID 2>/dev/null || true
echo "=== done ==="

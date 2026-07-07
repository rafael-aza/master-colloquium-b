#!/bin/bash
set -euo pipefail

# --- Terraform-injected variables ---
DB_HOST="${rds_endpoint}"
DB_USER="${db_user}"
DB_PWD="${db_password}"
DB_NAME="${db_name}"
APP_REPO="${app_repo_url}"
APP_PORT="4000"
SRC_DIR="/opt/app-src"
APP_DIR="$SRC_DIR/app"

# --- OS update (minimal; skip full upgrade to keep boot time consistent) ---
apt-get update -y

# --- Install Node.js 18.x and git ---
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs git

# --- Fetch the application from the single source of truth (the repo) ---
rm -rf "$SRC_DIR"
git clone --depth 1 "$APP_REPO" "$SRC_DIR"

# --- Install dependencies ---
npm install --prefix "$APP_DIR" --omit=dev

# --- Create systemd unit ---
cat > /etc/systemd/system/demoapp.service << EOF
[Unit]
Description=3-tier demo app
After=network.target

[Service]
WorkingDirectory=$APP_DIR
Environment=PORT=$APP_PORT
Environment=DB_HOST=$DB_HOST
Environment=DB_USER=$DB_USER
Environment=DB_PWD=$DB_PWD
Environment=DB_NAME=$DB_NAME
ExecStart=/usr/bin/node $APP_DIR/index.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now demoapp

echo "Bootstrap complete. App cloned from $APP_REPO, started on :$APP_PORT"

#!/bin/bash

# Config
FRONTEND_IP="18.207.114.221"
BACKEND_IP="10.0.2.186"
DATABASE_IP="10.0.3.34"
USER="ubuntu"
APP_DIR="app"

echo "Copying frontend files..."
scp $APP_DIR/docker-compose-frontend.yml $USER@$FRONTEND_IP:/home/$USER/docker-compose.yml
scp $APP_DIR/.env $USER@$FRONTEND_IP:/home/$USER/.env

echo "Copying backend files..."
scp -o ProxyJump=$USER@$FRONTEND_IP $APP_DIR/docker-compose-backend.yml $USER@$BACKEND_IP:/home/$USER/docker-compose.yml
scp -o ProxyJump=$USER@$FRONTEND_IP $APP_DIR/.env $USER@$BACKEND_IP:/home/$USER/.env

echo "Copying database files..."
scp -o ProxyJump=$USER@$FRONTEND_IP $APP_DIR/docker-compose-database.yml $USER@$DATABASE_IP:/home/$USER/docker-compose.yml
scp -o ProxyJump=$USER@$FRONTEND_IP $APP_DIR/.env $USER@$DATABASE_IP:/home/$USER/.env

echo "Starting database..."
ssh -o ProxyCommand="ssh -W %h:%p $USER@$FRONTEND_IP" $USER@$DATABASE_IP \
"docker compose -f docker-compose.yml up -d"

echo "Starting backend..."
ssh -o ProxyCommand="ssh -W %h:%p $USER@$FRONTEND_IP" $USER@$BACKEND_IP \
"docker compose -f docker-compose.yml up -d"

echo "Starting frontend..."
ssh $USER@$FRONTEND_IP "docker compose -f docker-compose.yml up -d"

echo "All services deployed!"

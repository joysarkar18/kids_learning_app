#!/bin/bash

# Kids App Website Deployment Script
# This script builds and deploys the website to Firebase Hosting

set -e

echo "🚀 Starting deployment..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Installing..."
    npm install -g firebase-tools
fi

# Check if logged in
echo "🔐 Checking Firebase login..."
if ! firebase projects:list &> /dev/null; then
    echo "⚠️  Not logged in. Logging in to Firebase..."
    firebase login
fi

# Build the website
echo "📦 Building website..."
cd website
npm run build
cd ..

# Deploy to Firebase
echo "🌐 Deploying to Firebase Hosting..."
firebase deploy --only hosting --config firebase-website.json

echo "✅ Deployment complete!"
echo "🌍 Your site is live!"

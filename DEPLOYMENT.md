# Firebase Hosting Deployment Guide

## Prerequisites

1. Install Firebase CLI:
```bash
npm install -g firebase-tools
```

2. Login to Firebase:
```bash
firebase login
```

## Deploy the Website

### Step 1: Build the Website
```bash
cd website
npm run build
```

### Step 2: Deploy to Firebase Hosting
```bash
# From the project root directory
firebase hosting:deploy --only hosting --config firebase-website.json
```

Or deploy with a specific target:
```bash
firebase deploy --only hosting --config firebase-website.json
```

## Connect Custom Domain

### Option 1: Using Firebase Console (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **rumora-c0d7b**
3. Click on **Hosting** in the left sidebar
4. Click **Add custom domain**
5. Enter your domain name (e.g., `www.yourdomain.com` or `yourdomain.com`)
6. Follow the verification steps:
   - **If you manage DNS through your domain provider:**
     - Add the TXT record provided by Firebase to verify ownership
     - Add the A records or CNAME records for hosting
   
   - **DNS Records you'll need to add:**
     ```
     Type: TXT
     Name: @ (or your domain name)
     Value: firebase-verification-code=xxxxx
     
     Type: A (for root domain)
     Name: @
     Value: 199.36.158.100
     
     Type: CNAME (for www subdomain)
     Name: www
     Value: your-project-id.web.app
     ```

7. Wait for DNS propagation (can take up to 72 hours, usually faster)
8. Once verified, Firebase will automatically provision an SSL certificate

### Option 2: Using Firebase CLI

```bash
# Navigate to your project root
cd /Users/byteberg/Development/Projects/kids

# Add custom domain
firebase hosting:channel:deploy custom-domain --config firebase-website.json
```

## DNS Configuration Examples

### For Root Domain (yourdomain.com)
```
Type    Name    Value
A       @       199.36.158.100
A       @       199.36.158.101
A       @       199.36.158.102
A       @       199.36.158.103
TXT     @       firebase-verification-code=xxxxx
```

### For WWW Subdomain (www.yourdomain.com)
```
Type    Name    Value
CNAME   www     your-project-id.web.app
TXT     @       firebase-verification-code=xxxxx
```

### For Custom Subdomain (app.yourdomain.com)
```
Type    Name    Value
CNAME   app     your-project-id.web.app
TXT     @       firebase-verification-code=xxxxx
```

## Useful Commands

```bash
# Check hosting status
firebase hosting:channel:list

# Deploy to a preview channel
firebase hosting:channel:deploy preview-name

# View deployment logs
firebase hosting:channel:open preview-name

# Rollback to previous version
firebase hosting:rollback

# View all deployments
firebase hosting:releases:list
```

## Automated Deployment Script

Create a deploy script in your project root:

```bash
#!/bin/bash
# deploy.sh

echo "Building website..."
cd website
npm run build
cd ..

echo "Deploying to Firebase..."
firebase deploy --only hosting --config firebase-website.json

echo "Deployment complete!"
```

Make it executable:
```bash
chmod +x deploy.sh
```

Then deploy with:
```bash
./deploy.sh
```

## Troubleshooting

### Domain Verification Fails
- Wait a few minutes and retry (DNS propagation)
- Double-check DNS records are correct
- Use `dig` or online DNS tools to verify records

### SSL Certificate Issues
- Firebase automatically provisions SSL certificates
- Wait up to 24 hours after domain verification

### Deployment Fails
- Ensure you're logged in: `firebase login`
- Check Firebase project is selected: `firebase use`
- Verify build completed successfully

## Additional Resources

- [Firebase Hosting Documentation](https://firebase.google.com/docs/hosting)
- [Custom Domain Setup](https://firebase.google.com/docs/hosting/custom-domain)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)

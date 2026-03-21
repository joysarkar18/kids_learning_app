# 🚀 Quick Deployment Guide

## One-Time Setup

### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. Login to Firebase
```bash
firebase login
```

### 3. Set the correct Firebase project
```bash
firebase use rumora-c0d7b
```

## Deploy the Website

### Quick Deploy (using the script)
```bash
./deploy.sh
```

### Manual Deploy
```bash
# Build
cd website && npm run build

# Deploy
cd .. && firebase deploy --only hosting --config firebase-website.json
```

## Connect Your Custom Domain

### Step-by-Step:

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Select project: **rumora-c0d7b**

2. **Add Custom Domain**
   - Click **Hosting** in the left menu
   - Click **Add custom domain**
   - Enter your domain (e.g., `www.yourdomain.com`)

3. **Add DNS Records** (at your domain registrar)

   **For `www.yourdomain.com`:**
   ```
   Type: CNAME
   Name: www
   Value: rumora-c0d7b.web.app
   ```

   **For root domain `yourdomain.com`:**
   ```
   Type: A
   Name: @
   Value: 199.36.158.100
   ```

   **Verification Record:**
   ```
   Type: TXT
   Name: @
   Value: (copy the verification code from Firebase)
   ```

4. **Wait for Verification**
   - DNS propagation takes 5 minutes to 72 hours
   - Firebase will automatically issue SSL certificate

5. **Done!** Your site will be live at your custom domain

## Common Domain Registrars

| Registrar | DNS Settings Link |
|-----------|------------------|
| GoDaddy | https://www.godaddy.com/domains/domain-management |
| Namecheap | https://www.namecheap.com/myaccount/domain/ |
| Google Domains | https://domains.google.com/registrar |
| Cloudflare | https://dash.cloudflare.com/ |
| Bluehost | https://my.bluehost.com/cgi/domains.cgi |

## Verify Deployment

After deploying, your site will be available at:
- `https://rumora-c0d7b.web.app`
- `https://rumora-c0d7b.firebaseapp.com`

After connecting your domain:
- `https://www.yourdomain.com`

## Troubleshooting

**"Firebase command not found"**
```bash
npm install -g firebase-tools
```

**"Not logged in"**
```bash
firebase login
```

**"No project active"**
```bash
firebase use rumora-c0d7b
```

**Domain verification pending**
- Wait for DNS propagation (use https://dnschecker.org/)
- Verify DNS records are correct

## Need Help?

Run this command to check your setup:
```bash
firebase projects:list
firebase hosting:channel:list
```

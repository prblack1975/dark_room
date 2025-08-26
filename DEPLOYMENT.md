# Web Deployment Instructions

## Files in this directory
This directory contains a complete web build of the Dark Room game.

## Deployment Options

### 1. Static Web Hosting
Upload all files to any static web hosting service:
- GitHub Pages
- Netlify
- Vercel
- AWS S3 + CloudFront
- Any web server

### 2. Local Testing
Serve locally using Python or Node.js:
```bash
# Using Python 3
python -m http.server 8000

# Using Python 2
python -m SimpleHTTPServer 8000

# Using Node.js (http-server)
npx http-server
```

### 3. GitHub Pages Deployment
If deploying to GitHub Pages, ensure the base-href is set correctly:
- For user/organization pages: --base-href=/
- For project pages: --base-href=/repository-name/

## Important Notes
- All files must be served from the same domain
- HTTPS is recommended for production
- Enable gzip compression on your server for better performance
- The game requires web audio APIs (modern browser required)

## Build Information
- Version: 1.1.0+2
- Build Type: release
- Build Time: 2025-08-26T14:14:26Z
- Build Size:  24M

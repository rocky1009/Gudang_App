# Deploy Flutter Web App to Railway

## Quick Deploy

### Option 1: Deploy from GitHub (Recommended)

1. **Push to GitHub** (if not already done):
   ```bash
   git add .
   git commit -m "Add web deployment configuration"
   git push
   ```

2. **Deploy on Railway**:
   - Go to [railway.app](https://railway.app)
   - Click "New Project"
   - Choose "Deploy from GitHub repo"
   - Select your repository: `rocky1009/proyek_gudang`
   - Railway will auto-detect the `railway.json` and `Dockerfile.web`
   - Set the **Root Directory** to: `frontend/proyek_gudang`
   - Click "Deploy"

3. **Configure Domain**:
   - Once deployed, go to Settings → Networking
   - Click "Generate Domain" to get a free Railway domain
   - Your app will be available at: `https://your-app-name.up.railway.app`

### Option 2: Deploy using Railway CLI

1. **Install Railway CLI**:
   ```bash
   npm i -g @railway/cli
   ```

2. **Login**:
   ```bash
   railway login
   ```

3. **Deploy**:
   ```bash
   cd c:\Kuliah\ProyekTA\proyek_victoria\frontend\proyek_gudang
   railway init
   railway up
   ```

## What's Deployed

- **Dockerfile.web**: Multi-stage Docker build
  - Stage 1: Builds Flutter web with official Flutter Docker image
  - Stage 2: Serves with nginx (lightweight, production-ready)

- **nginx.conf**: Optimized nginx configuration
  - Handles Flutter routing (SPA support)
  - Gzip compression for faster loading
  - Static asset caching
  - Security headers

- **railway.json**: Railway deployment configuration
  - Specifies Dockerfile location
  - Configures restart policy

## Features Configured

✅ **PWA Support**: App can be installed on desktop/mobile browsers
✅ **Responsive Design**: Works on all screen sizes (mobile, tablet, desktop)
✅ **Fast Loading**: Gzip compression and asset caching
✅ **SEO Ready**: Proper meta tags and descriptions
✅ **Secure**: Security headers configured
✅ **SPA Routing**: All routes handled correctly

## Environment Variables (if needed)

If you need to configure API URL or other environment variables:

1. In Railway dashboard, go to your project
2. Click "Variables" tab
3. Add variables (e.g., `API_BASE_URL`)
4. Update your Flutter code to read from environment

## Testing Locally (Optional)

Build and test locally before deploying:

```bash
cd c:\Kuliah\ProyekTA\proyek_victoria\frontend\proyek_gudang

# Build web version
flutter build web --release --web-renderer html

# Serve locally (requires Python or a local server)
cd build\web
python -m http.server 8080
```

Then open: http://localhost:8080

## Architecture

```
Railway (nginx) → Flutter Web App → Backend API (Railway)
     ↓
User's Browser
```

Your web app will communicate with your existing backend at:
`https://proyekgudangbackend2-production.up.railway.app`

## Troubleshooting

**Build fails?**
- Check Railway build logs
- Ensure all dependencies in pubspec.yaml are web-compatible

**App loads but API fails?**
- Check CORS settings on backend
- Verify backend URL is correct in your Flutter code

**Routing issues?**
- nginx.conf handles SPA routing
- All routes redirect to index.html

## Cost

Railway Free Tier includes:
- $5 credit per month
- Enough for small to medium web apps
- Auto-sleeps when not in use

## Next Steps

After deployment:
1. Test all features in web browser
2. Test on mobile browsers
3. Share the Railway URL with users
4. Consider custom domain (requires Railway Pro)

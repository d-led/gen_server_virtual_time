# GitHub Pages Deployment Setup - Summary

## ✅ What's Been Created

### 1. GitHub Actions Workflow

**File:** `.github/workflows/test-and-deploy-diagrams.yml`

Automatically runs on every push to `main` and pull requests:

- Runs all tests with Elixir 1.16 + OTP 26
- Generates sequence diagrams in `test/output/`
- Deploys diagrams to GitHub Pages (main branch only)
- Caches dependencies for faster builds

### 2. Documentation

- **`.github/README.md`** - Detailed workflow documentation
- **`GITHUB_PAGES_SETUP.md`** - Step-by-step setup guide
- **`DEPLOYMENT_SUMMARY.md`** - This file

### 3. Updated README

Added badges linking to:

- ✅ Hex package: https://hex.pm/packages/gen_server_virtual_time
- ✅ HexDocs: https://hexdocs.pm/gen_server_virtual_time
- ✅ GitHub Pages: https://d-led.github.io/gen_server_virtual_time/

## 🚀 Next Steps

### 1. Enable GitHub Pages (One-Time Setup)

1. Go to: https://github.com/d-led/gen_server_virtual_time/settings/pages
2. Under **Source**, select **GitHub Actions**
3. Save

### 2. Push to Deploy

```bash
# Add all new files
git add .github/workflows/test-and-deploy-diagrams.yml
git add .github/README.md
git add GITHUB_PAGES_SETUP.md
git add DEPLOYMENT_SUMMARY.md
git add README.md

# Commit
git commit -m "Add GitHub Actions workflow for diagram deployment"

# Push (triggers deployment)
git push origin main
```

### 3. Watch It Deploy

1. Go to: https://github.com/d-led/gen_server_virtual_time/actions
2. Watch the workflow run (2-3 minutes)
3. Once complete, visit: **https://d-led.github.io/gen_server_virtual_time/**

## 📊 What Gets Published

Your beautiful sequence diagrams:

### Mermaid Diagrams (8 total)

- Simple request-response
- Authentication pipeline
- Sync vs async communication
- Timeline with timestamps
- Dining philosophers (2, 3, and 5 philosophers)

### PlantUML Diagrams (2 total)

- Alice and Bob conversation
- Pub-sub pattern

### Landing Page

A beautiful `index.html` with:

- Grid layout of all diagrams
- Categorization (Mermaid vs PlantUML)
- Descriptions and links
- Responsive design

## 🔄 Workflow Behavior

| Event                | Test Job | Deploy Job |
| -------------------- | -------- | ---------- |
| Push to `main`       | ✅ Runs  | ✅ Runs    |
| Push to other branch | ✅ Runs  | ❌ Skipped |
| Pull request         | ✅ Runs  | ❌ Skipped |

## 📦 Artifacts

Every workflow run saves `test/output/` as artifacts for 7 days:

- Download from the Actions tab
- Preview diagrams before deployment
- Useful for debugging

## 🎯 Key URLs After Setup

| Resource             | URL                                                      |
| -------------------- | -------------------------------------------------------- |
| 🎬 **Live Diagrams** | https://d-led.github.io/gen_server_virtual_time/         |
| 📦 **Hex Package**   | https://hex.pm/packages/gen_server_virtual_time          |
| 📖 **Documentation** | https://hexdocs.pm/gen_server_virtual_time               |
| 🔧 **Repository**    | https://github.com/d-led/gen_server_virtual_time         |
| ⚡ **Workflows**     | https://github.com/d-led/gen_server_virtual_time/actions |

## 💡 Quick Tips

### Local Preview

```bash
mix test
cd test/output
python3 -m http.server 8000
# Open http://localhost:8000
```

### Force Redeploy

```bash
git commit --allow-empty -m "Redeploy diagrams"
git push origin main
```

### Check Workflow Status

```bash
# View in browser
open https://github.com/d-led/gen_server_virtual_time/actions

# Or use GitHub CLI
gh workflow view "Test and Deploy Diagrams"
gh run list --workflow="test-and-deploy-diagrams.yml"
```

## 🐛 Common Issues

### Pages Not Enabled

**Solution:** Go to Settings → Pages → Source → Select "GitHub Actions"

### Workflow Permission Error

**Solution:** Settings → Actions → General → Workflow permissions → "Read and
write"

### 404 on Pages URL

**Solution:** Wait 1-2 minutes after first deployment, clear cache

### Diagrams Don't Render

**Solution:** Check browser console, verify CDN access, try regenerating

## 📚 Learn More

- [GitHub Pages Setup Guide](GITHUB_PAGES_SETUP.md) - Detailed instructions
- [Workflow Documentation](.github/README.md) - Technical details
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [GitHub Pages Docs](https://docs.github.com/en/pages)

## 🎉 That's It!

Once you push and enable Pages, your diagrams will be automatically published on
every commit to `main`. No manual deployment needed!

**Your diagrams will be live at:**
https://d-led.github.io/gen_server_virtual_time/

---

_Questions? See GITHUB_PAGES_SETUP.md for troubleshooting._

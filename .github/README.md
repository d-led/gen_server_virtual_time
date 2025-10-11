# GitHub Actions & Pages Setup

This directory contains GitHub Actions workflows for the GenServerVirtualTime project.

## Workflows

### `test-and-deploy-diagrams.yml`

Automatically tests the project and deploys generated sequence diagrams to GitHub Pages.

**Triggers:**
- Push to `main` branch → Runs tests + deploys diagrams
- Pull requests → Runs tests only (no deployment)

**What it does:**
1. ✅ Runs all tests (including diagram generation)
2. 📸 Generates sequence diagrams in `test/output/`
3. 📦 Saves diagrams as artifacts (7 days)
4. 🚀 Deploys to GitHub Pages (main branch only)

## Setup Instructions

### First-Time Setup

1. **Enable GitHub Pages in your repository:**
   - Go to **Settings** → **Pages**
   - Under **Source**, select **GitHub Actions**
   - Save

2. **Push the workflow:**
   ```bash
   git add .github/workflows/test-and-deploy-diagrams.yml
   git commit -m "Add GitHub Actions workflow for diagram deployment"
   git push origin main
   ```

3. **Wait for the action to complete:**
   - Go to **Actions** tab in your repository
   - Watch the workflow run
   - Once complete, your diagrams will be live!

4. **Find your Pages URL:**
   - Go to **Settings** → **Pages**
   - Your URL will be: `https://USERNAME.github.io/REPO_NAME/`
   - Example: `https://d-led.github.io/gen_server_virtual_time/`

5. **Update the README:**
   - Edit the badge link in `README.md` with your actual Pages URL

## What Gets Published

Every push to `main` publishes these diagrams:

### Mermaid Diagrams
- **Simple Request-Response** - Basic client-server interaction
- **Authentication Pipeline** - Multi-stage auth flow
- **Sync vs Async** - Different message types visualization
- **Timeline with Timestamps** - Virtual time progression
- **Dining Philosophers (2, 3, 5)** - Classic concurrency problem

### PlantUML Diagrams
- **Alice and Bob** - Simple conversation
- **Pub-Sub Pattern** - One-to-many messaging

### Index Page
- Beautiful landing page with all diagrams
- Organized by type with descriptions
- Responsive design

## Local Testing

Preview diagrams locally before pushing:

```bash
# Generate diagrams
mix test

# Serve locally
cd test/output
python3 -m http.server 8000

# Open http://localhost:8000
```

## Customization

### Deploy from different branch

Edit `.github/workflows/test-and-deploy-diagrams.yml`:

```yaml
on:
  push:
    branches:
      - main  # Trunk-based development
```

### Change artifact retention

```yaml
- name: Upload diagram artifacts
  uses: actions/upload-artifact@v4
  with:
    retention-days: 30  # Change from 7
```

### Add more diagrams

1. Add tests in `test/diagram_generation_test.exs` or `test/dining_philosophers_test.exs`
2. Write diagrams to `test/output/`
3. Update the index page in the test
4. Push to `main` - automatic deployment!

## Troubleshooting

### Workflow fails on permissions

**Solution:** Ensure workflow permissions are set correctly:
- Go to **Settings** → **Actions** → **General**
- Under **Workflow permissions**, select **Read and write permissions**
- Save

### Pages not deploying

**Solution:** 
1. Check **Settings** → **Pages** → Source is set to **GitHub Actions**
2. Verify the workflow completed successfully in **Actions** tab
3. Wait 1-2 minutes for DNS propagation

### 404 on Pages URL

**Solution:**
- Clear browser cache
- Try incognito mode
- Check that `test/output/index.html` exists
- Verify deployment step succeeded

## CI Pipeline Flow

```
Push to main
     ↓
┌────────────────┐
│  Test Job      │
│  - Checkout    │
│  - Setup Elixir│
│  - Run tests   │ → Generates diagrams in test/output/
│  - Upload      │ → Saves artifacts
└────────┬───────┘
         ↓
┌────────────────┐
│  Deploy Job    │
│  - Download    │ → Gets test/output/ artifacts
│  - Configure   │ → Setup GitHub Pages
│  - Deploy      │ → Publish to Pages
└────────────────┘
         ↓
   GitHub Pages Live! 🎉
```

## URLs

| Type | URL |
|------|-----|
| Repository | `https://github.com/USERNAME/REPO_NAME` |
| Actions | `https://github.com/USERNAME/REPO_NAME/actions` |
| Pages Settings | `https://github.com/USERNAME/REPO_NAME/settings/pages` |
| Published Site | `https://USERNAME.github.io/REPO_NAME/` |

## Pro Tips

1. **Badge in README:**
   ```markdown
   [![Pages](https://img.shields.io/badge/diagrams-live-blue)](https://USERNAME.github.io/REPO_NAME/)
   ```

2. **View artifacts without deploying:**
   - Any workflow run saves artifacts for 7 days
   - Download from the **Actions** tab

3. **Test PRs see diagrams too:**
   - PR workflows generate diagrams as artifacts
   - Download and view locally to review changes

4. **Cache speeds up builds:**
   - The workflow caches `deps/` and `_build/`
   - Subsequent runs are much faster

## Learn More

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Elixir CI Best Practices](https://github.com/actions/starter-workflows/blob/main/ci/elixir.yml)


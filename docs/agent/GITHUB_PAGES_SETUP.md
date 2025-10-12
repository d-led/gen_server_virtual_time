# GitHub Pages Setup Guide

Quick reference for setting up and accessing your published sequence diagrams.

## 🚀 Quick Setup (First Time)

### 1. Enable GitHub Pages

1. Go to your repository on GitHub:
   `https://github.com/d-led/gen_server_virtual_time`
2. Click **Settings** → **Pages** (in the left sidebar)
3. Under **Source**, select **GitHub Actions** from the dropdown
4. Click **Save**

### 2. Push the Workflow

```bash
git add .github/workflows/test-and-deploy-diagrams.yml
git add .github/README.md
git add GITHUB_PAGES_SETUP.md
git add README.md
git commit -m "Add GitHub Actions workflow for diagram deployment"
git push origin main
```

### 3. Wait for Deployment

1. Go to the **Actions** tab in your repository
2. Watch the workflow run (it will run automatically on push)
3. Wait for both jobs to complete:
   - ✅ Test (generates diagrams)
   - ✅ Deploy (publishes to Pages)

### 4. Access Your Diagrams

Once deployed, your diagrams will be available at:

**https://d-led.github.io/gen_server_virtual_time/**

The index page shows all generated diagrams with a beautiful interface!

## 📊 What Gets Published

Every push to `main` automatically publishes:

### Mermaid Sequence Diagrams

- **Simple Request-Response** - Basic client-server pattern
- **Authentication Pipeline** - Multi-stage auth flow
- **Sync vs Async Communication** - Different arrow styles
- **Timeline with Timestamps** - Virtual time progression
- **Dining Philosophers (2, 3, 5)** - Concurrency visualization

### PlantUML Sequence Diagrams

- **Alice and Bob** - Simple conversation
- **Pub-Sub Pattern** - One-to-many broadcast

### Interactive Features

- Self-contained HTML files (no external dependencies beyond CDN)
- Mermaid.js live rendering
- PlantUML server-side rendering
- Source code viewing
- Responsive design

## 🔧 How It Works

```
Developer pushes to main
        ↓
┌─────────────────────┐
│ GitHub Actions      │
│ - Checkout code     │
│ - Setup Elixir 1.16 │
│ - Install deps      │
│ - Run tests         │ ← Tests generate diagrams in test/output/
└──────────┬──────────┘
           ↓
    Artifacts saved (7 days)
           ↓
┌─────────────────────┐
│ Deploy to Pages     │
│ - Download output   │
│ - Configure Pages   │
│ - Upload & deploy   │
└──────────┬──────────┘
           ↓
  Live on GitHub Pages! 🎉
```

## 🎯 Key URLs

| Resource           | URL                                                             |
| ------------------ | --------------------------------------------------------------- |
| **Live Diagrams**  | https://d-led.github.io/gen_server_virtual_time/                |
| **Repository**     | https://github.com/d-led/gen_server_virtual_time                |
| **Workflows**      | https://github.com/d-led/gen_server_virtual_time/actions        |
| **Pages Settings** | https://github.com/d-led/gen_server_virtual_time/settings/pages |
| **Hex Package**    | https://hex.pm/packages/gen_server_virtual_time                 |
| **Documentation**  | https://hexdocs.pm/gen_server_virtual_time                      |

## 🧪 Local Preview

Test diagrams locally before pushing:

```bash
# Generate diagrams
mix test

# Serve locally
cd test/output
python3 -m http.server 8000

# Open in browser
open http://localhost:8000
```

## 🐛 Troubleshooting

### Workflow Fails with Permission Error

**Problem:** Action fails with "permission denied" or similar.

**Solution:**

1. Go to **Settings** → **Actions** → **General**
2. Scroll to **Workflow permissions**
3. Select **Read and write permissions**
4. Check **Allow GitHub Actions to create and approve pull requests**
5. Click **Save**

### Pages Shows 404

**Problem:** GitHub Pages URL returns 404 Not Found.

**Solution:**

1. Verify workflow completed successfully in **Actions** tab
2. Wait 1-2 minutes (DNS propagation)
3. Check **Settings** → **Pages** shows "Your site is live at..."
4. Clear browser cache or try incognito mode
5. Verify `test/output/index.html` exists in your repo

### Diagrams Not Rendering

**Problem:** HTML loads but diagrams don't render.

**Solution:**

1. Open browser console (F12) to check for errors
2. Verify CDN is accessible
   (https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js)
3. Check PlantUML server is up (https://www.plantuml.com/plantuml/)
4. Try regenerating: `mix test --force`

### Workflow Never Triggers

**Problem:** Push to main but no workflow runs.

**Solution:**

1. Verify `.github/workflows/test-and-deploy-diagrams.yml` is committed
2. Check file is not in `.gitignore`
3. Ensure `main` branch is spelled correctly in workflow
4. Go to **Actions** tab → Click "Enable workflows" if disabled

## 🎨 Customization

### Add New Diagrams

1. Add test to `test/diagram_generation_test.exs`:

   ```elixir
   test "generates my new diagram" do
     simulation = # ... your simulation
     mermaid = ActorSimulation.trace_to_mermaid(simulation)
     html = generate_mermaid_html(mermaid, "My Diagram")
     File.write!("test/output/my_diagram.html", html)
   end
   ```

2. Update index page in the same test file

3. Run locally: `mix test`

4. Push to deploy: `git push origin main`

### Change Deployment Branch

Edit `.github/workflows/test-and-deploy-diagrams.yml`:

```yaml
on:
  push:
    branches:
      - main # Trunk-based development
```

### Deploy on Tags Only

```yaml
on:
  push:
    tags:
      - "v*" # Deploy only on version tags
```

## 📈 Monitoring

### View Workflow Runs

- Go to **Actions** tab
- See all runs, including duration and status
- Download artifacts from any run (available for 7 days)

### View Deployment History

- **Settings** → **Pages** shows deployment history
- Each deployment is linked to the workflow run

### Check Build Logs

1. Go to **Actions** tab
2. Click on a workflow run
3. Click on job name (Test or Deploy)
4. View detailed logs

## 💡 Pro Tips

1. **PR Previews:** Pull requests run tests and generate artifacts, but don't
   deploy. Download artifacts to preview changes.

2. **Fast Iteration:** Use `mix test` locally to instantly see diagram changes
   without waiting for CI.

3. **Cache Benefits:** The workflow caches Elixir dependencies, making
   subsequent runs much faster.

4. **Artifact Download:** Don't want to wait for Pages? Download artifacts
   directly from any workflow run.

5. **Multiple Formats:** Generate both Mermaid and PlantUML to see which renders
   better for your use case.

## 📚 Next Steps

- ✅ Set up GitHub Pages (you're here!)
- 📝 Add more diagram tests
- 🎨 Customize HTML styling
- 🔗 Share your Pages URL
- 📊 Analyze workflow performance

## 🤝 Contributing

When adding diagram features:

1. Test locally first: `mix test`
2. Verify HTML renders correctly
3. Update index page with new diagrams
4. Push and verify deployment

---

**Need help?** Check the [GitHub Actions README](.github/README.md) for more
details.

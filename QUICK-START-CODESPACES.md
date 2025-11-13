# Quick Start: GitHub Codespaces for OnlyOffice

## 🚀 Get Started in 3 Commands

### Option 1: Automatic Setup (Recommended)

```bash
cd "/Users/bassel/Only Office SourceCode/DocumentServer"

# This will fork, commit, and push everything
./setup-github-fork.sh

# Then go to GitHub and create Codespace:
# https://github.com/YOUR_USERNAME/DocumentServer
# Click: Code → Codespaces → Create codespace
```

### Option 2: Manual Setup

```bash
# 1. Create fork on GitHub.com
# Go to: https://github.com/ONLYOFFICE/DocumentServer
# Click "Fork" button

# 2. Update your local repo
cd "/Users/bassel/Only Office SourceCode/DocumentServer"
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/DocumentServer.git

# 3. Commit and push
git add .
git commit -m "Add Codespaces configuration"
git push -u origin master

# 4. Create Codespace on GitHub.com
```

## Once Codespace Opens

```bash
# Build everything (5-10 minutes first time)
./build-with-version.sh

# Start services
./start-services.sh

# Check status
sudo supervisorctl status

# Access DocumentServer
# Click PORTS tab → port 9090 → open in browser
```

## 🎯 What You Get

✅ **Full Linux environment** - No Mac issues  
✅ **All dependencies installed** - Node, Python, C++ toolchain  
✅ **Database services running** - PostgreSQL, RabbitMQ, Redis  
✅ **No local resource usage** - Runs in cloud  
✅ **VSCode integration** - Familiar editor  
✅ **Shareable preview URLs** - Test with your team  

## 💰 Cost

**Free tier**: 60 core-hours/month
- 2-core machine = 30 hours/month FREE
- Perfect for development

**After free tier**: $0.18/hour (2-core)
- ~$14/month for 80 hours of development
- Stop Codespace when not using to save money

## 🛠️ Daily Workflow

```bash
# Morning: Open Codespace
# (resumes where you left off)

# Make changes to code
# Example: add chat feature in server/DocService/sources/

# Rebuild
./rebuild.sh

# Test
# Access via PORTS tab URL

# Evening: Stop Codespace
# (Click Codespace name → Stop)
```

## 🎨 Example: Adding Embedded Chat

See `CODESPACES-SETUP.md` for complete code examples of:
- Backend WebSocket chat handler
- Frontend chat UI component
- Integration with document editing

## 📖 Full Documentation

- `CODESPACES-SETUP.md` - Complete setup guide
- `VERSION-FIX-README.md` - Version reset fix details
- `BUILD-FIX-NOTES.md` - Build troubleshooting

## ⚡ Pro Tips

1. **Set auto-stop** to 30 minutes (Settings → Auto-stop)
2. **Use 2-core machine** unless building frequently
3. **Commit often** - Your work persists even if Codespace deleted
4. **Make port 9090 public** - Share with team for testing

## 🆘 Having Issues?

```bash
# Build failed?
./rebuild.sh --clean

# Services won't start?
docker ps  # Check if databases running
./start-services.sh

# Need logs?
sudo supervisorctl tail -f docservice
```

## 🎉 That's It!

You now have a **professional OnlyOffice development environment** that:
- Works perfectly (no platform issues)
- Costs almost nothing
- Can be shared with team
- Accessible from anywhere

**Ready?** Run `./setup-github-fork.sh` now!

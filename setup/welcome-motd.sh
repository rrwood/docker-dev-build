#!/bin/bash
#
# Welcome Message - Display on first login
# This creates a message of the day for new users
#

cat << 'EOF'

╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║       Welcome to Your Development Container! 🚀               ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

📋 First Time Setup - Important!

   🔐 1. Change your default password:
      cd ~/setup && ./change-password.sh

   🔑 2. Generate SSH keys (recommended):
      cd ~/setup && ./generate-ssh-keys.sh

   📖 3. Read the setup guide:
      cat ~/setup/README.md

🛠️  Available Tools:

   • Claude CLI:    setup-claude
   • LiteLLM:       setup-litellm
   • ngrok:         install-ngrok

📁 Your Workspace:

   • Working directory: /app
   • Setup scripts:     ~/setup/
   • Config files:      ~/.config/

📚 Documentation:

   • Setup guide:       ~/setup/README.md
   • GitHub repo:       https://github.com/rrwood/docker-dev-build

💡 Quick Commands:

   • Change password:   cd ~/setup && ./change-password.sh
   • SSH keys:          cd ~/setup && ./generate-ssh-keys.sh
   • Container info:    hostname && whoami && ip addr

───────────────────────────────────────────────────────────────

EOF

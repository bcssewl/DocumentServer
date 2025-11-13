# GitHub Codespaces Setup for OnlyOffice Custom Development

This repository is configured to run in GitHub Codespaces with full OnlyOffice DocumentServer development environment.

## Initial Setup

### Step 1: Fork This Repository

Since this is cloned from the official OnlyOffice repo, you need your own fork:

```bash
# On GitHub.com:
# 1. Go to https://github.com/ONLYOFFICE/DocumentServer
# 2. Click "Fork" button (top right)
# 3. Create fork in your account
```

### Step 2: Update Your Local Repository

```bash
cd "/Users/bassel/Only Office SourceCode/DocumentServer"

# Add your fork as the origin
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/DocumentServer.git

# Push your custom changes to your fork
git add .
git commit -m "Add custom development setup with Codespaces support"
git push -u origin master
```

### Step 3: Launch Codespace

```bash
# On GitHub.com:
# 1. Go to YOUR forked repository
# 2. Click the green "Code" button
# 3. Click "Codespaces" tab
# 4. Click "Create codespace on master"
```

**Wait 3-5 minutes** for the Codespace to build and configure.

## Working in Codespaces

### First Time Build

Once your Codespace opens:

```bash
# In Codespace terminal
cd /workspace

# Build all components with version tracking
./build-with-version.sh

# This will take 5-10 minutes
# Build log will show progress for each component
```

### Starting DocumentServer

```bash
# Start all services
./start-services.sh

# Check if services are running
sudo supervisorctl status

# Should show:
#   docservice: RUNNING
#   converter: RUNNING
#   nginx: RUNNING
```

### Accessing DocumentServer

1. **In VSCode Codespace**: 
   - Click the "PORTS" tab (bottom panel)
   - Find port 9090
   - Click the globe icon to open in browser
   - URL will be like: `https://yourname-documentserver-9090.preview.app.github.dev`

2. **Share with your team**:
   - Make port 9090 public (right-click in PORTS tab)
   - Share the URL

### Making Code Changes

#### Example: Adding Embedded Chat

**1. Create chat backend service:**

```bash
# In Codespace terminal
cd /workspace/server/DocService/sources

# Create new chat handler
nano chatHandler.js
```

```javascript
// chatHandler.js
'use strict';

const logger = require('./../../Common/sources/logger');

class ChatHandler {
    constructor(pubsub) {
        this.pubsub = pubsub;
    }

    async sendMessage(docId, userId, message) {
        const chatMessage = {
            docId,
            userId,
            message,
            timestamp: Date.now()
        };
        
        // Broadcast to all users in the document
        this.pubsub.publish(`chat:${docId}`, JSON.stringify(chatMessage));
        
        logger.info('Chat message sent: %s', JSON.stringify(chatMessage));
        return chatMessage;
    }

    subscribeToChatRoom(docId, callback) {
        this.pubsub.subscribe(`chat:${docId}`, (message) => {
            callback(JSON.parse(message));
        });
    }
}

module.exports = ChatHandler;
```

**2. Integrate into DocsCoServer:**

```bash
nano DocsCoServer.js
```

Add at the top:
```javascript
const ChatHandler = require('./chatHandler');
const chatHandler = new ChatHandler(pubsub);
```

Add WebSocket handler for chat:
```javascript
// Around line 4000, where other message handlers are
case 'chat':
    if (data.message) {
        yield* chatHandler.sendMessage(conn.docId, conn.user.id, data.message);
    }
    break;
```

**3. Add frontend chat UI:**

```bash
cd /workspace/web-apps/apps/documenteditor/main/app/view

# Create chat panel component
nano ChatPanel.js
```

```javascript
define([
    'common/main/lib/component/BaseView'
], function () {
    'use strict';

    DE.Views.ChatPanel = Common.UI.BaseView.extend({
        el: '#chat-panel',
        
        template: _.template([
            '<div class="chat-container">',
            '  <div id="chat-messages" class="chat-messages"></div>',
            '  <div class="chat-input">',
            '    <input type="text" id="chat-message-input" placeholder="Type a message..."/>',
            '    <button id="chat-send-btn">Send</button>',
            '  </div>',
            '</div>'
        ].join('')),
        
        initialize: function(options) {
            Common.UI.BaseView.prototype.initialize.call(this, arguments);
            this.socketio = options.socketio;
        },
        
        render: function() {
            this.$el.html(this.template());
            
            // Set up event listeners
            $('#chat-send-btn').on('click', this.sendMessage.bind(this));
            $('#chat-message-input').on('keypress', (e) => {
                if (e.which === 13) this.sendMessage();
            });
            
            // Listen for incoming messages
            this.socketio.on('chat', this.onChatMessage.bind(this));
            
            return this;
        },
        
        sendMessage: function() {
            const input = $('#chat-message-input');
            const message = input.val().trim();
            
            if (message) {
                this.socketio.emit('message', {
                    type: 'chat',
                    message: message
                });
                input.val('');
            }
        },
        
        onChatMessage: function(data) {
            const msgDiv = $('<div class="chat-message"></div>');
            msgDiv.text(`${data.userId}: ${data.message}`);
            $('#chat-messages').append(msgDiv);
            $('#chat-messages').scrollTop($('#chat-messages')[0].scrollHeight);
        }
    });
});
```

**4. Rebuild and test:**

```bash
# Rebuild the changed components
cd /workspace
./rebuild.sh

# Services will restart automatically
# Test your changes at the forwarded port URL
```

### Development Workflow

```bash
# Daily workflow:
1. Make code changes in VSCode
2. ./rebuild.sh                    # Rebuild modified components
3. Test at the Codespace URL
4. git commit -m "Add feature X"
5. git push                        # Backup your work
```

### Debugging

**View logs:**
```bash
# Real-time logs
sudo supervisorctl tail -f docservice
sudo supervisorctl tail -f converter

# Or check log files
tail -f /var/log/onlyoffice/documentserver/docservice.log
tail -f /var/log/onlyoffice/documentserver/converter.log
```

**Restart specific service:**
```bash
sudo supervisorctl restart docservice
sudo supervisorctl restart converter
```

**Full restart:**
```bash
./stop-services.sh
./start-services.sh
```

## Integrating with Your App

### From Your Mac App

```javascript
// Your app connects to Codespace URL
const documentServerUrl = 'https://yourname-documentserver-9090.preview.app.github.dev';

// Initialize OnlyOffice editor
const docEditor = new DocsAPI.DocEditor("placeholder", {
    documentType: 'word',
    document: {
        url: 'https://your-storage.com/document.docx',
        key: 'unique-document-key'
    },
    editorConfig: {
        callbackUrl: 'https://your-app.com/callback'
    }
});
```

### Exposing Your Local App to Codespace

If you need Codespace to callback to your Mac:

```bash
# On your Mac, use ngrok or similar
ngrok http 3000

# Use the ngrok URL as callbackUrl in Codespace
```

## Cost Management

**To minimize costs:**

1. **Stop Codespace when not using** (doesn't delete, just stops billing)
   - Click Codespace name → Stop Codespace

2. **Use 2-core machine** (not 4-core)
   - Settings → Machine type → 2-core

3. **Set auto-stop timeout**
   - Settings → Set timeout to 30 minutes

4. **Delete old Codespaces**
   - Keep only active development Codespace

**Free tier:** 60 core-hours/month = 30 hours on 2-core machine

## Troubleshooting

### Services won't start

```bash
# Check if databases are running
docker ps

# If not, start them
cd .devcontainer && docker-compose up -d

# Then try starting services again
./start-services.sh
```

### Build fails

```bash
# Clean and rebuild
rm -rf server/node_modules
rm -rf web-apps/node_modules
rm -rf sdkjs/node_modules

./build-with-version.sh
```

### Port not accessible

1. Check PORTS tab in VSCode
2. Ensure port 9090 visibility is set to "Public"
3. Try stopping and restarting the Codespace

### Out of disk space

```bash
# Clean up
docker system prune -a
npm cache clean --force
```

## Backing Up Your Work

**Always commit and push regularly:**

```bash
# Commit your changes
git add .
git commit -m "Add embedded chat feature"
git push

# Your work is safe even if Codespace is deleted
```

## Next Steps

1. ✅ Fork the repository
2. ✅ Push your custom changes
3. ✅ Create Codespace
4. ✅ Build OnlyOffice
5. ✅ Start developing your custom features (embedded chat, etc.)
6. ✅ Integrate with your app

---

**Need help?** Check the logs or create an issue in your fork.

**Want to share your Codespace?**
- Make port 9090 public
- Share the preview URL with your team
- They can test without setting up anything!

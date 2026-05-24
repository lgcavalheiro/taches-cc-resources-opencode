# Auto-Installation for MCP Servers

Complete guide for automatically installing MCP servers in Opencode with safe credential management.

## Overview

When you build an MCP server, you want it instantly available in Opencode.

This guide provides scripts and patterns for zero-friction installation.

## The Problem

Manual MCP installation requires:
1. Adding to Opencode via CLI (`opencode mcp add`)
2. Copying credentials to multiple places
3. Restarting Opencode
4. Testing that everything works

This is tedious and error-prone.

## The Solution

A manual configuration approach with secure patterns:
1. Store credentials in `~/.mcp_secrets` with `chmod 600`
2. Use variable expansion (`${VAR}`) in all configs
3. Install in Opencode (user scope)
4. Manually update Opencode config with variable references
5. Never write hardcoded secrets to configuration files

**Why not automated?** Auto-installation scripts that write actual credential values to configs are insecure. The recommended pattern uses variable expansion everywhere.

## Secure Installation Guide

### Step 1: Set Up Secrets

Create `~/.mcp_secrets`:
```bash
# ~/.mcp_secrets
export META_ACCESS_TOKEN="your_token_here"
export META_AD_ACCOUNT_ID="act_123456"
export STRIPE_API_KEY="sk_live_xyz"
```

Secure it:
```bash
chmod 600 ~/.mcp_secrets
```

Load in shell profile (`~/.zshrc` or `~/.bashrc`):
```bash
# Load MCP secrets
if [ -f ~/.mcp_secrets ]; then
  source ~/.mcp_secrets
fi
```

Reload:
```bash
source ~/.zshrc  # or ~/.bashrc
```

### Step 2: Install in Opencode

```bash
# Source secrets
source ~/.mcp_secrets

# Install with actual values (Opencode stores them securely)
opencode mcp add
```

**Note:** When using `opencode mcp add`, you pass actual values. Opencode stores them securely in `~/.config/opencode/settings.json` and references them correctly.

### Step 3: Configure Opencode

Edit `~/.config/opencode/settings.json`:

```json
{
  "mcpServers": {
    "meta-ads": {
      "command": "/Users/username/.local/bin/uv",
      "args": ["--directory", "/Users/username/Developer/mcp/meta-ads-mcp", "run", "python", "-m", "src.server"],
      "cwd": "/Users/username/Developer/mcp/meta-ads-mcp",
      "env": {
        "META_ACCESS_TOKEN": "${META_ACCESS_TOKEN}",
        "META_AD_ACCOUNT_ID": "${META_AD_ACCOUNT_ID}"
      }
    }
  }
}
```

**CRITICAL:** Use variable expansion (`${VAR}`), never hardcode values.

### Step 4: Verify Installation

```bash
# Check Opencode
opencode mcp list

# Test environment variables
echo $META_ACCESS_TOKEN  # Should show value
```

Restart Opencode and test.

## Complete Examples

### Example 1: Stripe MCP Server

**1. Add to `~/.mcp_secrets`:**
```bash
export STRIPE_API_KEY="sk_live_abc123"
```

**2. Install in Opencode:**
```bash
source ~/.mcp_secrets
opencode mcp add
```

**3. Verify Opencode config:**
```json
{
  "mcpServers": {
    "stripe": {
      "command": "/Users/username/.local/bin/uv",
      "args": ["--directory", "/Users/username/Developer/mcp/stripe-mcp", "run", "python", "-m", "src.server"],
      "cwd": "/Users/username/Developer/mcp/stripe-mcp",
      "env": {
        "STRIPE_API_KEY": "${STRIPE_API_KEY}"
      }
    }
  }
}
```

### Example 2: Multi-Profile Server (GoHighLevel)

**1. Add to `~/.mcp_secrets`:**
```bash
export GHL_MAIN_API_TOKEN="pit_main_abc"
export GHL_MAIN_LOCATION_ID="loc_main_123"
export GHL_CLIENT_API_TOKEN="pit_client_xyz"
export GHL_CLIENT_LOCATION_ID="loc_client_456"
```

**2. Install in Opencode:**
```bash
source ~/.mcp_secrets
opencode mcp add
```

**3. Verify Opencode config:**
```json
{
  "mcpServers": {
    "ghl": {
      "command": "/Users/username/.local/bin/uv",
      "args": ["--directory", "/Users/username/Developer/mcp/ghl-mcp", "run", "python", "-m", "src.server"],
      "cwd": "/Users/username/Developer/mcp/ghl-mcp",
      "env": {
        "GHL_MAIN_API_TOKEN": "${GHL_MAIN_API_TOKEN}",
        "GHL_MAIN_LOCATION_ID": "${GHL_MAIN_LOCATION_ID}",
        "GHL_CLIENT_API_TOKEN": "${GHL_CLIENT_API_TOKEN}",
        "GHL_CLIENT_LOCATION_ID": "${GHL_CLIENT_LOCATION_ID}"
      }
    }
  }
}
```

## Credential Management Best Practices

### Use ~/.mcp_secrets

Store all MCP server credentials in `~/.mcp_secrets`:

```bash
# ~/.mcp_secrets
# Meta Ads
export META_MAIN_ACCESS_TOKEN="EAAJxdR0..."
export META_MAIN_AD_ACCOUNT_ID="act_123456789"

# Stripe
export STRIPE_API_KEY="sk_live_..."

# GoHighLevel
export GHL_MAIN_API_TOKEN="pit-..."
export GHL_MAIN_LOCATION_ID="PpE1PIlJ..."

# Zoom
export ZOOM_ACCOUNT_ID="5ZozWfDX..."
export ZOOM_CLIENT_ID="or2VVA9x..."
export ZOOM_CLIENT_SECRET="oRO3NKXX..."
```

Secure it:
```bash
chmod 600 ~/.mcp_secrets
```

Load in shell profile:
```bash
# Add to ~/.zshrc or ~/.bashrc
if [ -f ~/.mcp_secrets ]; then
  source ~/.mcp_secrets
fi
```

### Security Checklist

- [ ] `~/.mcp_secrets` has `chmod 600` permissions
- [ ] All configs use `${VAR}` variable expansion
- [ ] `.env` files are in `.gitignore`
- [ ] Pre-commit hook installed to catch secrets
- [ ] Never commit actual credential values
- [ ] Rotate credentials if accidentally exposed

## Verification

### Check Opencode Installation
```bash
# List all installed servers
opencode mcp list

# Get specific server details
cat ~/.config/opencode/settings.json | jq '.mcp["meta-ads"]'

# Remove if needed
opencode mcp logout meta-ads
```

### Check Opencode Configuration

```bash
# View all servers
cat ~/.config/opencode/settings.json | jq '.mcpServers'

# Check specific server
cat ~/.config/opencode/settings.json | jq '.mcpServers["meta-ads"]'

# Verify cwd property is set
cat ~/.config/opencode/settings.json | jq '.mcpServers["meta-ads"].cwd'

# Verify env uses variable expansion
cat ~/.config/opencode/settings.json | jq '.mcpServers["meta-ads"].env'
```

Ensure configs show `${VAR}` syntax, not actual values.

### Test in Conversation

**Opencode:**
- Open any project
- Ask: "List available MCP servers"
- Ask: "What Meta Ads operations are available?"

**Opencode:**
- Restart the app
- Ask: "List available MCP servers"
- Ask: "What Meta Ads operations are available?"

## Workflow Integration

When creating MCP servers, include installation in your development process:

### Final Installation Steps

1. **Add credentials to `~/.mcp_secrets`**
2. **Install in Opencode** using `opencode mcp add` with actual values
3. **Configure Opencode** with variable expansion (`${VAR}`)
4. **Verify with security checklist**
5. **Test in Opencode**

This ensures secure, consistent installation across all clients.

## Troubleshooting

**"Command not found: opencode"**
- Install Opencode CLI: Open Opencode → run `/install-cli`

**"jq: command not found"**
```bash
brew install jq  # macOS
```

**"Server not appearing in Opencode"**
```bash
# Check installation
opencode mcp list

# Try removing and reinstalling
opencode mcp logout <server-name>
~/.config/opencode/scripts/install-mcp.sh ...
```

**"Server not appearing in Opencode"**
- Verify JSON syntax: `jq '.' ~/.config/opencode/settings.json`
- Check backup file if config is corrupted
- Restart Opencode

**"Environment variable not found"**
- Check `~/.config/opencode/.env` exists
- Verify variable names match exactly
- Ensure no extra spaces: `KEY=value` not `KEY = value`

## TypeScript/Node Servers

### Installation Pattern

**Opencode:**
```bash
opencode mcp add
```

**Opencode:**
```json
{
  "mcpServers": {
    "my-ts-server": {
      "command": "/usr/local/bin/node",
      "args": ["/Users/username/Developer/mcp/my-ts-server/dist/index.js"],
      "cwd": "/Users/username/Developer/mcp/my-ts-server",
      "env": {
        "API_KEY": "${API_KEY}"
      }
    }
  }
}
```

**Note:** TypeScript servers have natural isolation through `node_modules/`.

## Advanced: HTTP/SSE Servers

For remote servers:

```bash
# HTTP server
opencode mcp add

# SSE server with headers
opencode mcp add
```

## Security Best Practices Summary

### Critical Security Rules

1. **Never hardcode credentials** - Always use `${VAR}` variable expansion
2. **Secure credential files** - `chmod 600 ~/.mcp_secrets`
3. **Use `.gitignore`** - Never commit `.env`, `.env.local`, `*.key`, `secrets.json`
4. **Variable expansion everywhere** - Opencode configs must use `${VAR}`
5. **Token rotation** - Update `~/.mcp_secrets`, restart clients
6. **Pre-commit hooks** - Install to catch accidental commits
7. **Always include `cwd`** - Set working directory in all configs
8. **Absolute paths** - Command, args, cwd must all be absolute
9. **User scope for secrets** - Keep credentials out of project configs
10. **Validate before deploy** - Run security checklist

### What Good Looks Like

**✅ Secure Configuration:**
```json
{
  "command": "/Users/username/.local/bin/uv",
  "args": ["--directory", "/Users/username/Developer/mcp/my-server", "run", "python", "-m", "src.server"],
  "cwd": "/Users/username/Developer/mcp/my-server",
  "env": {
    "API_KEY": "${API_KEY}",
    "DB_URL": "${DB_URL:-postgres://localhost/mydb}"
  }
}
```

**❌ Insecure Configuration:**
```json
{
  "command": "uv",
  "args": ["--directory", "./my-server", "run", "python", "-m", "src.server"],
  "env": {
    "API_KEY": "sk_live_abc123"
  }
}
```

Issues: Relative command path, relative directory, hardcoded secret, no `cwd` property.

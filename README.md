# 🛸 Claw-Mission-One: Premium AI VPS

[![Tailscale Ready](https://img.shields.io/badge/Network-Tailscale-blue.svg)](https://tailscale.com/)
[![OpenClaw](https://img.shields.io/badge/Agent-OpenClaw-orange.svg)](https://github.com/openclaw/openclaw)
[![Mission Control](https://img.shields.io/badge/Orchestrator-Mission_Control-purple.svg)](https://github.com/builderz-labs/mission-control)

**Claw-Mission-One** is a fully rebuilt, premium-tier AI orchestration stack for Android Termux. It provides a VPS-like environment inside a Debian 12 PRoot, featuring integrated **OpenClaw Gateway** and **Mission Control**, all accessible over **Tailscale**.

---

## 🚀 One-Command Rebuild

Run this in your Termux Terminal:

```bash
curl -sSL "https://raw.githubusercontent.com/Muxd21/Claw-Mission-One/main/install.sh" | bash
```

---

## ✨ Key Features

- **VPS-Style Architecture**: Runs inside a hardened Debian 12 PRoot with a dedicated `openclaw` operator user.
- **Tailscale First**: Automated port bridging allows you to access your AI dashboards from any device on your tailnet.
- **Integrated Dashboard**: A premium documentation and portal interface to manage your stack.
- **VS Code Remote-SSH**: Optimized for remote development on ports `2222`.
- **Node.js v22 LTS**: Powered by the latest stable Node environment with Bionic networking shims.
- **One-Command Sync**: Keep both applications updated with `vps-sync`.

---

## 📱 Dashboards & Access

Once installed and connected to Tailscale, access your apps at:

- **Mission Control**: `http://<YOUR_PHONE_IP>:3000`
- **OpenClaw UI**: `http://<YOUR_PHONE_IP>:18789`
- **SSH Access**: `ssh -p 2222 root@<YOUR_PHONE_IP>` (Password: `root`)

---

## 🛠 Operator Commands (Inside Debian)

Login with: `proot-distro login debian --user openclaw`

| Command | Description |
|---------|-------------|
| `vps-start` | Start all services (Mission Control + OpenClaw Gateway) |
| `vps-stop` | Stop all running services |
| `vps-restart` | Restart all services |
| `vps-sync` | Force pull and rebuild both apps from source |
| `check-all` | View real-time status of your AI services |
| `logs` | View integrated logs for all apps |

---

## 📦 Acknowledgments

- **OpenClaw Team**: For the advanced AI agent framework.
- **Builderz Labs**: For the Mission Control orchestrator.
- **Termux Community**: For making mobile VPS development possible.

---
*Rebuilt with precision by Antigravity AI for the Claw-Mission community.*

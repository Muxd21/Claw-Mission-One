# 🛸 Claw-Mission-One: Premium AI VPS for Android
[![Tailscale Ready](https://img.shields.io/badge/Network-Tailscale-blue.svg)](https://tailscale.com/)
[![OpenClaw](https://img.shields.io/badge/Agent-OpenClaw-orange.svg)](https://github.com/openclaw/openclaw)
[![Mission Control](https://img.shields.io/badge/Orchestrator-Mission_Control-purple.svg)](https://github.com/builderz-labs/mission-control)

**Claw-Mission-One** is the ultimate, pre-configured AI command center for your Android phone. It turns Termux into a high-performance VPS running **OpenClaw Gateway** and **Mission Control** in a hardened Debian environment.

---

## 🚀 Instant Rebuild
Run this in your Termux Terminal to install or update to the latest premium version:

```bash
curl -sSL "https://raw.githubusercontent.com/Muxd21/Claw-Mission-One/main/install.sh" | bash
```

---

## ⚡ The One-Command Start
After installation, you never have to remember complex commands again. Just type:

```bash
./claw.sh
```

**This single command handles everything:**
- 🌐 **Bridges**: Starts network tunnels for SSH, Mission Control, and the Agent Gateway.
- 🛡️ **SSHD**: Fires up the secure shell daemon for remote PC access.
- 🧠 **AI Services**: Orchestrates Mission Control and OpenClaw via PM2.
- 🐚 **Shell**: Drops you directly into the operator cockpit.

---

## 🔐 Credentials & Access
Access your services via **Tailscale** using your phone's IP address.

### 🖥️ Dashboards
| Service | URL | Credentials |
|---------|-----|-------------|
| **Mission Control** | `http://<PHONE_IP>:3000` | User: `admin` / Pass: `admin` |
| **OpenClaw UI** | `http://<PHONE_IP>:18789` | *Unified Auth via Token* |
| **SSH Access** | `ssh -p 2222 root@<IP>` | User: `root` / Pass: `root` |

> [!TIP]
> Your unique **OpenClaw Gateway Token** is saved at `~/claw-mission-token.txt` on your Termux host.

---

## 🛠️ Operator Commands (Inside Debian)
Inside the `./claw.sh` shell, use these shortcuts:

- `vps-restart`: Restart all AI services
- `vps-stop`: Shut down the stack
- `vps-sync`: Pull latest updates and rebuild
- `logs`: Real-time combined log stream
- `check-all`: View service health and CPU/Memory usage

---

## 📦 Credits & Community
- **OpenClaw**: The powerhouse agent framework.
- **Mission Control**: The elite orchestration dashboard.
- **Muxd21**: Infrastructure design and premium rebuilding.

---
*Powered by Antigravity AI — Rebuilding the future of mobile intelligence.*

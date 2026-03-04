# TailBar

[![Swift](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://swift.org)
[![macOS](https://img.shields.io/badge/macOS-14%2B-blue.svg)](https://www.apple.com/macos/)
[![GitHub stars](https://img.shields.io/github/stars/JungHoonGhae/TailBar)](https://github.com/JungHoonGhae/TailBar/stargazers)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/JungHoonGhae/TailBar/blob/main/LICENSE)
[![CI](https://github.com/JungHoonGhae/TailBar/actions/workflows/ci.yml/badge.svg)](https://github.com/JungHoonGhae/TailBar/actions/workflows/ci.yml)

| [<img alt="GitHub Follow" src="https://img.shields.io/github/followers/JungHoonGhae?style=flat-square&logo=github&labelColor=black&color=24292f" width="156px" />](https://github.com/JungHoonGhae) | Follow [@JungHoonGhae](https://github.com/JungHoonGhae) on GitHub for more projects. |
| :-----| :----- |
| [<img alt="X link" src="https://img.shields.io/badge/Follow-%40lucas_ghae-000000?style=flat-square&logo=x&labelColor=black" width="156px" />](https://x.com/lucas_ghae) | Follow [@lucas_ghae](https://x.com/lucas_ghae) on X for updates. |

A native macOS menu bar app for Tailscale — manage serves, funnels, peers, and exit nodes without leaving your workflow.

```bash
brew tap JungHoonGhae/tailbar
brew install tailbar
```

## Why TailBar?

### The problem: Tailscale on macOS lacks a power-user interface

If you use `tailscale serve` to expose dev servers or manage exit nodes across your tailnet, your options today are:

| Tool | What you have to do |
|------|-------------------|
| **Tailscale macOS app** | Shows connection status. No serve management, no exit node browsing, no traffic stats. You still need the terminal. |
| **CLI (`tailscale`)** | Full-featured, but requires remembering commands, parsing JSON, and constant context switching. |
| **Admin console (web)** | Network-wide config, but overkill for "which port am I serving?" or "switch exit node." |

**The daily friction:**

1. Coding, want to expose port 3000 → switch to terminal → `tailscale serve https / http://localhost:3000` → switch back
2. Check if funnel is on → `tailscale serve status --json` → parse JSON
3. Switch exit node → `tailscale status --json | jq '.Peer[] | select(.ExitNodeOption)'` → pick one → `tailscale set --exit-node=...`
4. "What's my Tailscale IP?" → `tailscale ip` → copy → paste

Every interaction breaks your flow.

### TailBar solves this

One click from your menu bar:

| | Tailscale app | CLI | Admin console | **TailBar** |
|---|:---:|:---:|:---:|:---:|
| View connection status | ✅ | ✅ | ✅ | ✅ |
| Add/remove HTTPS serves | — | ✅ | — | ✅ |
| Toggle funnel per service | — | ✅ | — | ✅ |
| Browse & switch exit nodes | — | ✅ | ✅ | ✅ |
| Suggested exit node | — | — | — | ✅ |
| Peer traffic stats (rx/tx) | — | ✅ | ✅ | ✅ |
| Auto-detect dev ports | — | — | — | ✅ |
| Service health checks | — | — | — | ✅ |
| Key expiry warnings | — | — | ✅ | ✅ |
| Real-time updates | — | — | — | ✅ |
| No terminal needed | ✅ | — | ✅ | ✅ |
| No browser needed | ✅ | ✅ | — | ✅ |

## Features

- 🌐 **Serve Management** — Add, remove, and monitor HTTPS serves from the menu bar
- 🔓 **Funnel Toggle** — Enable/disable public internet access per service with one click
- 💻 **Peer Monitoring** — All nodes in your tailnet with connection type (direct/DERP), traffic stats, and key expiry
- 🌍 **Exit Node Control** — Browse, select, and switch exit nodes with smart suggestions
- 🔍 **Port Detection** — Auto-detect running dev servers (3000, 8080, etc.) and quick-serve them
- 🏥 **Service Health** — Real-time health checks on backend connectivity
- ⚡ **Local API** — Direct communication via Tailscale Local API (CLI fallback included)

## Installation

### Homebrew

```bash
brew tap JungHoonGhae/tailbar
brew install tailbar
```

### From source

```bash
git clone https://github.com/JungHoonGhae/TailBar.git
cd TailBar
swift build -c release
cp .build/release/TailBar /usr/local/bin/
```

## Usage

Run `tailbar` — it lives in your menu bar as a background app (no Dock icon).

**Keyboard shortcuts:**

| Shortcut | Action |
|----------|--------|
| `Cmd+1` ~ `Cmd+4` | Switch tabs (Overview / Peers / Services / Exit Nodes) |
| `Cmd+F` | Focus search |
| `Cmd+R` | Refresh |
| `Esc` | Close popover |

**Settings:**
- Launch at login
- Refresh interval (5s / 10s / 30s / 1m)
- Popover vs. classic menu toggle

## How it connects to Tailscale

TailBar uses the **Tailscale Local API** (preferred) or **CLI** (fallback):

| Method | How it works |
|--------|-------------|
| **Local API** | Reads port from `/Library/Tailscale/ipnport`, auth token from `/Library/Tailscale/sameuserproof-{port}`, then HTTP to `127.0.0.1:{port}` |
| **CLI** | Executes `/Applications/Tailscale.app/Contents/MacOS/Tailscale` with `--json` flags |

The Local API is the same interface the Tailscale desktop app uses internally — no subprocess overhead, instant responses, and real-time streaming via `watch-ipn-bus`.

## Requirements

| Requirement | Version/Notes |
|-------------|---------------|
| macOS | 14.0+ (Sonoma) |
| Tailscale | Installed and running |
| Swift | 5.10+ (for building from source) |

## Development

```bash
swift build           # Build
swift run             # Run
swift test            # Test (20 tests across 2 suites)
swift build -c release  # Release build
```

## Roadmap

- [ ] Multi-profile switching (switch Tailscale accounts)
- [ ] Taildrop file sharing (send files to peers)
- [ ] System notifications (peer changes, key expiry, health alerts)
- [ ] Xcode `.app` bundle (code signing, notarization)
- [ ] MagicDNS name display and copy

## License

MIT

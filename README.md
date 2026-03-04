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

## Why TailBar?

### The problem: Tailscale on macOS lacks a power-user interface

If you run `tailscale serve` to expose dev servers or manage exit nodes across your tailnet, your current options are:

| Tool | What you have to do |
|------|-------------------|
| **Tailscale macOS app** | Shows basic connection status. No serve management, no exit node browsing, no traffic stats. You still need the terminal for anything useful. |
| **CLI (`tailscale`)** | Full-featured, but requires remembering commands, parsing JSON output, and switching between terminal and your editor constantly. |
| **Admin console (web)** | Powerful for network-wide config, but overkill for "which port am I serving?" or "switch my exit node." Requires opening a browser. |

**The daily friction looks like this:**

1. You're coding, want to expose port 3000 → switch to terminal → `tailscale serve https / http://localhost:3000` → switch back
2. Need to check if funnel is on → `tailscale serve status --json` → read JSON → figure it out
3. Want to switch exit node → `tailscale set --exit-node=...` → but which nodes are available? → `tailscale status --json | jq '.Peer[] | select(.ExitNodeOption)'` → pick one → set it
4. Colleague asks "what's my Tailscale IP?" → `tailscale ip` → copy → paste

Every interaction breaks your flow.

### TailBar solves this

**TailBar** puts everything in your menu bar — one click to see, manage, and control your entire Tailscale setup:

| | Tailscale macOS app | CLI | Admin console | **TailBar** |
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
| No terminal needed | ✅ | — | ✅ | ✅ |
| No browser needed | ✅ | ✅ | — | ✅ |
| Real-time updates | — | — | — | ✅ |

Under the hood, TailBar uses the **Tailscale Local API** (the same interface the official apps use internally) for instant response times, with CLI as automatic fallback.

## Features

- 🌐 **Serve Management** — Add, remove, and monitor HTTPS serves from the menu bar
- 🔓 **Funnel Toggle** — Enable/disable public internet access per service with one click
- 💻 **Peer Monitoring** — All nodes in your tailnet with connection type (direct/DERP), traffic stats, and key expiry
- 🌍 **Exit Node Control** — Browse, select, and switch exit nodes with smart suggestions
- 🔍 **Port Detection** — Auto-detect running dev servers (3000, 8080, etc.) and quick-serve them
- 🏥 **Service Health** — Real-time health checks on backend connectivity
- ⚡ **Local API** — Direct communication via Tailscale Local API (CLI fallback included)

## Screenshots

| Popover UI | Classic Menu |
|:----------:|:------------:|
| *Tabbed popover with Overview, Peers, Services, Exit Nodes* | *Traditional NSMenu for lightweight usage* |

## Requirements

| Requirement | Version/Notes |
|-------------|---------------|
| macOS | 14.0+ (Sonoma) |
| Tailscale | Installed and running |
| Swift | 5.10+ (for building from source) |

## Installation

### From source

```bash
git clone https://github.com/JungHoonGhae/TailBar.git
cd TailBar
swift build -c release
cp .build/release/TailBar /usr/local/bin/
TailBar
```

### Homebrew

```bash
brew tap JungHoonGhae/tailbar
brew install tailbar
```

## Usage

Just run `TailBar` — it lives in your menu bar as a background app (no Dock icon).

**Menu bar icon:**
- Connected: network icon with service count badge
- Disconnected: slashed network icon

**Keyboard shortcuts (Popover UI):**

| Shortcut | Action |
|----------|--------|
| `Cmd+1` ~ `Cmd+4` | Switch tabs (Overview / Peers / Services / Exit Nodes) |
| `Cmd+F` | Focus search |
| `Cmd+R` | Refresh |
| `Esc` | Close popover |

**Settings:**
- Refresh interval (5s / 10s / 30s / 1m)
- Popover vs. classic menu toggle
- Local API vs. CLI preference

## How it connects to Tailscale

TailBar uses the **Tailscale Local API** (preferred) or **CLI** (fallback):

| Method | How it works |
|--------|-------------|
| **Local API** | Reads port from `/Library/Tailscale/ipnport`, auth token from `/Library/Tailscale/sameuserproof-{port}`, then HTTP to `127.0.0.1:{port}` |
| **CLI** | Executes `/Applications/Tailscale.app/Contents/MacOS/Tailscale` (or homebrew path) with `--json` flags |

The Local API is the same interface the Tailscale desktop app uses internally — no CLI subprocess overhead, instant responses, and real-time streaming via `watch-ipn-bus`.

## Architecture

```
TailBar/
├── App/              Entry point, AppDelegate
├── Core/             Models, Store, Error types, Connection manager
├── Networking/       Protocol + Local API client + CLI fallback
├── Features/
│   ├── ExitNode/     Exit node management & views
│   ├── Peers/        Peer detail views with traffic stats
│   ├── Profiles/     Multi-account switching
│   └── Taildrop/     File sharing manager
├── UI/
│   ├── Tabs/         Overview, Peers, Services, Exit Nodes tabs
│   ├── PopoverController    NSPopover-based UI
│   └── StatusItemController NSMenu-based fallback UI
├── Services/         Notification manager
└── Persistence/      Alias store (UserDefaults)
```

**Key design decisions:**
- **Protocol-based client** — `TailscaleClientProtocol` enables dependency injection and testing
- **Local API first** — `http://127.0.0.1:{port}` with `Sec-Tailscale` auth, falls back to CLI automatically
- **watch-ipn-bus streaming** — Real-time updates via Tailscale's event bus, polling as fallback
- **Actor-based cache** — Thread-safe response caching with TTL
- **Connection state machine** — `disconnected → connecting → connected → error → reconnecting` with exponential backoff

## Development

```bash
# Build
swift build

# Run
swift run

# Test
swift test

# Build release
swift build -c release
```

### Running tests

```bash
swift test
# 20 tests across 2 suites:
# - Model Decoding (status, serve config, prefs, IPN bus)
# - TailscaleStore (refresh, add/remove serve, funnel, error handling)
```

## CI/CD

GitHub Actions workflow runs on every push/PR to `main`:
- **Build** — `swift build` on macOS 14
- **Test** — `swift test` with all unit tests
- **Release** — Auto-creates GitHub release on version tags (`v*`)

## Roadmap

- [ ] Multi-profile switching (switch Tailscale accounts)
- [ ] Taildrop file sharing (send files to peers)
- [ ] System notifications (peer changes, key expiry, health alerts)
- [ ] Xcode `.app` bundle (code signing, notarization, app icon)
- [ ] Sparkle auto-update framework
- [ ] MagicDNS name display and copy
- [ ] Dark mode semantic colors (Asset Catalog)

## License

MIT

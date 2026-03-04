# TailBar

[![Swift](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://swift.org)
[![macOS](https://img.shields.io/badge/macOS-14%2B-blue.svg)](https://www.apple.com/macos/)
[![GitHub stars](https://img.shields.io/github/stars/JungHoonGhae/TailBar)](https://github.com/JungHoonGhae/TailBar/stargazers)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/JungHoonGhae/TailBar/blob/main/LICENSE)
[![CI](https://github.com/JungHoonGhae/TailBar/actions/workflows/ci.yml/badge.svg)](https://github.com/JungHoonGhae/TailBar/actions/workflows/ci.yml)

| [<img alt="GitHub Follow" src="https://img.shields.io/github/followers/JungHoonGhae?style=flat-square&logo=github&labelColor=black&color=24292f" width="156px" />](https://github.com/JungHoonGhae) | Follow [@JungHoonGhae](https://github.com/JungHoonGhae) on GitHub for more projects. |
| :-----| :----- |
| [<img alt="X link" src="https://img.shields.io/badge/Follow-%40lucas_ghae-000000?style=flat-square&logo=x&labelColor=black" width="156px" />](https://x.com/lucas_ghae) | Follow [@lucas_ghae](https://x.com/lucas_ghae) on X for updates. |

Tailscale management menu bar app for macOS — manage serves, funnels, peers, and exit nodes from your menu bar.

## Features

- **Serve Management** — Add, remove, and monitor Tailscale HTTPS serves directly from the menu bar
- **Funnel Toggle** — Enable/disable public internet access per service with one click
- **Peer Monitoring** — View all nodes in your tailnet with connection type, traffic stats, and key expiry
- **Exit Node Control** — Browse, select, and switch exit nodes with suggested node support
- **Port Detection** — Auto-detect common dev ports (3000, 8080, etc.) and quick-serve them
- **Service Health** — Real-time health checks on backend connectivity
- **Multi-Profile** — Switch between Tailscale accounts/profiles
- **Taildrop** — Send files to peers via Tailscale file sharing
- **System Notifications** — Alerts for peer changes, key expiry, and service health
- **Local API** — Uses Tailscale Local API for fast, direct communication (CLI fallback included)

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

### Homebrew (coming soon)

```bash
brew install --cask JungHoonGhae/tap/tailbar
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
- Notification preferences
- Local API vs. CLI preference

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
- **Protocol-based client** — `TailscaleClientProtocol` enables DI and testing
- **Local API first** — Uses `http://127.0.0.1:{port}` with `Sec-Tailscale` auth, falls back to CLI
- **watch-ipn-bus streaming** — Real-time updates via Tailscale's event bus, polling as fallback
- **Actor-based cache** — Thread-safe response caching with TTL

## How it connects to Tailscale

TailBar uses the **Tailscale Local API** (preferred) or **CLI** (fallback):

| Method | How it works |
|--------|-------------|
| **Local API** | Reads port from `/Library/Tailscale/ipnport`, auth token from `/Library/Tailscale/sameuserproof-{port}`, then HTTP to `127.0.0.1:{port}` |
| **CLI** | Executes `/Applications/Tailscale.app/Contents/MacOS/Tailscale` (or homebrew path) with `--json` flags |

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

- [ ] Xcode `.app` bundle (code signing, notarization, app icon)
- [ ] Sparkle auto-update framework
- [ ] Homebrew Cask distribution
- [ ] MagicDNS name display and copy
- [ ] Dark mode semantic colors (Asset Catalog)

## License

MIT

<p align="center">
  <h1 align="center">TailBar</h1>
  <p align="center">
    Your Tailscale. Always one click away.
  </p>
  <p align="center">
    <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.10-orange.svg" /></a>
    <a href="https://www.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-14%2B-blue.svg" /></a>
    <a href="https://github.com/JungHoonGhae/TailBar/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" /></a>
    <a href="https://github.com/JungHoonGhae/TailBar/actions/workflows/ci.yml"><img src="https://github.com/JungHoonGhae/TailBar/actions/workflows/ci.yml/badge.svg" /></a>
  </p>
</p>

<br />

> **TailBar** is a native macOS menu bar app that brings your entire Tailscale workflow — serves, funnels, peers, exit nodes — into a single, always-accessible popover. No terminal. No browser. Just click.

<br />

## Install

```bash
brew tap JungHoonGhae/tailbar && brew install tailbar
```

<details>
<summary>Build from source</summary>

```bash
git clone https://github.com/JungHoonGhae/TailBar.git
cd TailBar && swift build -c release
cp .build/release/TailBar /usr/local/bin/
```

Requires Swift 5.10+ and macOS 14 (Sonoma).
</details>

<br />

## The Problem

Managing Tailscale on macOS means constant context switching.

```
You're coding
  → switch to terminal
    → tailscale serve https / http://localhost:3000
      → switch back

Need to check funnel?
  → tailscale serve status --json
    → parse JSON output

Switch exit node?
  → tailscale status --json | jq '.Peer[] | select(.ExitNodeOption)'
    → pick one
      → tailscale set --exit-node=...
```

The official macOS app shows connection status — and that's about it. The CLI is powerful but breaks your flow. The admin console requires a browser.

**TailBar puts it all in your menu bar.**

<br />

## What You Get

<table>
<tr>
<td width="50%">

### Serves

Add, remove, and monitor HTTPS serves.
Toggle funnel per service with one click.
Auto-detect running dev ports and quick-serve them.

</td>
<td width="50%">

### Peers

Every node in your tailnet at a glance.
Connection type, traffic stats, key expiry.
Direct vs. DERP relay — instantly visible.

</td>
</tr>
<tr>
<td width="50%">

### Exit Nodes

Browse all available exit nodes.
Smart suggestions based on location.
Switch with a single click.

</td>
<td width="50%">

### Health

Real-time service health checks.
Key expiry warnings before they bite.
Live updates via Tailscale event stream.

</td>
</tr>
</table>

<br />

## How It Works

TailBar uses the **Tailscale Local API** — the same interface the official desktop app uses internally.

| | Local API | CLI Fallback |
|---|---|---|
| **Speed** | Direct HTTP to `127.0.0.1` | Subprocess per command |
| **Updates** | Real-time via `watch-ipn-bus` | Polling |
| **Auth** | `Sec-Tailscale` token | N/A |

Falls back to CLI automatically if the Local API is unavailable.

<br />

## Keyboard Shortcuts

| | |
|---|---|
| `Cmd 1` — `Cmd 4` | Switch tabs |
| `Cmd F` | Search |
| `Cmd R` | Refresh |
| `Esc` | Close |

<br />

## Comparison

|  | Tailscale App | CLI | Admin Console | TailBar |
|---|:---:|:---:|:---:|:---:|
| Manage serves | — | ✅ | — | ✅ |
| Toggle funnels | — | ✅ | — | ✅ |
| Exit node switching | — | ✅ | ✅ | ✅ |
| Suggested exit node | — | — | — | ✅ |
| Peer traffic stats | — | ✅ | ✅ | ✅ |
| Auto-detect ports | — | — | — | ✅ |
| Health checks | — | — | — | ✅ |
| Real-time updates | — | — | — | ✅ |
| No terminal | ✅ | — | ✅ | ✅ |
| No browser | ✅ | ✅ | — | ✅ |

<br />

## Roadmap

- Multi-profile switching
- Taildrop file sharing
- System notifications
- Signed `.app` bundle
- MagicDNS integration

<br />

## Development

```bash
swift build          # build
swift test           # 20 tests, 2 suites
swift run            # run
```

<br />

---

<p align="center">
  <sub>MIT License</sub>
  <br />
  <sub>Requires macOS 14+ and Tailscale.</sub>
</p>

<p align="center">
  <a href="https://github.com/JungHoonGhae"><img alt="GitHub" src="https://img.shields.io/github/followers/JungHoonGhae?style=flat-square&logo=github&labelColor=black&color=24292f" /></a>
  &nbsp;
  <a href="https://x.com/lucas_ghae"><img alt="X" src="https://img.shields.io/badge/Follow-%40lucas_ghae-000000?style=flat-square&logo=x&labelColor=black" /></a>
</p>

# Local Development Setup for lumo.proton.dev

## Prerequisites

- macOS with Xcode
- Access to `proton/web/clients` repository with local-sso configured and running

## Setup Steps (One-time per machine)

### 1. Install mkcert and generate CA certificate

```bash
brew install mkcert
mkcert -install
```

This creates a root CA at `/Users/<username>/Library/Application Support/mkcert/rootCA.pem`

### 2. Install certificate in iOS Simulator

```bash
xcrun simctl keychain booted add-root-cert "/Users/$(whoami)/Library/Application Support/mkcert/rootCA.pem"
```

**Note:** Re-run this command after creating/resetting a simulator.

### 3. Build and run

In Xcode:
1. Select **LumoApp-Local** scheme
2. Clean Build (Cmd+Shift+K)
3. Run on Simulator (Cmd+R)

## How It Works

1. iOS app connects to `https://lumo.proton.dev`
2. `/etc/hosts` resolves to `127.0.0.1` (configured in `proton/web/clients`)
3. HAProxy (port 443) proxies requests:
   - Frontend → local webpack dev server
   - API → production backend (`lumo.proton.black`)
4. mkcert certificate is trusted by iOS Simulator

## Configuration

- `Xcconfigs/Debug-Local.xcconfig`: URLs set to `https://lumo.proton.dev`
- `limitsNavigationsToAppBoundDomains = false` in dev mode for flexibility
- Production scheme (**LumoApp**) unchanged

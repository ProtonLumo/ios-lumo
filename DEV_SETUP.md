# Local Development Setup for lumo.proton.dev

## Prerequisites

- macOS with Xcode
- Access to `proton/web/clients` repository with local-sso configured and running

## Setup Steps (One-time per machine)

### 1. Install mkcert

```bash
brew install mkcert
```

### 2. Start the web server (automatically generates certificates)

When you run `yarn start-all` for the first time, it automatically generates SSL certificates if they don't exist:

```bash
cd ~/dev/proton/web/clients
yarn start-all --applications "proton-lumo" --api proton.black --no-error-logs
```

This will:
- Generate SSL certificates for `*.proton.dev` (saved in `utilities/local-sso/`)
- Install mkcert root CA in macOS system keychain
- Configure `/etc/hosts` for local development domains
- Start HAProxy and the development server

The root CA is created at `/Users/<username>/Library/Application Support/mkcert/rootCA.pem`

**Note:** Certificates are generated only once. Subsequent runs of `yarn start-all` will reuse existing certificates.

### 3. Install root CA in iOS Simulator

```bash
xcrun simctl keychain booted add-root-cert "/Users/$(whoami)/Library/Application Support/mkcert/rootCA.pem"
```

**Note:**
- Re-run this command after creating/resetting a simulator
- If you regenerate the root CA (with `mkcert -install` or `./generate-certificate.sh`), you must reset the simulator keychain and add the new certificate:
  ```bash
  xcrun simctl keychain booted reset
  xcrun simctl keychain booted add-root-cert "/Users/$(whoami)/Library/Application Support/mkcert/rootCA.pem"
  ```

### 4. Build and run

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
4. HAProxy serves the SSL certificate for `*.proton.dev` (signed by mkcert root CA)
5. iOS Simulator trusts the certificate because the root CA is installed in its keychain

## Configuration

- `Xcconfigs/Debug-Local.xcconfig`: URLs set to `https://lumo.proton.dev`
- `limitsNavigationsToAppBoundDomains = false` in dev mode for flexibility
- Production scheme (**LumoApp**) unchanged

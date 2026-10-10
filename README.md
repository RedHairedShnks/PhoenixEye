<div align="center">

<img width="968" height="406" alt="image" src="https://github.com/user-attachments/assets/0552c7a8-4b95-4fdc-9a25-ff5343eb97ef" />


# PhoenixEye

**Intel gathering and GPS coordinate capture.**

Cloudflared ·  · Capturing-live

[![Bash](https://img.shields.io/badge/bash-5.0%2B-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![PHP](https://img.shields.io/badge/php-7.4%2B-777BB4?style=flat-square&logo=php&logoColor=white)](https://www.php.net/)
[![Platform](https://img.shields.io/badge/platform-linux%20%7C%20macos%20%7C%20wsl-00D4FF?style=flat-square)](https://www.kernel.org/)
[![License](https://img.shields.io/badge/license-MIT-7B2FF7?style=flat-square)](LICENSE)

</div>

---

## Overview

PhoenixEye is Simple, single-machine diagnostics utility. It serves a browser page that requests permission-based device information and GPS coordinates, then forwards the collected data to a local PHP endpoint that writes reports to a file. The launcher tails that file live in the terminal where you started the tool.

Built for **authorized lab testing**, red-team education, and personal device audits. The tool does not tunnel externally by default, does not silently collect without consent, and does not persist data beyond what the operator explicitly retains.


## Features

| Module | Description |
|---|---|
| **Animated launcher** | Colored Phoenix-eye banner, spinner, clean menu. |
| **Cloudflared tunnel** | Optional public link via `trycloudflare.com`. |
| **Loopback mode** | Serve strictly on `127.0.0.1:8080`. |
| **Device info** | User agent, platform, cores, RAM, screen, language, cookies, browser name, local time, referrer, OS CPU. |
| **GPS capture** | Browser `Geolocation API`, coordinates, accuracy, map link, Google Earth link. |
| **Permission-aware** | Explicit grant required. Denied, timeout, and unavailable states are logged. |
| **Live terminal output** | Report streams to the terminal as soon as it arrives. |
| **Session log** | Append-only `phoenix_data.txt`, plus `phoenix_ip.txt` and `phoenix_saved_ip.txt`. |

---

---

## Requirements

- **bash** 4.0+ (5.0+ recommended for `$'...'` ANSI strings)
- **php** 7.4+ with the CLI SAPI
- **wget** (only if the tunnel option is used)
- **lsof** (optional, used to detect port conflicts)
- A POSIX-compatible terminal with 256-color support
- A modern browser on the target device with the Geolocation API

Supported hosts: Linux (all distros), macOS, WSL, Termux.

---

## Installation

```bash
git clone https://github.com/ShnksPHX/PhoenixEye.git
cd PhoenixEye
chmod +x phoenixeye.sh
```

No global install. No Python. No Node. Everything runs from the project directory.

---

## Usage

```bash
bash phoenixeye.sh
```

You will see:

<img width="440" height="302" alt="image" src="https://github.com/user-attachments/assets/2b5f6994-b739-4b06-b0ed-ed84ffcf4119" />


**Option 1 — Public link via Cloudflare:**

Downloads `cloudflared` if missing, starts a PHP server on `127.0.0.1:3333`, opens a tunnel, extracts the `trycloudflare.com` URL, and prints:

```
  Link - https://random-words.trycloudflare.com

  waiting for capturing information..
```

**Option 2 — Loopback only:**

Starts a PHP server on `127.0.0.1:8080` and prints:

```
  Link - http://127.0.0.1:8080

  waiting for capturing information..
```

On any hit, the terminal prints `target connected` and streams the report live. Press `Ctrl+C` to stop — the launcher kills `php` and `cloudflared` and restores terminal state.

---

## Terminal Output

```
  ● target connected
  ── live report ──
Hound - Information Gathering Report
------------------------------------

Device Information
------------------------------------
User Agent: Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0
Platform: Linux x86_64
Cookies Enabled: true
Browser Language: en-US
Browser Name: Netscape
Browser CodeName: Mozilla
RAM: undefined
CPU Cores: 12
Screen Width: 1920
Screen Height: 1080
Local Time: 8:33:32 AM
RefUrl:
OS CPU: Linux x86_64
------------------------------------

GPS Lat Long Information
-----------------------
Latitude: 14.5764
Longitude: 121.039
Map Location:  https://www.google.com/maps/place/14.5764,121.039
Google Earth:  https://earth.google.com/web/search/14.5764,121.039
-----------------------
```

All reports are appended to `phoenix_data.txt` in the project directory.

---

---

## Project Layout

```
PhoenixEye/
├── phoenixeye.sh       # launcher + animated UI
├── template.php        # redirect wrapper
├── index.php           # generated from template.php
├── index_chat.html     # page shell (payload injected at runtime)
├── index.html          # generated: index_chat.html + payload
├── payload             # device + GPS capture script
├── ip.php              # server-side IP writer
├── webhook.php         # report appender
├── script.js           # chat UI controller
├── style.css           # chat UI styling
├── phoenix_data.txt    # report log (append-only)
├── phoenix_ip.txt      # IP log (rotated per hit)
├── phoenix_saved_ip.txt# archived IP log
├── README.md
└── LICENSE
```

---

---

## Security Notes

- **Consent first.** The browser Geolocation API always prompts the target; the payload does not bypass this. A target that denies the prompt produces a `User denied the Geolocation permission.` log entry instead of coordinates.
- **Loopback default.** Option 2 binds to `127.0.0.1` only. The page is not reachable from the LAN or the internet.
- **No credential storage.** The tool stores no passwords, tokens, or cookies.
- **No persistence of location beyond the log file.** Delete `phoenix_data.txt` to wipe coordinates.
- **Tunnel exposure.** If you choose Option 1, the `trycloudflare.com` URL is public. Treat it as such — anyone with the link can reach the served page for as long as the tunnel is running.
- **Authorized use only.** Running this tool against devices or networks you do not own or have written permission to test may violate computer-fraud laws in your jurisdiction. The author of this repository does not condone or support unauthorized use.
- **No data leaves the host unless Cloudflared is used (which only relays the HTTP traffic between the target's browser and the local PHP server). No analytics, no telemetry, no third-party beacons beyond the Google Maps / Google Earth links embedded in the report itself (which the operator views manually, not the target).

---


---

## FAQ

**Q: Does this bypass the browser permission prompt?**
No. The Geolocation API always requires explicit user permission. PhoenixEye only reads what the browser is willing to expose.

**Q: Can I use this without Cloudflare?**
Yes. Option 2 uses only `php -S 127.0.0.1:8080` and never touches the internet.

**Q: Where is the data stored?**
In the project directory: `phoenix_data.txt`, `phoenix_ip.txt`, `phoenix_saved_ip.txt`.

**Q: Does it work on Android / Termux?**
Yes. The launcher detects `arm`/`aarch64` and downloads the matching Cloudflared binary.

**Q: Can I rename the report files?**
Yes — edit the paths inside `phoenixeye.sh`, `ip.php`, and `webhook.php`.

**Q: Why does `RAM` sometimes show `undefined`?**
`navigator.deviceMemory` is only implemented in Chromium browsers. Firefox and Safari return `undefined`, which the payload writes literally.

---

## License

Released under the MIT License. See [`LICENSE`](LICENSE) for the full text.

---

## Contributors

- Tracy "Shnks" G. A

---

<div align="center">

**PhoenixEye** — 

```
authorized access · consent-based ·
```

</div>

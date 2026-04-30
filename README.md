# Rokid Compass HUD

Streams a live compass heading to Rokid AR glasses in real time — always visible in the corner.

```
iPhone (magnetometer) ──TCP :8100──▶ Rokid Glasses
```

## What the glasses see

Three display formats to choose from:

| Format | Example |
|--------|---------|
| **Full** | `↑ N  007°` |
| **Compact** | `↑ N` |
| **Minimal** | `N` |

The glasses receive a new JSON packet every time your heading changes by the configured threshold (default: 1°).

## TCP wire protocol (port 8100)

```json
{"type":"compass", "text":"↑ N  007°"}
{"type":"compass", "text":"↗ NE  047°"}
{"type":"compass", "text":"→ E  091°"}
{"type":"status",  "text":"Rokid Compass connected — heading data streaming on TCP :8100"}
```

## Setup

1. Open `RokidCompass.xcodeproj` in Xcode 15+
2. Set your team in Signing & Capabilities
3. Build and run on iPhone (iOS 17+)
4. Grant **location** permission when prompted (needed for true-north heading)
5. Connect Rokid glasses to the same Wi-Fi; point TCP client at `<phone-ip>:8100`
6. The heading starts streaming immediately — appears on glasses in real time

## Settings

| Setting | Default | Description |
|---------|---------|-------------|
| Format | Full | `↑ N  007°` / `↑ N` / `N` |
| Update threshold | 1° | Only broadcasts when heading changes by this many degrees |
| Broadcast | On | Pause/resume streaming to glasses |

## Calibration

If the reading seems off, wave the phone in a figure-8 motion a few times — iOS will show a calibration screen automatically.

Uses `CLLocationManager.startUpdatingHeading()` with **true north** (requires location permission for magnetic declination correction). Falls back to magnetic north if location is unavailable.

## Cardinal directions

16-point compass rose: N · NNE · NE · ENE · E · ESE · SE · SSE · S · SSW · SW · WSW · W · WNW · NW · NNW

## Requirements

- iOS 17.0+
- Xcode 15+
- iPhone with magnetometer (all modern iPhones)
- Location permission (for true-north correction)
- Rokid AR glasses on the same Wi-Fi

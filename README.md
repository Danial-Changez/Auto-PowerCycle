<h1> Auto-PowerCycle </h1>

PowerShell script that watches Windows event logs and power-cycles a monitor when both power-related events occur (Kernel-Power 105 and DellTechHub "PowerEvent handled successfully"). Uses NirSoft's `ControlMyMonitor.exe` to send the VCP power command to the selected display.

<h2> Table of Contents </h2>

- [Requirements](#requirements)
- [How it works](#how-it-works)
- [Usage](#usage)
- [Customization](#customization)

## Requirements
- `ControlMyMonitor.exe` placed alongside `autoCycle.ps1` (already included here).
- Execution policy that allows running local scripts (e.g., launch PowerShell with `-ExecutionPolicy Bypass` if needed).

## How it works
- Subscribes to the System and Application event logs.
- When a Kernel-Power 105 entry and a DellTechHub "PowerEvent handled successfully" entry both appear within the event window, the script toggles the monitor power off then on via VCP code `D6` (power mode), sending `4` (off) then `1` (on).
- By default, it assumes Mountain Standard Time for the timezone check; pass `-mst $true` to require your actual timezone to be Mountain Standard Time instead of forcing it.
- Runs indefinitely so the event subscriptions stay active.

## Usage
```pwsh
# Run from the script directory
.\autoCycle.ps1            # default settings
.\autoCycle.ps1 -mst $true # only updates machines located in Mountain Standard Time
```

## Customization
- Monitor target: change `$monitor` (default `"Secondary"`). Use `ControlMyMonitor.exe /scomma` to list monitor names if needed.
- VCP codes: `$vcpCode`, `$offCode`, `$onCode` control the command sent to the monitor.

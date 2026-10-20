# Running Dahua SmartPSS Lite on Linux (Wine)

**English** | [Türkçe](README.tr.md)

Install scripts and documentation to run **Dahua SmartPSS Lite** (V1.006.0000000.1, 64-bit; Dahua's free Windows video-management client)
on Linux with Wine, in a private Wine prefix. This is **not** an official Linux version, it is not affiliated with Dahua, and there is no warranty.

> **This repository does NOT contain Dahua SmartPSS Lite or the Microsoft VC++ runtime.** It only contains scripts and documentation.
> You download SmartPSS Lite yourself from **dahuasecurity.com** (see below). **Do not use the Dahua Wiki build, it is outdated.**

## Status

| | |
|---|---|
| Tested systems | Debian 13 (XFCE/Xorg), Pardus 25 (GNOME/Wayland), Devuan 6 (GNOME/Wayland); at least 3 different computers. All with WineHQ stable (Devuan 6 via the WineHQ Debian 13/trixie repository) |
| Wine | WineHQ stable 11.0 |
| Verified working | First-run setup (admin account), adding devices (IP and serial number/P2P), the device's web interface, live view |
| Not tested | Playback of recordings, long-term use, many cameras, the distribution's own Wine package (Debian 13 ships Wine 10) |
| Performance | In the author's own testing the application runs **much faster on Linux than on Windows** |
| Known issue | Live view can still be slow with many streams or over VNC/remote desktop. There is no hardware video decoding under Wine |

## Requirements

- 64-bit (x86_64) Linux. A ready-made Wine install script exists for Debian/Ubuntu based distributions
- Wine 11 (WineHQ stable; at least Wine 9), `7z` (p7zip-full / 7zip), `unzip`, `curl` or `wget`
- At least 3 GB free disk space (about 2.3 GB after installation, less after `cleanup.sh`)
- A Linux filesystem such as ext4 (do not run the Wine prefix on NTFS/exFAT)

## Installation

### 1. Get this repository

```bash
git clone https://github.com/EmreYavuzalp/smartpss-lite-linux.git
cd smartpss-lite-linux
```

### 2. Download SmartPSS Lite

Download SmartPSS Lite only from **[dahuasecurity.com](https://www.dahuasecurity.com)** (Dahua's official site, download section):
search for "SmartPSS Lite", get the Windows 64-bit package and put it into this folder.
**Do not download or use the Dahua Wiki version:** the SmartPSS Lite build offered there is outdated and has not been tested with these scripts.

Tested file:

```
General_SmartPSSLite_MultiLang_Win64-Install_IS_V1.006.0000000.1.R.260305.zip
SHA-256: b7c716eefadf2993a84f28adec56e6f29f7a2dbb855e16caee697ccfc2014130
```

Verify with `sha256sum General_SmartPSSLite_*.zip`. Other versions are untested and may not work.
If the zip is somewhere else: `SMARTPSS_ZIP=/path/to/file.zip ./setup.sh`.

### 3. Install Wine (if not installed)

On Debian/Ubuntu based systems (needs `sudo` and internet):

```bash
./wine-install.sh
```

By default it adds the official **WineHQ** repository and installs `winehq-stable`
(`sudo apt install --install-recommends winehq-stable`), plus `7z` and `unzip`. This is the tested setup.

- On Debian-family systems (Debian, Devuan, Pardus ...) the distribution's own Wine package
  (`wine wine64 libwine fonts-wine`) is used as a fallback if WineHQ does not work. It has not been tested with SmartPSS Lite.
- To force a source: `WINE_SOURCE=winehq ./wine-install.sh` or `WINE_SOURCE=distro ./wine-install.sh`.

On other distributions install Wine following the [WineHQ instructions](https://gitlab.winehq.org/wine/wine/-/wikis/Download).
Check with `wine --version` (Wine 9 or newer is required, 11 recommended).

### 4. Install

```bash
./setup.sh
```

Takes a few minutes. The script:

1. Checks requirements (architecture, Wine version, `7z`, disk space)
2. Creates a private Wine prefix in this folder (`./prefix`). It does not touch `~/.wine`
3. Unpacks the NSIS installer inside Dahua's zip with `7z` and copies the application into the prefix (the installer wizard is not run)
4. Installs the Microsoft VC++ runtime (v14) and adds `native,builtin` DLL overrides for `msvcp140`, `vcruntime140`, etc.
   (downloads `vc_redist.x64.exe` from Microsoft if it is not in the folder)
5. Applies a Wine setting (`GlobalFlag`, see below) and pre-creates the user directories
6. Adds a "SmartPSS Lite" shortcut to the application menu and the desktop

### 5. Start

Use "SmartPSS Lite" in the application menu, or:

```bash
./run.sh
```

On first start you are asked to create an administrator (admin) account and a security question.

> **Do not move or delete** the `smartpss-lite-linux` folder after installation: the program and your data live in `prefix/`.
> To move it, run `./uninstall.sh` first and `./setup.sh` in the new place (your data is deleted).

## Stopping the program

Closing the window is normally enough. If processes stay behind (`SmartPSSLiteDaemon.exe` runs in the background):

```bash
WINEPREFIX="$PWD/prefix" wineserver -k
```

This stops every Wine process in that prefix (including an open session). Check with `pgrep -af SmartPSS`.

## Disk space

```bash
./cleanup.sh
```

Asks before every step. It can delete crash dumps (`.dmp`, can be many GB after crashes), temporary files, logs,
Wine Mono (not needed) and the installer files. It never touches account and device data.

The installed prefix is about 2.3 GB. Most of the rest is Wine's own system files and cannot be removed.

## Uninstall

```bash
./uninstall.sh
```

Deletes the prefix (including accounts, devices, recordings, screenshots) and the shortcuts. Asks for confirmation.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Does not start / hangs | `WINEPREFIX="$PWD/prefix" wineserver -k`, then `./run.sh` |
| Black screen after login, window keeps closing and reopening | Make sure `setup.sh` finished completely (step 4 prevents this, see below). In an old prefix add the setting by hand |
| Login screen instead of account creation on first start | The app data was set up badly. Run `./uninstall.sh` and `./setup.sh` (this is why the user directories are created beforehand) |
| Live view is slow | If you use VNC/remote desktop, try on a local screen; use the sub stream and fewer windows |
| Disk is filling up | `./cleanup.sh` |
| Logs (for support/inspection) | `prefix/drive_c/users/Public/SmartPSSLite/Log/client_log/` |

The scripts print messages in English, or in Turkish when the system language is Turkish.

## Technical notes (what was done and why)

The application is a closed-source 64-bit Windows program written with Qt5, and it depends on Dahua's closed-source Windows DLLs
(`dhnetsdk.dll`, `play.dll`, ...). A native Linux build is therefore not possible; Wine is the solution.
The detailed discovery log is in [`docs/NOTES.md`](docs/NOTES.md) (Turkish, raw working notes). In short, the problems and fixes:

1. **Account creation was skipped on first start.** Under Wine the app cannot create nested directories below
   `C:\Users\Public\SmartPSSLite\...` itself; when the databases could not be created it misread "no users" and went straight to login.
   Fix: the required directories are created beforehand by `setup.sh` and `run.sh`.
2. **Black screen after login and a crash loop.** While loading skin PNGs, an access violation occurs in Wine's ntdll heap (`RtlFreeHeap`
   called from inside Qt5Gui); the app catches it in its own crash handler and its daemon restarts it. Two settings fixed it:
   - Installing the official Microsoft VC++ runtime (native `msvcp140`/`vcruntime140`) and overriding the DLLs.
   - `HKLM\System\CurrentControlSet\Control\Session Manager\GlobalFlag = 0x4070` (heap debug flags, believed to disable Wine's low-fragmentation
     heap). **Do not remove it.** The root cause is not proven; this is a workaround.

## Legal

- SmartPSS Lite is a product of Dahua Technology; this repository is not affiliated with Dahua and does not distribute its files.
- The Microsoft Visual C++ Redistributable belongs to Microsoft; the script downloads it from Microsoft's official address.
- The scripts and documentation in this repository are MIT licensed (see `LICENSE`).
- Use your cameras/recorders only on networks you are authorized to use.

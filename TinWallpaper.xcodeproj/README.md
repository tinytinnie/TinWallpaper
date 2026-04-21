# TinWallpaper

TinWallpaper is a macOS app for setting video wallpapers and a matching screensaver video source.

## Features

- Apply a video as a live desktop wallpaper.
- Set a separate video source for the screensaver.
- Keep live wallpaper and screensaver configured at the same time.
- Recent video list for quick re-selection.

## Requirements

For end users:

- macOS (Apple Silicon or Intel)

For developers/building from source:

- Xcode 15+

## Project Structure

- `TinWallpaper/` main app target
- `TinWallpaperScreensaver/` screensaver bridge target
- `Screensaver/` legacy screensaver files

## Build and Run

1. Open the project/workspace in Xcode.
2. Select the `TinWallpaper` scheme.
3. Build and run (`Cmd+R`).
4. Grant any macOS permissions if prompted.

## Use Without Xcode

Recommended release flow:

1. Build a Release version of `TinWallpaper.app`.
2. Zip the app (`TinWallpaper.app.zip`).
3. Upload it to GitHub Releases.
4. Users download, unzip, move `TinWallpaper.app` to `Applications`, and run it.

If Gatekeeper blocks launch on an unsigned build, users can right-click the app and choose `Open` once.

For best user experience, sign and notarize release builds with an Apple Developer ID.

## How to Use

1. Launch the app.
2. Choose a mode in the segmented control:
   - `Live Wallpaper`
   - `Screensaver`
3. Click `Choose Video` and pick a local video file.
4. Use the action buttons:
   - `Apply as Live Wallpaper` to apply current video to desktop wallpaper.
   - `Set as Screensaver Source` to set current video for screensaver playback.

Notes:

- The selected mode applies to the next chosen video.
- Recent Videos shows your original file names for easier navigation.
- Internally, the app copies media into `/Users/Shared/TinWallpaper` for stable playback/sharing.

## Recommended Video Format

For smoother playback:

- H.264 (`.mp4`)
- 1080p or 1440p
- 30 FPS or 60 FPS
- Moderate bitrate (very high bitrate 4K files may stutter on some systems)

## Troubleshooting

### Live wallpaper is choppy

- Try a lower resolution or lower bitrate source.
- Prefer H.264 MP4 files.
- Close GPU-heavy apps.

### Screensaver shows wrong/old video

- In the app, set mode to `Screensaver`.
- Choose the desired file again.
- Click `Set as Screensaver Source`.

### Nothing updates

- Re-run from Xcode and watch logs.
- Verify `/Users/Shared/TinWallpaper` exists and is writable.

## Logging

Debug logging for wallpaper manager/screen manager is available in code and currently disabled by default.

- `WallpaperManager.debugLoggingEnabled`
- `MultiScreenManager.debugLoggingEnabled`

Set to `true` when diagnosing playback/apply issues.

## Contributing

1. Fork the repo
2. Create a feature branch
3. Make changes
4. Open a pull request

## License

MIT License

Copyright (c) 2026 TinyTinnie

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

This Rice is for CachyOS + Hyprland + Quickshell. It is no longer maintained, if I am bored I might take screen shots in the future.

WARNING + Transparency: I was new to Quickshell so I did use Claude to assist with writing the code. Use at your own risk. Personal experience, no problems on 2 different systems.

Even though I was having fun building this, I stopped because even though I have more than enough RAM to not care, I was not happy with 400mb+ of RAM just to run it. So, it's cool, but I value resource efficiency.

It is inspired by the Deus Ex games.

Visually it resembles a HUD by having plenty of visual information on the bottom layer just above the wallpaper. The bottom layer itself was the taskbar. Instead of a normal 'bar', I used the entire screen as a 'bar' on the bottom layer. All active windows are displayed on top of the UI.

Visual information:
- CPU + Cores usage/stress (inaccurate readings, if your CPU stress is 8% it might sshow stress at 14-18% on the status bar)
- Network Up and Down
- Battery level and power drain (pulses red if battery is 5% or lower. pulses constantly if on desktop)
- GPU usage/stress (shows all gpu's on machine. Accurrate readings. Status bar(s) show how much each gpu is processing. actual vram usage is below status bar in small text)
- Storage manager (shows all drives/partitions. able to mount/unmount partitions. able to open partitions via button that opens a terminal to them)
- Clock
- Custom display manager (very rough/janky, technically it works, most of the time. It's able to visually position multiple monitors, auto scale resolution to the preferred monitors resolution. Doesn't always work)

Visual layout:

- Upper left corner: CPU Monitor
- Upper middle center: Display Manager
- Bottom left corner: Network, battery is positioned above it.
- Upper right corner: Clock
- Bottom right corner: GPU(s), Storage module is positioned above it

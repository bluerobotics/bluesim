# BlueSim

BlueROV2 Heavy simulator for Godot 4.7.2. The [hosted BlueSim demo](https://blueos.cloud/bluesim/) runs with BlueOS and the Cockpit control station.

## Run from source

Install [Godot 4.7.2 standard](https://godotengine.org/download/archive/4.7.2-stable/), open `project.godot`, wait for the asset import, and press F5. Select **Pool** for keyboard play. The project uses the Compatibility renderer on desktop and Web.

To build the distribution archives locally, install the matching export templates in the Godot editor and run the following from the project root. Pass the path to the Godot executable as the first argument if it is outside your PATH.

```sh
godot --headless --editor --import
bash .github/export.sh godot /tmp/bluesim-exports
```

The [Godot exports workflow](https://github.com/bluerobotics/bluesim/actions) attaches `bluesim-windows.zip`, `bluesim-linux.zip`, `bluesim-mac.zip`, and `bluesim-web.zip` to successful builds. Extract the desktop archive before launching. On Windows and Linux, run from the extracted directory so ArduSub can use its bundled `eeprom.bin`. The macOS archive contains a universal app with ad hoc signing for testing. For Web, serve the extracted files over HTTP and open `index.html`.

## Controls

| Action | Key |
| --- | --- |
| Rise / dive | Space / Shift |
| Forward / reverse | Up / Down |
| Yaw left / right | Left / Right |
| Strafe left / right | A / D |
| Lights down / up | 1 / 2 |
| Open / close gripper | 3 / 4 |
| Tilt camera down / up | 5 / 6 |
| Switch camera | C |
| Reset position | R |
| Help / graphics settings | H / Esc |

## ArduSub SITL

On Windows and x86-64 Linux, BlueSim downloads and starts ArduSub when the menu opens. On macOS, start SITL separately. From an ArduPilot checkout with its SITL dependencies installed, run:

```sh
Tools/autotest/sim_vehicle.py -L RATBeach -v ArduSub -f vectored_6dof --model JSON:127.0.0.1
```

Select **Pool** and connect [QGroundControl](https://qgroundcontrol.com/) to SITL over TCP at `127.0.0.1:5760`. For an external simulator running on a different host, set the JSON backend address to the BlueSim host and point QGroundControl at the SITL host. BlueSim listens for servo packets on UDP port 9002 and replies to the sender. Enable **Reply to SITL on incoming frames** before selecting the pool to send state only in response to incoming servo packets. Keyboard movement is available before a peer connects and resumes when the peer times out. The Web build supports keyboard play.

## External levels

Export a Godot 4 resource pack containing `res://custom_level.tscn` with a `Node3D` root. Use a Godot 4.7.2 project when rebuilding packs made for Godot 3. Place the `.pck` in the `levels` directory next to the Windows or Linux executable, or in `user://levels` for macOS and source runs. On macOS that is `~/Library/Application Support/Godot/app_userdata/BlueSim/levels`. Restart BlueSim and select the pack by filename. Use packs from sources you trust, since packs can contain scripts.

The [original Sunken Ship sample](https://drive.google.com/file/d/1WH4l-l8qXnWUa5BHHtIDgaU-UnMEJ2H_/view?usp=share_link) was built for the original BlueSim. To port an old level, open its source project in Godot 4.7.2, complete the project conversion, verify `custom_level.tscn`, and export a new PCK.

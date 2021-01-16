# BlueSim
BlueROV2 Simulator. [Online demo here](http://sim.galvanicloop.com/) (works better on Firefox).

# Download

 - [Windows](http://sim.galvanicloop.com/builds/windows/windows/bluesim.zip)
 - [Mac](http://sim.galvanicloop.com/builds/mac/mac/bluesim.zip)
 - [Linux](http://sim.galvanicloop.com/builds/linux/linux/bluesim.zip)

# Usage

  1. Open [QGroundControl](http://qgroundcontrol.com/)
  2. Set up a new communication link at TCP 127.0.0.1, port 5760.
  3. Launch BlueSim
  4. Chooset BlueRov2 Heavy
  5. Connect the new link in QGC
  6. Drive around using the gamepad as if controlling a real BlueRov2.


# Default keys:

If there is not SITL instance attached, these keys can be used to control the ROV:

|      Action      |  Key  |
|:----------------:|:-----:|
| Downwards        | Shift |
| Upwards          | Space |
| Forward          |   Up  |
| Backwards        |  Down |
| Rotate right     | Right |
| Rotate left      |  Left |
| Strafe right     |   D   |
| Strafe left      |   A   |
| Lights down      |   1   |
| Lights up        |   2   |
| Close gripper    |   3   |
| Open gripper     |   4   |
| Tilt camera down |   5   |
| Tilt camera up   |   6   |

# SITL integration:

    Before opening Bluesim (it launches its own SITL instance), run:

 `sim_vehicle.py -j6 -L RATBeach --frame JSON --out=udpout:0.0.0.0:14550`

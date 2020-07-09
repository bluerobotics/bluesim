# BlueSim
BlueROV2 Simulator. [Online demo here](http://sim.galvanicloop.com/) (works better on Firefox).


# Default keys:

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

 `sim_vehicle.py -j6 -L RATBeach --frame gazebo-bluerov2  --out=udpout:0.0.0.0:14550`

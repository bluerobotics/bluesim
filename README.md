# bluesim
BlueROV2 Simulator 


# Default keys:

| A     | Strafe Left      |
|-------|------------------|
| D     | Strafe Right     |
| Up    | Forward          |
| Down  | Backwards        |
| Left  | Turn Left        |
| Right | Turn Right       |
| 1     | Lights Down      |
| 2     | Lights Up        |
| 3     | Close Gripper    |
| 4     | Open Gripper     |
| 5     | Tilt Camera Down |
| 6     | Tilt Camera Up   |

# SITL integration:

 `sim_vehicle.py -j6 -L RATBeach --frame gazebo-bluerov2  --out=udpout:0.0.0.0:14550`

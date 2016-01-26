README for Q5
Author Group 5

Description:

If the light sensor value is less than threshold then all the leds are turned on. The threshold value is changed from the command line using 
$set [value]

UDP-MESSAGING:
After detection, 
Data is sent using the UDP messaging to the port 7000.
Auto build function for Sensor.py in Makefile is removed to use the custom Sensor.py function.

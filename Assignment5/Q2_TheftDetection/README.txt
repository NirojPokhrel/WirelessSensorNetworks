README for Q2
Author Group 5

Description:
1. Multicast message is send on port 7000 to all the nodes when the light sensor data when value is less than threshold or send the temperature sensor data when value is more than threshold(when temperature is increased during smoke).
2. Select USE_LIGHT_SENSOR/USE_TEMPERATURE_SENSOR to use one of the two sensor by changing it in detect.h.
3. Settings are send on port 4000. Initial request is send when the device boots up. Response is send if there are other nodes already in the network otherwise the value is set to default for the first node. Also, if the user changes the threshold value it is disseminated through port 4000.
4. Port 8000 is used to send the data to Listener.py via the router but it can be removed by changing the Listener.py to receive the multicast data.
5. If more than 7 nodes are present than modulo 7 is done to identify the group to which the node belong.

UDP-MESSAGING:
After detection, 
Data is sent using the UDP messaging to the port 7000.
Auto build function for Sensor.py in Makefile is removed to use the custom Sensor.py function.

import socket
import SmokeDetection
import re
import sys

port = 7000

if __name__ == '__main__':
	socket.inet_pton(socket.AF_INET6, "ff02::1")
	s = socket.socket(socket.AF_INET6, socket.SOCK_DGRAM)

	s.bind(('', port))
	while True:
		data, addr = s.recvfrom(1024)
		if (len(data) > 0):
			rpt = SmokeDetection.SmokeDetection(data=data, data_length=len(data))
			print addr
			print rpt


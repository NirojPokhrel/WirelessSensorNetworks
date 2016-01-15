#include <lib6lowpan/ip.h>
#include <ctype.h>

void ChangeEndianess(uint32_t num, char* output, int len);

void ChangeEndianess(uint32_t num, char* output, int len) {
	uint16_t shifter = 0;

	switch(len) {
		case sizeof(uint16_t):
			output[0] = (num>>24) & 0xff;
			output[1] = (num>>16) & 0xff;
			break;
		case sizeof(uint32_t):
			output[0] = (num>>24) & 0xff;
			output[1] = (num>>16) & 0xff;
			output[2] = (num>>8) & 0xff;
			output[3] = num & 0xff;
			break;
		case sizeof(uint64_t):
			output[0] = (num>>56) & 0xff;
			output[1] = (num>>48) & 0xff;
			output[2] = (num>>40) & 0xff;
			output[3] = (num>>32) & 0xff;
			output[4] = (num>>24) & 0xff;
			output[5] = (num>>16) & 0xff;
			output[6] = (num>>8) & 0xff;
			output[7] = num & 0xff;
			break;
	}

	//output[0] = (num>>8) & 0xff;
	//output[1] = num & 0xff;
}

module EchoP {
	uses {
		interface Boot;
		interface Leds;
		interface SplitControl as RadioControl;

		interface UDP as Echo;
	}
} implementation {

	event void Boot.booted() {
		call RadioControl.start();
		call Echo.bind(7);
		call Leds.led1On();
	}

	event void Echo.recvfrom(struct sockaddr_in6 *from, void *data,
			  uint16_t len, struct ip6_metadata *meta) {
		char* str = data;
		uint16_t i;
		bool isNumber = TRUE;
		char output[8];

		for (i = 0; i < len - 1; i++) {
			if (!isdigit(str[i])) {
				isNumber = FALSE;
				break;
			}
		}

		if (isNumber) {
			//Check atoi ( online if this is what it is supposed to do)
			i = atol(str);
			ChangeEndianess(i, output, sizeof(uint16_t));
			call Echo.sendto(from, output, sizeof(uint16_t));
			//call Echo.sendto(from, &i, sizeof(uint32_t));
		} else { 
			call Echo.sendto(from, data, len);
		}
	}

	event void RadioControl.startDone(error_t e) {}

	event void RadioControl.stopDone(error_t e) {}  
}

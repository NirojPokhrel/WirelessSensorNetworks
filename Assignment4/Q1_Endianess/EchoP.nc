#include <lib6lowpan/ip.h>
#include <ctype.h>


module EchoP {
	uses {
		interface Boot;
		interface Leds;
		interface SplitControl as RadioControl;

		interface UDP as Echo;
	}
} implementation {

	enum {
		ENUM_ITEM_NUM_SIZE = sizeof(uint16_t),
	};
	void ChangeEndianess(uint32_t num, char* output, int len);

	void ChangeEndianess(uint32_t num, char* output, int len) {
		uint8_t *pu8Char;
		int i;

		pu8Char = ((uint8_t*)&num)+len-1;
		for( i=0; i<len; i++ ) {
			*output++ = *pu8Char--;
		}
	}

	event void Boot.booted() {
		call RadioControl.start();
		call Echo.bind(7);
		call Leds.led1On();
	}

	event void Echo.recvfrom(struct sockaddr_in6 *from, void *data,
			  uint16_t len, struct ip6_metadata *meta) {
		char* str = data;
		uint32_t i;
		bool isNumber = TRUE;
		char output[ENUM_ITEM_NUM_SIZE];

		for (i = 0; i < len - 1; i++) {
			if (!isdigit(str[i])) {
				isNumber = FALSE;
				break;
			}
		}

		if (isNumber) {
			//Check atoi ( online if this is what it is supposed to do)
			i = atol(str);
			ChangeEndianess(i, output, ENUM_ITEM_NUM_SIZE);
			call Echo.sendto(from, output, ENUM_ITEM_NUM_SIZE);
			//call Echo.sendto(from, &i, sizeof(uint32_t));
		} else { 
			call Echo.sendto(from, data, len);
		}
	}

	event void RadioControl.startDone(error_t e) {}

	event void RadioControl.stopDone(error_t e) {}  
}

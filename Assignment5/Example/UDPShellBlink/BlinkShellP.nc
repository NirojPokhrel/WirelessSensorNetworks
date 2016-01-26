#include <stdio.h>
module BlinkShellP {
	uses {
		interface Boot;
  		interface Leds;
		interface SplitControl as RadioControl;

		interface ShellCommand as CountCmd;
	}
} implementation {

	event void Boot.booted() {
		call RadioControl.start();
	}

	event char* CountCmd.eval(int argc, char* argv[]) {
		char* reply_buf = call CountCmd.getBuffer(50);
		char *ledsBlinkStatus;
		int val, led0, led1, led2;
		if( argc != 2 ) {
			sprintf( reply_buf, "Wrong Command!!! Try: count [0-7] $count 1 (Led0 On Led1 Off Led2 Off\n");
		} else {
			ledsBlinkStatus = argv[1];
			val = ledsBlinkStatus[0] - '0';
			if( strlen(ledsBlinkStatus) != 1 || ( val <0 || val > 7) ) {
				sprintf( reply_buf, "Wrong Command!!! Try: count [0-7] $count 1 (Led0 On Led1 On Led2 Off\n");

				return reply_buf;
			}
			switch(val) {
				case 0:
					led0 = 0;
					led1 = 0;
					led2 = 0;
				break;
				case 1:
					led0 = 1;
					led1 = 0;
					led2 = 0;
				break;
				case 2:
					led0 = 0;
					led1 = 1;
					led2 = 0;
				break;
				case 3:
					led0 = 1;
					led1 = 1;
					led2 = 0;
				break;
				case 4:
					led0 = 0;
					led1 = 0;
					led2 = 1;
				break;
				case 5:
					led0 = 1;
					led1 = 0;
					led2 = 1;
				break;
				case 6:
					led0 = 0;
					led1 = 1;
					led2 = 1;
				break;
				case 7:
					led0 = 1;
					led1 = 1;
					led2 = 1;
				break;
			}
			if( 0 == led0 ) {
				call Leds.led0Off();
			} else
				call Leds.led0On();

			if( 0 == led1 ) {
				call Leds.led1Off();
			} else
				call Leds.led1On();

			if( 0 == led2 ) {
				call Leds.led2Off();
			} else
				call Leds.led2On();
			sprintf ( reply_buf, "Led0=%s Led1=%s Led2=%s\n", 0 == led0 ? "Off":"On", 0 == led1 ? "Off":"On", 0 == led2 ? "Off":"On");
		}
		return reply_buf;
	}

	event void RadioControl.startDone(error_t e) {}
	event void RadioControl.stopDone(error_t e) {}
}

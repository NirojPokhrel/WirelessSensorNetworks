#include <lib6lowpan/ip.h>
#include <stdio.h>

uint16_t read_done = 0;
uint16_t light_value;

module SensingP {
	uses {
		interface Boot;
		interface Leds;
		interface SplitControl as RadioControl;
		interface ShellCommand as ReadParCmd;

		interface Timer<TMilli> as SenseTimer;
		interface Read<uint16_t> as LightPar;
	}
} implementation {

	enum {
		Read_PERIOD = 250, // ms
		LightPar_THRESHOLD = 0x10,
	};

	event void Boot.booted() {
		call RadioControl.start();
		call SenseTimer.startPeriodic(Read_PERIOD);
	}
#if 1
	event void SenseTimer.fired() {
		call LightPar.read();
	}
#endif
	event void LightPar.readDone(error_t e, uint16_t val) {
		light_value = val;
		//read_done = 1;
	}

	event char* ReadParCmd.eval(int argc, char* argv[]) {
		char* reply_buf = call ReadParCmd.getBuffer(50);

		//Write the Light value and return
		//read_done = 0;
		//call LightPar.read();

		//while( !read_done ) {
			sprintf ( reply_buf, "\t[value: %d]\n", light_value);
		//}

		return reply_buf;
	}
	
	event void RadioControl.startDone(error_t e) {}

	event void RadioControl.stopDone(error_t e) {}
}

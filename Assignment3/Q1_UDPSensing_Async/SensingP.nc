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

		interface Read<uint16_t> as LightPar;
	}
} implementation {

	enum {
		Read_PERIOD = 250, // ms
		LightPar_THRESHOLD = 0x10,
	};

	event void Boot.booted() {
		call RadioControl.start();
	}
	event void LightPar.readDone(error_t e, uint16_t val) {
		int len;
		char* reply_buf = call ReadParCmd.getBuffer(50);
		len = sprintf( reply_buf, "Sensor Value: %d\n", val );
		call ReadParCmd.write(reply_buf, len+1);
	}

	event char* ReadParCmd.eval(int argc, char* argv[]) {
		char* reply_buf = call ReadParCmd.getBuffer(50);

		sprintf ( reply_buf, "Started Reading Sensor\n");
		call LightPar.read();

		return reply_buf;
	}
	
	event void RadioControl.startDone(error_t e) {}

	event void RadioControl.stopDone(error_t e) {}
}

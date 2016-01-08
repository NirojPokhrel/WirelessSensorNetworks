#include <lib6lowpan/ip.h>

module TempSensingP {
	uses {
		interface Boot;
		interface Leds;
		interface SplitControl as RadioControl;

		interface Timer<TMilli> as SenseTimer;
		interface Read<uint16_t> as TempPar;
	}
}
 implementation {
 	enum {
 		ENUM_READ_PERIOD = 256,
 		ENUM_TEMP_THRESHOLD = 0x0A,
 	};

 	event void Boot.booted() {
 		call RadioControl.start();
 		call SenseTimer.startPeriodic(ENUM_READ_PERIOD);
 	}

 	event void SenseTimer.fired() {
 		call TempPar.read();
 	}

 	event void TempPar.readDone( error_t result, uint16_t val) {
 		if( result == SUCCESS ) {
 			call Leds.led2Off();
 			if( val < ENUM_TEMP_THRESHOLD ) {
 				call Leds.led0On();
 				call Leds.led1Off();
 			} else {
 				call Leds.led0Off();
 				call Leds.led1On();
 			}
 		} else {
 			call Leds.led2On();
 		}
 	}

 	event void RadioControl.startDone( error_t result ) {

 	}

 	event void RadioControl.stopDone( error_t result ) {

 	}
 }
#include <lib6lowpan/ip.h>

#include <Timer.h>
#include "blip_printf.h"

module LightP {
	uses {
		interface Boot;
		interface Leds;
		interface SplitControl as RadioControl;
		interface Timer<TMilli> as SensorReadTimer;

		interface ReadStream<uint16_t> as StreamPar;

		interface ShellCommand as SetCmd;
	}
} implementation {

	enum {
		SAMPLE_RATE = 2000,
		SAMPLE_SIZE = 10,
		NUM_SENSORS = 1,
		ENUM_DEFAULT_THRESHOLD = 0x20,
		ENUM_DEFAULT_SAMPLE_PERIOD = 10000,
	};

	uint8_t m_remaining = NUM_SENSORS;
	uint32_t m_seq = 0;
	uint16_t m_par,m_tsr,m_hum,m_temp;
	uint16_t m_parSamples[SAMPLE_SIZE];
	uint16_t m_threshold = ENUM_DEFAULT_THRESHOLD;
	uint16_t m_samplePeriod = ENUM_DEFAULT_SAMPLE_PERIOD;


	event void Boot.booted() {
		call RadioControl.start();
		call SensorReadTimer.startPeriodic(SAMPLE_RATE);
	}

	task void checkStreamPar() {
		uint8_t i;
		uint32_t val = 0;

		for (i = 0; i < SAMPLE_SIZE; i++) {
			val += m_parSamples[i];
		} 
		val /= 10; 
		if( val < 10 ) {
			call Leds.led0On();
			call Leds.led1On();
			call Leds.led2On();
		} else {
			call Leds.led0Off();
			call Leds.led1Off();
			call Leds.led2Off();
		}
	}

	event void SensorReadTimer.fired() {
		call StreamPar.postBuffer(m_parSamples, SAMPLE_SIZE);
		call StreamPar.read(m_samplePeriod);
	}

	event void StreamPar.readDone(error_t ok, uint32_t usActualPeriod) {
		if (ok == SUCCESS) {
			post checkStreamPar();
		}
	}

	event void StreamPar.bufferDone(error_t ok, uint16_t *buf,uint16_t count) {}

	event char* SetCmd.eval( int argc, char* argv[] ) {
		char *reply_buf = call SetCmd.getBuffer(128);
		uint16_t val = 0;

		if( reply_buf == NULL ) {
			return NULL;
		}
		if( argc != 2 ) {
			sprintf( reply_buf, "Wrong Command!!! Try $set [0-1000]");
		} else {
			val = atoi(argv[1]);
			m_threshold = val; 
			sprintf(reply_buf, "Threshold set to %d\n", m_threshold);
		}

		return reply_buf;
	}


	event void RadioControl.startDone(error_t e) {}
	event void RadioControl.stopDone(error_t e) {}
}

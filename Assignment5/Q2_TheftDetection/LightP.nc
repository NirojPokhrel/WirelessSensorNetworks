#include <lib6lowpan/ip.h>

#include <Timer.h>
#include "blip_printf.h"
#include "detect.h"


module LightP {
	uses {
		interface Boot;
		interface Leds;
		interface UDP as SenseSend;
		interface UDP as Settings;
		interface SplitControl as RadioControl;
		interface Timer<TMilli> as SensorReadTimer;
		interface Timer<TMilli> as InitialWaitTimer;

		interface ReadStream<uint16_t> as StreamPar;

		interface ShellCommand as SetCmd;
		interface ShellCommand as GetCmd;
	}
} implementation {

	enum {
		SAMPLE_RATE = 256,
		SAMPLE_SIZE = 10,
		ENUM_DEFAULT_THRESHOLD = 10,
		ENUM_DEFAULT_SAMPLE_PERIOD = 10000,
		ENUM_SETTINGS_REQUEST = 1,
		ENUM_SETTINGS_RESPONSE = 2,
		ENUM_SETTINGS_USERS = 4,
	};

	uint8_t m_responseReceived = 0;
	uint16_t m_parSamples[SAMPLE_SIZE];
	uint16_t m_threshold = ENUM_DEFAULT_THRESHOLD;
	uint16_t m_samplePeriod;
	uint16_t m_sampleTime;

	nx_struct alarm_report stats;
	struct sockaddr_in6 alarm_report_sock;

	nx_struct settings_report settingsReport;
	struct sockaddr_in6 settings_report_sock;



	event void Boot.booted() {
		call RadioControl.start();
	}

	event void SensorReadTimer.fired() {
		call StreamPar.postBuffer(m_parSamples, SAMPLE_SIZE);
		call StreamPar.read(m_samplePeriod);
	}

	event void InitialWaitTimer.fired() {
		if( !m_responseReceived ) {
			m_threshold = ENUM_DEFAULT_THRESHOLD;
			m_samplePeriod = SAMPLE_RATE;
			m_sampleTime = ENUM_DEFAULT_SAMPLE_PERIOD;
			//If no response is received start sampling with the default value
			alarm_report_sock.sin6_port = htons(7000);
			inet_pton6(MULTICAST, &alarm_report_sock.sin6_addr);
			call SenseSend.bind(7000);
			call SensorReadTimer.startPeriodic(m_samplePeriod);
		}

	}

	event void StreamPar.bufferDone(error_t ok, uint16_t *buf,uint16_t count) {}


	task void userSettings() {
		settingsReport.sender = TOS_NODE_ID;
		settingsReport.type = ENUM_SETTINGS_USERS;
		settingsReport.settings.threshold = m_threshold;
		settingsReport.settings.sample_time = m_sampleTime;
		settingsReport.settings.sample_period = m_samplePeriod;

		call Settings.sendto(&settings_report_sock, &settingsReport, sizeof(settingsReport));
	}

	task void requestSettings() {
		settingsReport.sender = TOS_NODE_ID;
		settingsReport.type = ENUM_SETTINGS_REQUEST;
		call Settings.sendto(&settings_report_sock, &settingsReport, sizeof(settingsReport));
	}

	task void responseSettings() {
		settingsReport.sender = TOS_NODE_ID;
		settingsReport.type = ENUM_SETTINGS_RESPONSE;
		settingsReport.settings.threshold = m_threshold;
		settingsReport.settings.sample_time = m_sampleTime;
		settingsReport.settings.sample_period = m_samplePeriod;

		call Settings.sendto(&settings_report_sock, &settingsReport, sizeof(settingsReport));

	}

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
			//TODO: POST A REPLY MESSAGE
			post userSettings();
		}

		return reply_buf;
	}

	event char* GetCmd.eval( int argc, char* argv[] ) {
		char *reply_buf = call SetCmd.getBuffer(128);
		uint16_t val = 0;

		if( reply_buf == NULL ) {
			return NULL;
		}
		if( argc > 1 ) {
			sprintf( reply_buf, "Wrong Command!!! Try $get");
		} else {
			sprintf(reply_buf, "Threshold %d\n", m_threshold);
		}

		return reply_buf;
	}

	task void report_lightPar() {
		stats.source = TOS_NODE_ID;
		call SenseSend.sendto(&alarm_report_sock, &stats, sizeof(stats));
	}

	task void checkStreamPar() {
		uint8_t i;
		uint32_t val = 0;

		for (i = 0; i < SAMPLE_SIZE; i++) {
			val += m_parSamples[i];
		} 
		val /= 10; 
		if( val < m_threshold ) {
			call Leds.led0On();
			call Leds.led1On();
			call Leds.led2On();
			post report_lightPar();
			//TODO: post multicast messages();
		} else {
			call Leds.led0Off();
			call Leds.led1Off();
			call Leds.led2Off();
		}
	}

	event void StreamPar.readDone(error_t ok, uint32_t usActualPeriod) {
		if (ok == SUCCESS) {
			post checkStreamPar();
		}
	}

	event void RadioControl.startDone(error_t e) {

		settings_report_sock.sin6_port = htons(4000);
		inet_pton6(MULTICAST, &settings_report_sock.sin6_addr );
		call Settings.bind(4000);
		/*Wait for 5 seconds for the reply if not initialize with the default value. Maybe it is the first in the network.*/
		post requestSettings();
		call InitialWaitTimer.startOneShot(5000);
	}
	
	event void RadioControl.stopDone(error_t e) {}

	event void Settings.recvfrom(struct sockaddr_in6 *from, 
			void *data, uint16_t len, struct ip6_metadata *meta) {
			nx_struct settings_report *settingsReport = (nx_struct settings_report*)data;

			switch( settingsReport->type ) {
			case ENUM_SETTINGS_REQUEST:
				post responseSettings();
				break;
			case ENUM_SETTINGS_RESPONSE:
				//Data is received start reading the data
				if( m_responseReceived )  //Already received can drop any other data
					break;
				alarm_report_sock.sin6_port = htons(7000);
				inet_pton6(MULTICAST, &alarm_report_sock.sin6_addr);
				call SenseSend.bind(7000);
				call SensorReadTimer.startPeriodic(m_samplePeriod);
				m_responseReceived = 1;
				//break; Fall through the break to update the data 
			case ENUM_SETTINGS_USERS:
				m_threshold = settingsReport->settings.threshold;
				m_sampleTime = settingsReport->settings.sample_time;
				m_samplePeriod = settingsReport->settings.sample_period;
				break;
			}
	}

	event void SenseSend.recvfrom(struct sockaddr_in6 *from, 
			void *data, uint16_t len, struct ip6_metadata *meta) {
			uint16_t u16Source;
			nx_struct alarm_report *report  = (nx_struct alarm_report*)data;
			u16Source = report->source;
			/*Print the modulo of the source so each node can be identified as one of the seven*/
			while( u16Source > 7 ) {
				u16Source -= 7;
			}
			switch( u16Source ) {
				case 2:
					call Leds.led0Off();
					call Leds.led1On();
					call Leds.led2Off();
					break;
				case 3:
					call Leds.led0On();
					call Leds.led1On();
					call Leds.led2Off();
					break;
				case 4:
					call Leds.led0Off();
					call Leds.led1Off();
					call Leds.led2On();
					break;
				case 5:
					call Leds.led0On();
					call Leds.led1Off();
					call Leds.led2On();
					break;
				case 6:
					call Leds.led0Off();
					call Leds.led1On();
					call Leds.led2On();
					break;
				case 7:
					call Leds.led0On();
					call Leds.led1On();
					call Leds.led2On();
					break;
				default:
					break;
			}
	}
}

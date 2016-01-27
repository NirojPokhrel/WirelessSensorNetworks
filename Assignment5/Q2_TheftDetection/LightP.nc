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
		//ReportDst can be removed by making changes in Listener.py to receive the broadcast data.
		interface UDP as ReportDst;
		interface SplitControl as RadioControl;
		interface Timer<TMilli> as SensorReadTimer;
		interface Timer<TMilli> as InitialWaitTimer;
#if defined(USE_LIGHT_SENSOR)
		interface ReadStream<uint16_t> as StreamPar;
#else if defined(USE_TEMPERATURE_SENSOR)
		interface Read<uint16_t> as ReadTemp;
#endif
		interface ShellCommand as SetCmd;
		interface ShellCommand as GetCmd;
	}
} implementation {

	enum {
		SAMPLE_RATE = 256,
		SAMPLE_SIZE = 10,
#if defined(USE_LIGHT_SENSOR)
		ENUM_DEFAULT_THRESHOLD = 10,
#else if defined(USE_TEMPERATURE_SENSOR)
		//More than the room temperature
		ENUM_DEFAULT_THRESHOLD = 6510,
#endif
		ENUM_DEFAULT_SAMPLE_PERIOD = 10000,
		ENUM_SETTINGS_REQUEST = 1,
		ENUM_SETTINGS_RESPONSE = 2,
		ENUM_SETTINGS_USERS = 4,
	};

	uint8_t m_responseReceived = 0;
#if defined(USE_LIGHT_SENSOR)
	uint16_t m_parSamples[SAMPLE_SIZE];
#else if defined(USE_TEMPERATURE_SENSOR)
	uint16_t m_temp;
#endif
	uint16_t m_threshold;
	uint16_t m_samplePeriod;
	uint16_t m_sampleTime;

	nx_struct alarm_report stats;
	struct sockaddr_in6 alarm_report_sock;

	nx_struct settings_report settingsReport;
	struct sockaddr_in6 settings_report_sock;

	struct sockaddr_in6  report_dst_sock;

	event void Boot.booted() {
		call RadioControl.start();
		m_responseReceived = 0;
	}

	event void SensorReadTimer.fired() {
#if defined(USE_LIGHT_SENSOR)
		call StreamPar.postBuffer(m_parSamples, SAMPLE_SIZE);
		call StreamPar.read(m_sampleTime);
#else if defined(USE_TEMPERATURE_SENSOR)
		call ReadTemp.read();
#endif
	}

	event void InitialWaitTimer.fired() {
		if( !m_responseReceived ) {
			m_threshold = ENUM_DEFAULT_THRESHOLD;
			m_samplePeriod = SAMPLE_RATE;
			m_sampleTime = ENUM_DEFAULT_SAMPLE_PERIOD;
		}
		//After getting the configuration start reading
		call SensorReadTimer.startPeriodic(m_samplePeriod);
	}


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

	task void report_sensorData() {
		stats.source = TOS_NODE_ID;
		call SenseSend.sendto(&alarm_report_sock, &stats, sizeof(stats));
		call ReportDst.sendto(&report_dst_sock, &stats, sizeof(stats));
	}

	task void checkSensorData() {
		uint8_t i;
		uint32_t val = 0;
#if defined(USE_LIGHT_SENSOR)
		for (i = 0; i < SAMPLE_SIZE; i++) {
			val += m_parSamples[i];
		} 
		val /= 10; 
		if( val < m_threshold ) {
#else if defined(USE_TEMPERATURE_SENSOR)
		val = m_temp;
		if( val > m_threshold ) {
#endif
			call Leds.led0On();
			call Leds.led1On();
			call Leds.led2On();
			post report_sensorData();
		} else {
			call Leds.led0Off();
			call Leds.led1Off();
			call Leds.led2Off();
		}
	}

#if defined(USE_LIGHT_SENSOR)

	event void StreamPar.readDone(error_t ok, uint32_t usActualPeriod) {
		if (ok == SUCCESS) {
			post checkSensorData();
		}
	}

	event void StreamPar.bufferDone(error_t ok, uint16_t *buf,uint16_t count) {}

#else if defined(USE_TEMPERATURE_SENSOR)

	event void ReadTemp.readDone(error_t e, uint16_t data) {
		if ( e == SUCCESS ) {
			m_temp = data;
			post checkSensorData();
		}
	}

#endif
	event void RadioControl.startDone(error_t e) {

		alarm_report_sock.sin6_port = htons(7000);
		inet_pton6(MULTICAST, &alarm_report_sock.sin6_addr);
		call SenseSend.bind(7000);

		report_dst_sock.sin6_port = htons(8000);
		inet_pton6(REPORT_DEST, &report_dst_sock.sin6_addr);
		call ReportDst.bind(8000);

		settings_report_sock.sin6_port = htons(4000);
		inet_pton6(MULTICAST, &settings_report_sock.sin6_addr );
		call Settings.bind(4000);
		/*Wait for 2 seconds for the reply if not initialize with the default value. Maybe it is the first node in the network.*/
		post requestSettings();
		call InitialWaitTimer.startOneShot(2000);
	}
	
	event void RadioControl.stopDone(error_t e) {}

	event void Settings.recvfrom(struct sockaddr_in6 *from, 
			void *data, uint16_t len, struct ip6_metadata *meta) {
			nx_struct settings_report *recivedSettings = (nx_struct settings_report*)data;

			switch( recivedSettings->type ) {
			case ENUM_SETTINGS_REQUEST:
				post responseSettings();
				break;
			case ENUM_SETTINGS_RESPONSE:
				//Data is received start reading the data
				if( m_responseReceived )  //Already received can drop any other data
					break;
				m_responseReceived = 1;
				m_threshold = recivedSettings->settings.threshold;
				m_sampleTime = recivedSettings->settings.sample_time;
				m_samplePeriod = recivedSettings->settings.sample_period;
				break; 
			case ENUM_SETTINGS_USERS:
				m_threshold = recivedSettings->settings.threshold;
				m_sampleTime = recivedSettings->settings.sample_time;
				m_samplePeriod = recivedSettings->settings.sample_period;
				break;
			}
	}

	event void ReportDst.recvfrom(struct sockaddr_in6 *from, 
			void *data, uint16_t len, struct ip6_metadata *meta) {}

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

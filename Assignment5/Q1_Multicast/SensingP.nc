#include <lib6lowpan/ip.h>
#include "sensing.h"
#include "blip_printf.h"

module SensingP {
	uses {
		interface Boot;
		interface Leds;
		interface SplitControl as RadioControl;

		interface UDP as VoltSend;
		interface UDP as Settings;

		interface ShellCommand as GetCmd;
		interface ShellCommand as SetCmd;

		interface Timer<TMilli> as VoltTimer;
		interface Read<uint16_t> as Volt;

		interface Mount as ConfigMount;
		interface ConfigStorage;
	}
} implementation {

	enum {
		VOLTAGE_PERIOD = 5000, // ms
		LOW_VOLTAGE_THRESHOLD = 1000,
	};

	settings_t settings;
	uint16_t m_volt;
	nx_struct sensing_report stats;
	struct sockaddr_in6 route_dest;
	struct sockaddr_in6 multicast;

	event void Boot.booted() {
		settings.voltage_period = VOLTAGE_PERIOD;
		settings.voltage_threshold = LOW_VOLTAGE_THRESHOLD;

		route_dest.sin6_port = htons(7000);
		inet_pton6(REPORT_DEST, &route_dest.sin6_addr);

		multicast.sin6_port = htons(4000);
		inet_pton6(MULTICAST, &multicast.sin6_addr);
		call Settings.bind(4000);

		call ConfigMount.mount();

		//call RadioControl.start();
	}

	//radio
	event void RadioControl.startDone(error_t e) {
		call VoltTimer.startPeriodic(settings.voltage_period);
	}
	event void RadioControl.stopDone(error_t e) {}



	//config
	
	event void ConfigMount.mountDone(error_t e) {
		if (e != SUCCESS) {
			call Leds.led0On();
			call RadioControl.start();
		} else {
			if (call ConfigStorage.valid()) {
				call ConfigStorage.read(0, &settings, sizeof(settings));
			} else {
				settings.voltage_period = VOLTAGE_PERIOD;
				settings.voltage_threshold = LOW_VOLTAGE_THRESHOLD;
				call RadioControl.start();
			}
		}
	}

	event void ConfigStorage.readDone(storage_addr_t addr, void* buf, storage_len_t len, error_t e) {
		call RadioControl.start();
	}

	event void ConfigStorage.writeDone(storage_addr_t addr, void* buf, storage_len_t len, error_t e) {
		call ConfigStorage.commit();
	}

	event void ConfigStorage.commitDone(error_t error) {}




	//udp interfaces

	event void VoltSend.recvfrom(struct sockaddr_in6 *from, void *data, uint16_t len, struct ip6_metadata *meta) {}

	event void Settings.recvfrom(struct sockaddr_in6 *from, void *data, uint16_t len, struct ip6_metadata *meta) {
		memcpy(&settings, data, sizeof(settings_t));
		call ConfigStorage.write(0, &settings, sizeof(settings));
	}

	//udp shell

	event char *GetCmd.eval(int argc, char **argv) {
		char *ret = call GetCmd.getBuffer(40);
		if (ret != NULL) {
			switch (argc) {
				case 1:
					sprintf(ret, "\t[Period: %u]\n\t[Threshold: %u]\n", settings.voltage_period, settings.voltage_threshold);
					break;
				case 2: 
					if (!strcmp("per",argv[1])) {
						sprintf(ret, "\t[Period: %u]\n", settings.voltage_period);
					} else if (!strcmp("th", argv[1])) {
						sprintf(ret, "\t[Threshold: %u]\n",settings.voltage_threshold);
					} else {
						strcpy(ret, "Usage: get [per|th]\n");
					}
					break;
				default:
					strcpy(ret, "Usage: get [per|th]\n");
			}
		}
		return ret;
	}

	task void report_settings() {
		call Settings.sendto(&multicast, &settings, sizeof(settings));
		call ConfigStorage.write(0, &settings, sizeof(settings));
	}

	event char *SetCmd.eval(int argc, char **argv) {
		char *ret = call SetCmd.getBuffer(40);
		if (ret != NULL) {
			if (argc == 3) { 
				if (!strcmp("per",argv[1])) {
					settings.voltage_period = atoi(argv[2]);
					sprintf(ret, ">>>Period changed to %u\n",settings.voltage_period);
					post report_settings();
				} else if (!strcmp("th", argv[1])) {
					settings.voltage_threshold = atoi(argv[2]);
					sprintf(ret, ">>>Threshold changed to %u\n",settings.voltage_threshold);
					post report_settings();
				} else {
					strcpy(ret,"Usage: set per|th [<sampleperiod in ms>|<threshold>]\n");
				}
			} else if(argc == 4) {
				if(!strcmp("local", argv[3])) {
					if (!strcmp("per",argv[1])) {
						settings.voltage_period = atoi(argv[2]);
						sprintf(ret, ">>>Period changed to %u locally\n",settings.voltage_period);
					} else if (!strcmp("th", argv[1])) {
						settings.voltage_threshold = atoi(argv[2]);
						sprintf(ret, ">>>Threshold changed to %u locally\n",settings.voltage_threshold);
					} else {
						strcpy(ret,"Usage: set per|th [<sampleperiod in ms>|<threshold>]\n");
					}
				} else {
					strcpy(ret,"Usage: set per|th [<sampleperiod in ms>|<threshold>]\n");
				}
			} else {
				strcpy(ret,"Usage: set per|th [<sampleperiod in ms>|<threshold>]\n");
			}
		}
		return ret;
	}


	//voltage report loop	

	event void VoltTimer.fired() {
		call Volt.read();
	}

	task void report_volt() {
		stats.seqno++;
		stats.sender = TOS_NODE_ID;
		stats.voltage = m_volt;
		call VoltSend.sendto(&route_dest, &stats, sizeof(stats));
	}

	event void Volt.readDone(error_t ok, uint16_t val) {
		if (ok == SUCCESS) {
			m_volt = val;    
			if (val < settings.voltage_threshold) {
				call Leds.led0On();
			} else { 
				call Leds.led0Off();
			}
			post report_volt();
		}
	}
}

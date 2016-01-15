#include <lib6lowpan/ip.h>
#include "sensing.h"

module SensingP {
	uses {
		interface Boot;
		interface Leds;
		interface SplitControl as RadioControl;
		interface UDP as SenseSend;
		interface Timer<TMilli> as SenseTimer;
		interface Read<uint16_t> as Humidity;

		interface Timer<TMilli> as LightSenseTimer;
		interface Read<uint16_t> as LightPar;
	}

} implementation {

	enum {
		SENSE_PERIOD = 500, // ms
		ENUM_SENSE_PERIOD_LIGHT = 128,
		ENUM_SENSOR_TYPE_HUMIDITY = 0,
		ENUM_SENSOR_TYPE_LIGHT = 1,
	};

	nx_struct sensing_report stats;
	struct sockaddr_in6 route_dest;
	m_humidity = 0;

	nx_struct sensing_report statsLight;
	struct sockaddr_in6 route_destLight;
	m_lightPar = 0;

	event void Boot.booted() {
		call RadioControl.start();
	}

	event void RadioControl.startDone(error_t e) {
		route_dest.sin6_port = htons(7000);
		inet_pton6(REPORT_DEST, &route_dest.sin6_addr);
		call SenseTimer.startPeriodic(SENSE_PERIOD);

		route_destLight.sin6_port = htons(8000);
		inet_pton6(REPORT_DEST, &route_destLight.sin6_addr);
		call LightSenseTimer.startPeriodic(ENUM_SENSE_PERIOD_LIGHT);

	}

	task void report_humidity() {
		stats.seqno++;
		stats.sender = TOS_NODE_ID;
		stats.humidity = m_humidity;
		call SenseSend.sendto(&route_dest, &stats, sizeof(stats));
	}

	event void SenseSend.recvfrom(struct sockaddr_in6 *from, 
			void *data, uint16_t len, struct ip6_metadata *meta) {}

	event void SenseTimer.fired() {
		call Humidity.read();
	}

	event void Humidity.readDone(error_t ok, uint16_t val) {
		if (ok == SUCCESS) {
			m_humidity = val;
			post report_humidity();
		}
	}

	task void report_lightPar() {
		statsLight.seqno++;
		statsLight.sender = TOS_NODE_ID;
		statsLight.humidity = m_lightPar;
		call SenseSend.sendto(&route_destLight, &statsLight, sizeof(statsLight));
	}

	event void LightSenseTimer.fired() {
		call LightPar.read();
	}

	event void LightPar.readDone( error_t ok, uint16_t val ) {
		if( ok == SUCCESS ) {
			m_lightPar = val;
			post report_lightPar();
		}
	}

	event void RadioControl.stopDone(error_t e) {}
}

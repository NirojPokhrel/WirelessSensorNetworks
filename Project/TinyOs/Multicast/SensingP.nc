#include <lib6lowpan/ip.h>
#include "sensing.h"
#include "blip_printf.h"

module SensingP {
	uses {
		interface Boot;
		interface Leds;
		interface SplitControl as RadioControl;

		interface UDP as UserPacket;

		interface ShellCommand as StartNwrkCmd;

		interface Timer<TMilli> as WaitTimer;
	}
} implementation {
	task void multicast_leaderSelection();
	void checkLeaderSelectionPkt( void *data );

	struct sockaddr_in6 route_dest;
	struct sockaddr_in6 multicast;

	//Niroj
	nx_uint8_t dataBuffer[20];
	leader_selection_t leaderPkt;
	header_t pktHeader;
	sensor_state_t sensorState;
	uint8_t u8Reset;

	event void Boot.booted() {

		route_dest.sin6_port = htons(7000);
		inet_pton6(REPORT_DEST, &route_dest.sin6_addr);

		multicast.sin6_port = htons(4000);
		inet_pton6(MULTICAST, &multicast.sin6_addr);
		call UserPacket.bind(4000);

		call RadioControl.start();
		u8Reset = 0;

		sensorState.m_u8BatteryLevel = TOS_NODE_ID+10;
		sensorState.m_u8LeaderId = TOS_NODE_ID;
		sensorState.m_u8LeaderBatteryLevel = TOS_NODE_ID+10;

	}

	//radio
	event void RadioControl.startDone(error_t e) {
	}
	event void RadioControl.stopDone(error_t e) {}


	//udp shell


	event char *StartNwrkCmd.eval(int argc, char **argv) {
		post multicast_leaderSelection();

   	    call WaitTimer.startOneShot( 5000 );
		u8Reset = 1;
		
		return "Successful";
	}
	
	task void multicast_leaderSelection() {
		// Get battery Level
		// Multicast it to all other nodes and wait for objection for 5 seconds 
		// If no objection within 5 seconds then send another confirmation package about it's election
		// Get confirmation from the network
		leader_selection_t *psLeaderPkt;
		header_t *psPktHeader;

		psPktHeader = (header_t*)dataBuffer;
		psPktHeader->m_u8Type = MESSAGE_TYPE_LEADER_SELECTION;
		psPktHeader->m_u8PayloadSize = sizeof(leader_selection_t);

		psLeaderPkt = (leader_selection_t*) (dataBuffer+sizeof(leader_selection_t));
		psLeaderPkt->m_u8BatteryLevel = TOS_NODE_ID+10;
		psLeaderPkt->m_u8NodeId = TOS_NODE_ID;

		call UserPacket.sendto(&multicast, dataBuffer, psPktHeader->m_u8PayloadSize + sizeof(header_t));
	}	

	event void UserPacket.recvfrom(struct sockaddr_in6 *from, void *data, uint16_t len, struct ip6_metadata *meta) { 
		header_t *headerPtr = (header_t*) data;
		switch(headerPtr->m_u8Type) {
			case MESSAGE_TYPE_LEADER_SELECTION:
				if( sizeof(leader_selection_t) == headerPtr->m_u8PayloadSize ) {
					checkLeaderSelectionPkt((uint8_t*)data + sizeof(header_t));
				}
			break;
		}
	}

	void checkLeaderSelectionPkt( void *data ) {
		leader_selection_t *leaderSelectionData = (leader_selection_t*) data;

		if( sensorState.m_u8LeaderBatteryLevel < leaderSelectionData->m_u8BatteryLevel) {
			sensorState.m_u8LeaderBatteryLevel = leaderSelectionData->m_u8BatteryLevel;
			sensorState.m_u8LeaderId = leaderSelectionData->m_u8NodeId;
		} else if ( sensorState.m_u8LeaderBatteryLevel == leaderSelectionData->m_u8BatteryLevel ) {
			if( TOS_NODE_ID > leaderSelectionData->m_u8NodeId ) {
				sensorState.m_u8LeaderId = leaderSelectionData->m_u8NodeId;
			}
		} else {
			post multicast_leaderSelection();
		}

		if( !u8Reset ) {
   	    	call WaitTimer.startOneShot( 5000 );
			u8Reset = 1;
		}
	}


  	event void WaitTimer.fired() {
  		call Leds.set(sensorState.m_u8LeaderId);
  	}
}

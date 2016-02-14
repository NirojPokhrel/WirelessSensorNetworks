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
#if ENABLE_DEBUG
		interface ShellCommand as DebugCmd;
#endif

		interface Timer<TMilli> as WaitTimer;
	}
} implementation {
	task void multicast_leaderSelection();
	task void multicast_requestNodeid();
	task void replyNodeInfo();
	task void assign_role();

	void checkLeaderSelectionPkt( void *data );
	void replyNodeIdToLeader(void *data);
	void addSlaveToNetwork(void *data);
	void addRoleToSlaves(void *data );

	struct sockaddr_in6 route_dest;
	struct sockaddr_in6 multicast;

	//Niroj
	nx_uint8_t settingsBuffer[20];
	uint8_t tempData[20];
	leader_selection_t leaderPkt;
	header_t pktHeader;
	sensor_state_t sensorState;
	leader_state_t leaderState;
	uint8_t u8Reset;
#if ENABLE_DEBUG
	debug_info_t debugInfo;
#endif
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
		sensorState.m_u8LastRequest = 0;

		leaderState.m_u8NumOfSlavesInNetwork = 0;
#if ENABLE_DEBUG
		debugInfo.m_u8NumberOfPackets = 0;
		debugInfo.m_u8CountNodeTwo = 0;
		debugInfo.m_u8CountNodeThree = 0;
		debugInfo.m_u8CountNodeFour = 0;
		debugInfo.m_u8CountNothing = 0;
#endif
	}

	//radio
	event void RadioControl.startDone(error_t e) {
	}
	event void RadioControl.stopDone(error_t e) {}


	//udp shell


	event char *StartNwrkCmd.eval(int argc, char **argv) {
		sensorState.m_u8LastRequest++;
		post multicast_leaderSelection();

   	    call WaitTimer.startOneShot( 5000 );
		u8Reset = 1;

		return "Successful\n";
	}
#if ENABLE_DEBUG	
	event char *DebugCmd.eval(int argc, char **argv) {
		char retValue[200];

		if( argc > 1  ){
			if( atoi(argv[1]) == 1 ) {
				sprintf(retValue, "NodeId=%d\nBatteryLevel=%d\nRequestId=%d\n", debugInfo.m_puLastPacket.m_u8NodeId, debugInfo.m_puLastPacket.m_u8BatteryLevel, debugInfo.m_puLastPacket.m_u8RequestId );
			}
		} else {
			sprintf(retValue, "Lead=%d\nLeadBat=%d\nNumPack=%d\nTwoC=%d\nThreeC=%d\nFourC=%d\nNo=%d\nLReq=%d\n", sensorState.m_u8LeaderId, sensorState.m_u8LeaderBatteryLevel, debugInfo.m_u8NumberOfPackets, debugInfo.m_u8CountNodeTwo, debugInfo.m_u8CountNodeThree, debugInfo.m_u8CountNodeFour, debugInfo.m_u8CountNothing, sensorState.m_u8LastRequest );
		}

		return retValue;
	}
#endif
	task void multicast_leaderSelection() {
		// Get battery Level
		// Multicast it to all other nodes and wait for objection for 5 seconds 
		// If no objection within 5 seconds then send another confirmation package about it's election
		// Get confirmation from the network
		leader_selection_t *psLeaderPkt;
		header_t *psPktHeader;

		psPktHeader = (header_t*)settingsBuffer;
		psPktHeader->m_u8Type = MESSAGE_TYPE_LEADER_SELECTION;
		psPktHeader->m_u8PayloadSize = sizeof(leader_selection_t);

		psLeaderPkt = (leader_selection_t*) ((uint8_t*)settingsBuffer+sizeof(header_t));
		psLeaderPkt->m_u8BatteryLevel = TOS_NODE_ID+10;
		psLeaderPkt->m_u8NodeId = TOS_NODE_ID;
		psLeaderPkt->m_u8RequestId = sensorState.m_u8LastRequest;

		memcpy( &debugInfo.m_puLastPacket, (uint8_t*)settingsBuffer+sizeof(header_t), sizeof(leader_selection_t) );
		call UserPacket.sendto(&multicast, settingsBuffer, psPktHeader->m_u8PayloadSize + sizeof(header_t));
	}	

	event void UserPacket.recvfrom(struct sockaddr_in6 *from, void *data, uint16_t len, struct ip6_metadata *meta) {
		header_t *headerPtr; 

		memcpy( tempData, data, len );
		headerPtr = (header_t*) tempData;
		switch(headerPtr->m_u8Type) {
			case MESSAGE_TYPE_LEADER_SELECTION:
#if ENABLE_DEBUG
				debugInfo.m_u8NumberOfPackets++;
#endif
				if( sizeof(leader_selection_t) == headerPtr->m_u8PayloadSize ) {
					checkLeaderSelectionPkt((uint8_t*)tempData + sizeof(header_t));
				}
			break;
/*
			case MESSAGE_TYPE_LEADER_REQUEST_NODE_IDS:
				if( sizeof(leader_selection_t) == headerPtr->m_u8PayloadSize ) {
					replyNodeIdToLeader(tempData + sizeof(header_t));
				}
			break;
			case MESSAGE_TYPE_LEADER_REPLY_NODE_IDS:
				if( SENSOR_STATE_LEADER == sensorState.m_u8NodeRole ) {
					if( sizeof(slave_reply_t) == headerPtr->m_u8PayloadSize ) {
						addSlaveToNetwork(tempData + sizeof(header_t));
					}
				}
			break;
*/
			case MESSAGE_TYPE_LEADER_ASSIGN_ROLE:
				if( sizeof(slave_info_t) == headerPtr->m_u8PayloadSize ) {
					addRoleToSlaves(tempData + sizeof(header_t));
				}
			break;

		}
	}

	void checkLeaderSelectionPkt( void *data ) {
		leader_selection_t *leaderSelectionData = (leader_selection_t*) data;
#if ENABLE_DEBUG
		if( 2 == leaderSelectionData->m_u8NodeId ) {
			debugInfo.m_u8CountNodeTwo++;
		} else if( 3 == leaderSelectionData->m_u8NodeId ) {
			debugInfo.m_u8CountNodeThree++;

		} else if( 4 == leaderSelectionData->m_u8NodeId ) {
			debugInfo.m_u8CountNodeFour++;
		} else  {
			debugInfo.m_u8CountNothing++;
		}
#endif
		memcpy( &debugInfo.m_puLastPacket, data, sizeof(leader_selection_t) );
		if( leaderSelectionData->m_u8NodeId > 10 )
			return;

		if( sensorState.m_u8LeaderBatteryLevel < leaderSelectionData->m_u8BatteryLevel) {
			sensorState.m_u8LeaderBatteryLevel = leaderSelectionData->m_u8BatteryLevel;
			sensorState.m_u8LeaderId = leaderSelectionData->m_u8NodeId;
		} else if ( sensorState.m_u8LeaderBatteryLevel == leaderSelectionData->m_u8BatteryLevel ) {
			if( TOS_NODE_ID > leaderSelectionData->m_u8NodeId ) {
				sensorState.m_u8LeaderId = leaderSelectionData->m_u8NodeId;
			}
		} //else
		if( TOS_NODE_ID  == (leaderSelectionData->m_u8NodeId+1)) 
		{
			post multicast_leaderSelection();
		}

		if( !u8Reset ) {
   	    	call WaitTimer.startOneShot( 5000 );
			u8Reset = 1;
		}
	}

	void replyNodeIdToLeader(void *data) {
		leader_selection_t *leaderData = (leader_selection_t*) data;
		if( sensorState.m_u8LeaderId == leaderData->m_u8NodeId) {
			//Prepare the data to be send to the leader
  			//call Leds.set(sensorState.m_u8LeaderId);
			post replyNodeInfo();
		} 
	}

	void addSlaveToNetwork(void *data) {
		slave_reply_t *slaveData = (slave_reply_t*) data;

		if( slaveData -> m_u8NodeId < MAX_NUMBER_OF_SLAVES ) {
			leaderState.m_psSlavesInfo[leaderState.m_u8NumOfSlavesInNetwork].m_u8SlaveId = slaveData->m_u8NodeId;
			if( leaderState.m_u8NumOfSlavesInNetwork < 2 ) {
				leaderState.m_psSlavesInfo[leaderState.m_u8NumOfSlavesInNetwork].m_u8SlaveRole = SENSOR_STATE_SENSE;
			} else {
				leaderState.m_psSlavesInfo[leaderState.m_u8NumOfSlavesInNetwork].m_u8SlaveRole = SENSOR_STATE_STANDY;
			}
		}

		leaderState.m_sCurrentSlave.m_u8SlaveId = slaveData->m_u8NodeId;
		leaderState.m_sCurrentSlave.m_u8SlaveRole = leaderState.m_psSlavesInfo[leaderState.m_u8NumOfSlavesInNetwork].m_u8SlaveRole;

		leaderState.m_u8NumOfSlavesInNetwork++;

		post assign_role();
	}

	void addRoleToSlaves(void *data ) {
		slave_info_t *psSlavePkt = (slave_info_t*)data;
		if( TOS_NODE_ID == psSlavePkt->m_u8SlaveId ) {
			if( SENSOR_STATE_SENSE == psSlavePkt->m_u8SlaveRole ) {
				call Leds.led1On();
			} else if( SENSOR_STATE_STANDY == psSlavePkt->m_u8SlaveRole ) {
				call Leds.led2On();
			}
		}
	}

  	event void WaitTimer.fired() {
  		//call Leds.set(sensorState.m_u8LeaderId);
  		if( TOS_NODE_ID == sensorState.m_u8LeaderId ) {
  			//Send the confirmation mail to all other nodes.
  			//
  			sensorState.m_u8NodeRole = SENSOR_STATE_LEADER;
  			post multicast_requestNodeid();
  			call Leds.led0On();
  		} 
  	}
	
	task void multicast_requestNodeid() {
		// Get battery Level
		// Multicast it to all other nodes and wait for objection for 5 seconds 
		// If no objection within 5 seconds then send another confirmation package about it's election
		// Get confirmation from the network
		leader_selection_t *psLeaderPkt;
		header_t *psPktHeader;

		psPktHeader = (header_t*)settingsBuffer;
		psPktHeader->m_u8Type = MESSAGE_TYPE_LEADER_REQUEST_NODE_IDS;
		psPktHeader->m_u8PayloadSize = sizeof(leader_selection_t);

		psLeaderPkt = (leader_selection_t*) (settingsBuffer+sizeof(header_t));
		psLeaderPkt->m_u8BatteryLevel = sensorState.m_u8LeaderBatteryLevel;
		psLeaderPkt->m_u8NodeId = TOS_NODE_ID;

		call UserPacket.sendto(&multicast, settingsBuffer, psPktHeader->m_u8PayloadSize + sizeof(header_t));
	}

	task void replyNodeInfo() {
		slave_reply_t *psSlavePkt;
		header_t *psPktHeader;

		psPktHeader = (header_t*)settingsBuffer;
		psPktHeader->m_u8Type = MESSAGE_TYPE_LEADER_REPLY_NODE_IDS;
		psPktHeader->m_u8PayloadSize = sizeof(slave_reply_t);

		psSlavePkt = (slave_reply_t*) (settingsBuffer+sizeof(header_t));
		psSlavePkt->m_u8NodeId = TOS_NODE_ID;

		call UserPacket.sendto(&multicast, settingsBuffer, psPktHeader->m_u8PayloadSize + sizeof(header_t));

	}

	task void assign_role() {
		slave_info_t *psSlavePkt;
		header_t *psPktHeader;

		psPktHeader = (header_t*)settingsBuffer;
		psPktHeader->m_u8Type = MESSAGE_TYPE_LEADER_ASSIGN_ROLE;
		psPktHeader->m_u8PayloadSize = sizeof(slave_info_t);

		psSlavePkt = (slave_info_t*) (settingsBuffer+sizeof(header_t));
		memcpy( psSlavePkt, &leaderState.m_sCurrentSlave, sizeof(slave_info_t));

		call UserPacket.sendto(&multicast, settingsBuffer, psPktHeader->m_u8PayloadSize + sizeof(header_t));
	}
}

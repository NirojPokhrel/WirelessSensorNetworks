#include <lib6lowpan/ip.h>
#include "tolerant.h"
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
		interface Timer<TMilli> as SyncTimer;
		interface Timer<TMilli> as SenseTimer;
		interface Timer<TMilli> as VoltageSensing;
		interface Timer<TMilli> as DataCollectionTimer;

		interface Read<uint16_t> as LightPar;
	}
} implementation {
	task void multicast_leaderSelection();
	task void multicast_requestNodeid();
	task void replyNodeInfo();
	task void assign_role();
	task void sync_role();
	task void request_resendSyncRole();
	task void send_data();
	task void report_data_to_admin();

	void checkLeaderSelectionPkt( void *data );
	void replyNodeIdToLeader(void *data);
	void addSlaveToNetwork(void *data);
	void addRoleToSlaves(void *data );
	void syncRoles(void *data);

	void store_data(void *data);
	void add_node_for_storage( uint8_t pos, uint8_t node );
	void add_data( uint8_t node, uint16_t data );
	void check_data_sanity();
	void check_for_fault_tolerance();
	uint8_t start_standby_mode_to_sensing();
	void manage_fault_counter( int pos0, int pos1, int pos2);

	struct sockaddr_in6 route_dest;
	struct sockaddr_in6 multicast;

	//Niroj
	nx_uint8_t settingsBuffer[20];
	nx_uint8_t dataBuffer[20];
	uint8_t tempData[20];
	leader_selection_t leaderPkt;
	header_t pktHeader;
	sensor_state_t sensorState;
	leader_state_t leaderState;
	uint8_t u8Reset;


	nx_struct alarm_report reportAdmin;
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
		sensorState.m_u8NodePresent = 0;
		sensorState.m_u8NodePresent = setBit(sensorState.m_u8NodePresent, TOS_NODE_ID );

		leaderState.m_u8NumOfSlavesInNetwork = 0;
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
			if( !strcmp( argv[1], "help") ) {
				sprintf(retValue, "\nTry $debug [1...4].\n1=>Node Info\n2=>Sync Info\n3=>Leader Info\n4.Sensor Information[For Leader]\n");
			} else if( atoi(argv[1]) == 1 ) {
				sprintf(retValue, "\nNodeId=%d\nBatteryLevel=%d\nRequestId=%d\n", debugInfo.m_puLastPacket.m_u8NodeId, debugInfo.m_puLastPacket.m_u8BatteryLevel, debugInfo.m_puLastPacket.m_u8RequestId );
			} else if (atoi(argv[1]) == 2 ) {
				sprintf( retValue, "\nNodePresent=%d\nSense=%d\nStandby=%d\nFailure=%d\n", sensorState.m_u8NodePresent, sensorState.m_sSyncInfo.m_u8SenseRole, sensorState.m_sSyncInfo.m_u8StandyRole, sensorState.m_sSyncInfo.m_u8FailureRole );
			} else if ( atoi(argv[1] ) == 3 ) {
				sprintf( retValue, "\nLeaderId=%d\nLeaderBatteryLevel=%d\n", sensorState.m_u8LeaderId, sensorState.m_u8LeaderBatteryLevel );
			} else if ( atoi(argv[1] ) == 4 ) {
				sprintf( retValue, "\nAvg=%d\nS0=%d\nS1=%d\nS2=%d\n", sensorState.m_u16AverageData, debugInfo.m_u16Sensor0, debugInfo.m_u16Sensor1, debugInfo.m_u16Sensor2 );
			}
		} else {
			sprintf(retValue, "Try: $debug help\n" );
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
			case MESSAGE_TYPE_LEADER_ASSIGN_ROLE:
				if( sizeof(slave_info_t) == headerPtr->m_u8PayloadSize ) {
					addRoleToSlaves(tempData + sizeof(header_t));
				}
			break;
*/
			case MESSAGE_TYPE_LEADER_SYNC_ROLE:
				if( sizeof(sync_packet_t) == headerPtr->m_u8PayloadSize ) {
					syncRoles(tempData+sizeof(header_t));
				}
			break;
			case MESSAGE_TYPE_LEADER_SYNC_ROLE_RESEND:
				if( TOS_NODE_ID == sensorState.m_u8LeaderId ) {
					if( !headerPtr->m_u8PayloadSize ) {
  						post sync_role();
					}
				}
			break;
			case MESSAGE_TYPE_DATA_PACKET:
				//Process the data only if it is a leader
				if( TOS_NODE_ID == sensorState.m_u8LeaderId ) {
					if( sizeof(data_packet_t) == headerPtr->m_u8PayloadSize) {
						store_data(tempData+sizeof(header_t));
					}
				}
			break;

		}
	}

	void checkLeaderSelectionPkt( void *data ) {
		leader_selection_t *leaderSelectionData = (leader_selection_t*) data;

		memcpy( &debugInfo.m_puLastPacket, data, sizeof(leader_selection_t) );
		if( leaderSelectionData->m_u8NodeId > 7 )
			return;

		sensorState.m_u8NodePresent = setBit(sensorState.m_u8NodePresent, leaderSelectionData->m_u8NodeId );
		if( sensorState.m_u8LeaderBatteryLevel < leaderSelectionData->m_u8BatteryLevel) {
			sensorState.m_u8LeaderBatteryLevel = leaderSelectionData->m_u8BatteryLevel;
			sensorState.m_u8LeaderId = leaderSelectionData->m_u8NodeId;
		} else if ( sensorState.m_u8LeaderBatteryLevel == leaderSelectionData->m_u8BatteryLevel ) {
			if( TOS_NODE_ID > leaderSelectionData->m_u8NodeId ) {
				sensorState.m_u8LeaderId = leaderSelectionData->m_u8NodeId;
			}
		} 
		//Check if this is the first time without the failure node or is it with the failure leader. If the leader has failed then retry.
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

		//call Leds.led1On();
		if( TOS_NODE_ID == psSlavePkt->m_u8SlaveId ) {
			if( SENSOR_STATE_SENSE == psSlavePkt->m_u8SlaveRole ) {
				call Leds.led1On();
			} else if( SENSOR_STATE_STANDY == psSlavePkt->m_u8SlaveRole ) {
				call Leds.led2On();
			}
		}
	}

	void syncRoles(void *data) {
		memcpy( &sensorState.m_sSyncInfo, data, sizeof(sync_packet_t));

		if( getBit(sensorState.m_sSyncInfo.m_u8SenseRole, TOS_NODE_ID) ) {
			call Leds.led1On();
			call Leds.led0Off();
			call Leds.led2Off();
			call SenseTimer.startPeriodic(3000);
			//call VoltageSensing.startOneShot(20000);
			//Wait for 20 seconds to be contacted from the leader otherwise select the next leader and proceed.
		} else if( getBit(sensorState.m_sSyncInfo.m_u8StandyRole, TOS_NODE_ID) ) {
			call Leds.led2On();
		} else if( getBit(sensorState.m_sSyncInfo.m_u8FailureRole, TOS_NODE_ID ) ) {
			call Leds.set(7);
			call SenseTimer.stop();
			//Stop sensing
		}
	}

	void leader_assign_role() {
		uint8_t i, count = 0;

		memset(&sensorState.m_sSyncInfo, 0, sizeof(sync_packet_t));
		memset(&sensorState.m_sStorageData, 0, sizeof(data_storage_t));

		add_node_for_storage( 0, TOS_NODE_ID);
		for( i=2; i<8; i++ ) {
			if( i == TOS_NODE_ID ) 
				continue;
			if(getBit(sensorState.m_u8NodePresent, i)) {
				sensorState.m_sSyncInfo.m_u8SenseRole = setBit(sensorState.m_sSyncInfo.m_u8SenseRole, i);
				count++;
				add_node_for_storage(count,i);
				if( count >= 2 ) {
					i++;
					break;
				}
			}
		}

		for( ; i<8; i++ ) {
			if( i == TOS_NODE_ID ) 
				continue;
			if(getBit(sensorState.m_u8NodePresent, i)) {
				sensorState.m_sSyncInfo.m_u8StandyRole = setBit(sensorState.m_sSyncInfo.m_u8StandyRole, i);
			}
		}
	}

	void store_data(void *data) {
		uint8_t nodeId;
		uint16_t sensorData;
		data_packet_t *psDataPkt;

		psDataPkt = (data_packet_t*) data;
		nodeId = psDataPkt->m_u8NodeId;
		sensorData = psDataPkt->m_u16Data;

		add_data(nodeId, sensorData);
	}

	void add_node_for_storage( uint8_t pos, uint8_t node ) {
		//New node is being added in the network
		sensorState.m_sStorageData.m_u8NodeId[pos] = node;
		sensorState.m_sStorageData.m_u8NewNode[pos] = 1;
	}

	void add_data( uint8_t node, uint16_t data ) {
		uint8_t i=0;

		for( ;i<3; i++ ) {
			if( sensorState.m_sStorageData.m_u8NodeId[i] == node ) {
				sensorState.m_sStorageData.m_u16Data[i] = data;
				sensorState.m_sStorageData.m_u8DataAvail[i] = 1;
				break;
			}
		}

		if( 3 == i ) {
		//Something has gone wrong maybe the failure node has not got the sync packet 
			post sync_role();
		}
	}

	void manage_fault_counter( int pos0, int pos1, int pos2) {
		if( pos0 ) {
			sensorState.m_sStorageData.m_u16FailureCount[0]++;
		} else {
			sensorState.m_sStorageData.m_u16FailureCount[0] = 0;
		}
		if( pos1 ) {
			sensorState.m_sStorageData.m_u16FailureCount[1]++;
		} else {
			sensorState.m_sStorageData.m_u16FailureCount[1] = 0;
		}
		if( pos2 ) {
			sensorState.m_sStorageData.m_u16FailureCount[2]++;
		} else {
			sensorState.m_sStorageData.m_u16FailureCount[2] = 0;
		}
	}

	uint8_t start_standby_mode_to_sensing() {
		int pos;

		pos = getNextSetBit(sensorState.m_sSyncInfo.m_u8StandyRole);
		if( 8 == pos ) {
			//No more extra sensor to replace so disable the network
			sensorState.m_sSyncInfo.m_u8StandyRole = resetBit(sensorState.m_sSyncInfo.m_u8StandyRole, pos);
			//Entire network fails!!!
			memset( &sensorState.m_sSyncInfo.m_u8FailureRole, 1, 1);
		} else {
			sensorState.m_sSyncInfo.m_u8SenseRole = setBit(sensorState.m_sSyncInfo.m_u8SenseRole, pos);
		}

		return pos;
	}

	void check_for_fault_tolerance() {
		int i=0, node_id;
		for( ; i<3; i++ ) {
			if( sensorState.m_sStorageData.m_u16FailureCount[i] > 5 ) {
				//Some node has failed. Try to reset this node and do something !!!!
				//Get a node from the standby mode and make it active !!!
				if( sensorState.m_sStorageData.m_u8NewNode[i] ) {
					//Implicit Watchdog approach. If no new node is received send the sync role packet for all the node to sync up again.
					post sync_role();
					return;
				}

				sensorState.m_sSyncInfo.m_u8SenseRole = resetBit(sensorState.m_sSyncInfo.m_u8SenseRole, sensorState.m_sStorageData.m_u8NodeId[i]);
				sensorState.m_sSyncInfo.m_u8FailureRole = setBit(sensorState.m_sSyncInfo.m_u8FailureRole, sensorState.m_sStorageData.m_u8NodeId[i]);
				node_id = start_standby_mode_to_sensing();
				if( 8 == node_id ) {
					//RETURN ERROR. No more valid 
					return;
				}
				add_node_for_storage( i, node_id );
				memset(&sensorState.m_sStorageData.m_u16FailureCount, 0, sizeof(sensorState.m_sStorageData.m_u16FailureCount));

				post sync_role();
				if( TOS_NODE_ID == pos ) {
					//The leader has failed itself do something here !!!
				}

				break;
			}

		}
	}

	void check_data_sanity() {
		uint8_t i=0, a1=0, a2=0, a3=0;
		uint8_t fault_pos0 = 0, fault_pos1 = 0, fault_pos2 = 0;
		uint16_t u16Average = 0;

		for( ; i<3; i++ ) {
			if( sensorState.m_sStorageData.m_u8DataAvail[i] != 1 ) {
				//Increase Data Absence bit 
				sensorState.m_sStorageData.m_u16Data[i] = 0xFFFF;
				//Check if it is first time of the node and it has not started yet then make sure to resend the sync signals again
			} else {
				sensorState.m_sStorageData.m_u8NewNode[i] = 0;
			}
		}

		if( get_absolute( sensorState.m_sStorageData.m_u16Data[0] - sensorState.m_sStorageData.m_u16Data[1] ) > 100 ) {
			a1 = 1;
		}

		if( get_absolute( sensorState.m_sStorageData.m_u16Data[1] - sensorState.m_sStorageData.m_u16Data[2] ) > 100 ) {
			a2 = 1;
		}

		if( get_absolute( sensorState.m_sStorageData.m_u16Data[0] - sensorState.m_sStorageData.m_u16Data[2] ) > 100 ) {
			a3 = 1;
		}
		if( a1 && a2 && a3 ) {
			//All nodes have failed
			u16Average = 0;
			fault_pos0 = 1;
			fault_pos1 = 1;
			fault_pos2 = 1;
		} else if( a1 && a3 ) {
			//0 has failed
			u16Average = (sensorState.m_sStorageData.m_u16Data[1] + sensorState.m_sStorageData.m_u16Data[2])>>1;
			fault_pos0 = 1;
		} else if( a2 && a3 ) {
			//2 has failed
			u16Average = (sensorState.m_sStorageData.m_u16Data[0] + sensorState.m_sStorageData.m_u16Data[1])>>1;
			fault_pos2 = 1;
		} else if( a1 && a2 ) {
			//1 has failed
			u16Average = (sensorState.m_sStorageData.m_u16Data[0] + sensorState.m_sStorageData.m_u16Data[2])>>1;
			fault_pos1 = 1;
		} else if( a1 || a2 || a3 ) {
			//Some anomaly is occuring
			u16Average = (sensorState.m_sStorageData.m_u16Data[0] + sensorState.m_sStorageData.m_u16Data[1] + sensorState.m_sStorageData.m_u16Data[2] )/3;
		} else {
			//Send average of three
			u16Average = (sensorState.m_sStorageData.m_u16Data[0] + sensorState.m_sStorageData.m_u16Data[1] + sensorState.m_sStorageData.m_u16Data[2] )/3;
		}
		sensorState.m_u16AverageData = u16Average;
		memset( &sensorState.m_sStorageData.m_u8DataAvail, 0, sizeof(sensorState.m_sStorageData.m_u8DataAvail));
		manage_fault_counter(fault_pos0, fault_pos1, fault_pos2 );
		check_for_fault_tolerance();
#if ENABLE_DEBUG
		debugInfo.m_u16Sensor0 = sensorState.m_sStorageData.m_u16Data[0];
		debugInfo.m_u16Sensor1 = sensorState.m_sStorageData.m_u16Data[1];
		debugInfo.m_u16Sensor2 = sensorState.m_sStorageData.m_u16Data[2];
#endif
		post report_data_to_admin();
	}

	event void LightPar.readDone(error_t e, uint16_t val) {
		sensorState.m_u16LighPar = val;
		if( TOS_NODE_ID != sensorState.m_u8LeaderId ) {
			post send_data();
		} else {
			add_data(TOS_NODE_ID, val);
		}
	}

  	event void WaitTimer.fired() {
  		//call Leds.set(sensorState.m_u8LeaderId);
  		if( TOS_NODE_ID == sensorState.m_u8LeaderId ) {
  			//Send the confirmation mail to all other nodes.
  			//
  			sensorState.m_u8NodeRole = SENSOR_STATE_LEADER;
  			//post multicast_requestNodeid();
  			leader_assign_role();
  			post sync_role();
  			call Leds.led0On();
			call SenseTimer.startPeriodic(3000);
			call DataCollectionTimer.startPeriodic(5000);
  		} else {
  			call SyncTimer.startOneShot(2000);
  		}
  	}

  	event void SyncTimer.fired() {
  		if(!sensorState.m_sSyncInfo.m_u8SenseRole) {
  			post request_resendSyncRole();
  		} 
  	}

  	event void SenseTimer.fired() {
		call LightPar.read();
  	}

  	event void VoltageSensing.fired() {

  	}

  	event void DataCollectionTimer.fired() {
  		check_data_sanity();
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

	task void sync_role() {
		sync_packet_t *psSyncPkt;
		header_t *psPktHeader;

		psPktHeader = (header_t*)settingsBuffer;
		psPktHeader->m_u8Type = MESSAGE_TYPE_LEADER_SYNC_ROLE;
		psPktHeader->m_u8PayloadSize = sizeof(sync_packet_t);

		psSyncPkt = (sync_packet_t*) (settingsBuffer+sizeof(header_t));
		memcpy( psSyncPkt, &sensorState.m_sSyncInfo, sizeof(sync_packet_t));
		call UserPacket.sendto(&multicast, settingsBuffer, psPktHeader->m_u8PayloadSize + sizeof(header_t));
	}

	task void request_resendSyncRole() {
		header_t *psPktHeader;

		psPktHeader = (header_t*)settingsBuffer;
		psPktHeader->m_u8Type = MESSAGE_TYPE_LEADER_SYNC_ROLE_RESEND;
		psPktHeader->m_u8PayloadSize = 0;

		call UserPacket.sendto(&multicast, settingsBuffer, sizeof(header_t));
	}

	task void send_data() {
		data_packet_t *psDataPkt;
		header_t *psPktHeader;

		psPktHeader = (header_t*)dataBuffer;
		psPktHeader->m_u8Type = MESSAGE_TYPE_DATA_PACKET;
		psPktHeader->m_u8PayloadSize = sizeof(data_packet_t);

		psDataPkt = (data_packet_t*) (dataBuffer+sizeof(header_t));
		psDataPkt->m_u8NodeId = TOS_NODE_ID;
		psDataPkt->m_u16Data = sensorState.m_u16LighPar;
		call UserPacket.sendto(&multicast, dataBuffer, psPktHeader->m_u8PayloadSize + sizeof(header_t));
	}

	task void report_data_to_admin() {
		reportAdmin.node_id = TOS_NODE_ID;
		reportAdmin.sensor_value = sensorState.m_u16AverageData;

		call UserPacket.sendto(&route_dest, &reportAdmin, sizeof(reportAdmin));
	}
}

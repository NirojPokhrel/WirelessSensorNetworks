#ifndef TOLERANT_H_
#define TOLERANT_H_

#include <IPDispatch.h>
#include "sensing.h"
#define MAX_NUMBER_OF_SLAVES 8
#define ENABLE_DEBUG 1
#define NEW_SENSOR_START 2
enum {
  SENSOR_STATE_LEADER = 50,
  SENSOR_STATE_SENSE = 51,
  SENSOR_STATE_STANDY = 52,
  SENSOR_STATE_FAIL = 53,
  SENSOR_SLAVE_ROLE_SENSE = 60,
  SENSOR_SLAVE_ROLE_STANDY = 61,
  MESSAGE_TYPE_LEADER_SELECTION = 110,
  MESSAGE_TYPE_LEADER_REQUEST_NODE_IDS = 111,
  MESSAGE_TYPE_LEADER_REPLY_NODE_IDS = 112,
  MESSAGE_TYPE_LEADER_ASSIGN_ROLE = 113,
  MESSAGE_TYPE_LEADER_SYNC_ROLE = 114,
  MESSAGE_TYPE_LEADER_SYNC_ROLE_RESEND = 115,
  MESSAGE_TYPE_REQUEST_PACKET = 116,
  MESSAGE_TYPE_DATA_PACKET = 117,
};

typedef nx_struct settings {
  nx_uint16_t voltage_period;
  nx_uint16_t voltage_threshold;
} settings_t;

typedef nx_struct header {
	nx_uint8_t m_u8Type;
	nx_uint8_t m_u8PayloadSize;
} header_t;

typedef nx_struct setting_packet {
	nx_uint8_t m_u8LeaderId;
	nx_uint8_t m_u8State;
}packet_t;


typedef struct syncPacket {
	uint8_t m_u8SenseRole;
	uint8_t m_u8StandyRole;
	uint8_t m_u8FailureRole;
} sync_packet_t;

typedef struct dataPacket {
	nx_uint8_t m_u8NodeId;
	nx_uint16_t m_u16Data;
} data_packet_t;

typedef struct dataStorage {
	uint8_t m_u8DataAvail[3];
	uint8_t m_u8NodeId[3];
	uint8_t m_u8NewNode[3];
	uint16_t m_u16Data[3];
	uint16_t m_u16FailureCount[3];
} data_storage_t;

typedef struct sensor_state { 
	uint8_t m_u8CurrentState;
	uint8_t m_u8NodeRole;
	uint8_t m_u8LeaderId;
	uint8_t m_u8BatteryLevel;
	uint8_t m_u8LeaderBatteryLevel;
	uint8_t m_u8LastRequest;
	uint8_t m_u8NodePresent;
	uint16_t m_u16LighPar;
	uint16_t m_u16AverageData;
	sync_packet_t m_sSyncInfo;
	data_storage_t m_sStorageData;
} sensor_state_t;

typedef struct slaveinfo {
	uint8_t m_u8SlaveId;
	uint8_t m_u8SlaveRole;
} slave_info_t;

typedef struct leader_state {
	uint8_t m_u8NumOfSlavesInNetwork;
	slave_info_t m_sCurrentSlave;
	slave_info_t m_psSlavesInfo[MAX_NUMBER_OF_SLAVES];
} leader_state_t;

typedef struct leaderSelectionState {
	nx_uint8_t m_u8BatteryLevel;
	nx_uint8_t m_u8NodeId;
	nx_uint8_t m_u8RequestId;
} leader_selection_t;

typedef struct slaveReplyState {
	nx_uint8_t m_u8NodeId;
} slave_reply_t;

#if ENABLE_DEBUG
typedef struct debugInfo {
	uint16_t m_u16Sensor0;
	uint16_t m_u16Sensor1;
	uint16_t m_u16Sensor2;
	uint16_t m_u16TestLevel;
	leader_selection_t m_puLastPacket;
} debug_info_t;
#endif

//Utility Functions
uint8_t getBit( uint8_t val, uint8_t pos ) {
	if( val & (1<<pos) ) {
		return 1;
	}

	return 0;
}

uint8_t getNextSetBit( uint8_t val ) {
	int i=0;

	for( ; i<8; i++ ) {
		if( val & (1<<i) ) {
			return i;
		}
	}

	return 8;
}

uint8_t setBit( uint8_t val, uint8_t pos ) {
	return (val|(1<<pos));
}

uint8_t resetBit( uint8_t val, uint8_t pos ) {
	return ( val & (~(1<<pos)));
}

uint8_t numSetBit( uint8_t val ) {
	uint8_t count = 0, i=0;
	for( ;i<8; i++ ) {
		if( val & (1<<i)) {
			count++;
		}
	}
	return count;
}

int get_absolute( int num ) {
	return num<0?-num:num;
}

#define REPORT_DEST "fec0::100"
#define MULTICAST "ff02::1"
#endif

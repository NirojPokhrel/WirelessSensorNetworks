#ifndef SENSING_H_
#define SENSING_H_

#include <IPDispatch.h>
#define MAX_NUMBER_OF_SLAVES 8
#define ENABLE_DEBUG 1
enum {
  AM_SENSING_REPORT = -1,
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
  MESSAGE_TYPE_LEADER_REJECTION = 113,
};

nx_struct sensing_report {
  nx_uint16_t seqno;
  nx_uint16_t sender;
  nx_uint16_t voltage;
} ;

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

typedef struct sensor_state { 
	uint8_t m_u8CurrentState;
	uint8_t m_u8NodeRole;
	uint8_t m_u8LeaderId;
	uint8_t m_u8BatteryLevel;
	uint8_t m_u8LeaderBatteryLevel;
	uint8_t m_u8LastRequest;
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

typedef struct syncPacket {
	uint8_t m_u8NodeRole;
	uint8_t m_u8FailureNode;
} sync_packet_t;

int getBit( uint8_t val, uint8_t pos ) {
	if( val & (1<<pos) ) {
		return 1;
	}

	return 0;
}

int setBit( uint8_t val, uint8_t pos ) {
	return (val|(1<<pos));
}
#if ENABLE_DEBUG
typedef struct debugInfo {
	uint8_t m_u8NumberOfPackets;
	uint8_t m_u8CountNodeTwo;
	uint8_t m_u8CountNodeThree;
	uint8_t m_u8CountNodeFour;
	uint8_t m_u8CountNothing;
	leader_selection_t m_puLastPacket;
} debug_info_t;
#endif

#define REPORT_DEST "fec0::100"
#define MULTICAST "ff02::1"
#endif

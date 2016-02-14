#ifndef SENSING_H_
#define SENSING_H_

#include <IPDispatch.h>
#define MAX_NUMBER_OF_SLAVES 10
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
} leader_selection_t;

typedef struct slaveReplyState {
	nx_uint8_t m_u8NodeId;
} slave_reply_t;


#define REPORT_DEST "fec0::100"
#define MULTICAST "ff02::1"
char arr[10][10] = { "fec0::2", "fec0::3", "fec0::4", "fec0::5", "fec0::6", "fec0::7", "fec0::8", "fec0::9", "fec0::10", "fec0::11" };
#endif

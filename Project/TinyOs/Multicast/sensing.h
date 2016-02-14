#ifndef SENSING_H_
#define SENSING_H_

#include <IPDispatch.h>

enum {
  AM_SENSING_REPORT = -1,
  SENSOR_STATE_WAIT = 50,
  SENSOR_STATE_SENSING = 51,
  SENSOR_STATE_STANDY = 52,
  SENSOR_STATE_FAIL = 53,
  SENSOR_ROLE_LEADER = 60,
  SENSOR_ROLE_FOLLOWER = 61,
  MESSAGE_TYPE_LEADER_SELECTION = 110,
  MESSAGE_TYPE_LEADER_REJECTION = 111,
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

typedef struct state { 
	uint8_t m_u8CurrentState;
	uint8_t m_u8NodeRole;
	uint8_t m_u8LeaderId;
	uint8_t m_u8BatteryLevel;
	uint8_t m_u8LeaderBatteryLevel;
} sensor_state_t;

typedef struct leaderSelectionState {
	nx_uint8_t m_u8BatteryLevel;
	nx_uint8_t m_u8NodeId;
} leader_selection_t;

void deCompressSrcDstNode(uint8_t arr[2], uint8_t compressed ) { 
	arr[0] = compressed & 0x0f; //Src Id
	arr[1] = (compressed >> 4) & 0xf0; //Dst Id
}

uint8_t compressSrcDst( uint8_t u8Src, uint8_t u8Dst ) { 
	return ((u8Src & 0x0f)|((u8Dst<<4)& 0xf0));
}

#define REPORT_DEST "fec0::100"
#define MULTICAST "ff02::1"

#endif

#ifndef SENSiNG_H_
#define SENSiNG_H_


enum {
  AM_SENSING_REPORT = -1,
 };

nx_struct alarm_report {
  nx_uint16_t node_id;;
  nx_uint16_t sensor_value;
  nx_uint8_t leader_id;
  nx_uint8_t failed_node;
} ;

#endif
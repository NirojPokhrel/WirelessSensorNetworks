#ifndef SENSING_H_
#define SENSING_H_

#include <IPDispatch.h>

enum {
  AM_SENSING_REPORT = -1
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

#define REPORT_DEST "fec0::100"
#define MULTICAST "ff02::1"

#endif

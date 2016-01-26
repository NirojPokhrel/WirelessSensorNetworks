#ifndef SENSING_H_
#define SENSING_H_
#define USE_TEMPERATURE_SENSOR
enum {
      AM_THEFT_REPORT = -1
};

nx_struct alarm_report {
  nx_uint16_t source;
} ;

typedef nx_struct settings {
	nx_uint16_t threshold;
	nx_uint32_t sample_time;
	nx_uint32_t sample_period;
} settings_t;

nx_struct settings_report {
	nx_uint16_t sender;
	nx_uint8_t type;
	settings_t  settings;
};
#define REPORT_DEST "fec0::100"
#define MULTICAST "ff02::1"

#endif

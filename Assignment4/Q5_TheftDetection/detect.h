#ifndef SENSING_H_
#define SENSING_H_

enum {
      AM_THEFT_REPORT = -1
};

nx_struct theft_report {
  nx_uint16_t seqno;
  nx_uint16_t pos_x;
  nx_uint16_t pos_y;
  nx_uint16_t item_type;
} ;

#define REPORT_DEST "fec0::100"

#endif

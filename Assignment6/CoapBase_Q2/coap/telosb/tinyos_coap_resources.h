#ifndef _COAP_TINYOS_COAP_RESOURCES_H_
#define _COAP_TINYOS_COAP_RESOURCES_H_

#include <tinyos_coap_defs.h>

//predefined resources

enum {

#ifdef COAP_RESOURCE_DEFAULT
    INDEX_DEFAULT,
#endif
#ifdef COAP_RESOURCE_TEMP
    INDEX_TEMP,
#endif
#ifdef COAP_RESOURCE_HUM
    INDEX_HUM,
#endif
#ifdef COAP_RESOURCE_LED
    INDEX_LED,
#endif
#ifdef COAP_RESOURCE_ROUTE
    INDEX_ROUTE,
#endif
#ifdef COAP_RESOURCE_BASE_LEDS
    INDEX_BASE_LEDS,
#endif
#ifdef COAP_RESOURCE_BUTTON_COUNTER
    INDEX_BASE_BUTTON_COUNTER,
#endif

    COAP_LAST_RESOURCE,
    COAP_NO_SUCH_RESOURCE = 0xff
};




index_uri_key_t uri_index_map[COAP_LAST_RESOURCE] = {
#ifdef COAP_RESOURCE_DEFAULT
  {
      INDEX_DEFAULT,
      "", sizeof(""),
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED | PUT_SUPPORTED | POST_SUPPORTED | DELETE_SUPPORTED),
      0
  },
#endif
#if defined (COAP_RESOURCE_TEMP) || defined (COAP_RESOURCE_ALL)
  {
      INDEX_TEMP,
      "st", sizeof("st"),
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      GET_SUPPORTED,
      0
  },
#endif
#if defined (COAP_RESOURCE_HUM) || defined (COAP_RESOURCE_ALL)
  {
      INDEX_HUM,
      "sh", sizeof("sh"),
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      GET_SUPPORTED,
      0
  },
#endif
#ifdef COAP_RESOURCE_LED
  {
      INDEX_LED,
      "l", sizeof("l"),
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED | PUT_SUPPORTED),
      1
  },
#endif
#ifdef COAP_RESOURCE_ROUTE
  {
      INDEX_ROUTE,
      "rt", sizeof("rt"),
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      GET_SUPPORTED,
      0
  },
#endif
#ifdef COAP_RESOURCE_BASE_LEDS
  {
      INDEX_BASE_LEDS,
      "leds", sizeof("leds"),
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED | PUT_SUPPORTED),
      0
  },
#endif
#ifdef COAP_RESOURCE_BUTTON_COUNTER
  {
      INDEX_BASE_BUTTON_COUNTER,
      "count", sizeof("count"),
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED | PUT_SUPPORTED | POST_SUPPORTED),
      1
  },
#endif
};


#endif

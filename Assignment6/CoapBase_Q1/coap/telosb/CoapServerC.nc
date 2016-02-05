#include <iprouting.h>

#include "tinyos_coap_resources.h"

configuration CoapServerC {

} implementation {
  components MainC;
  components LedsC;
  components CoapServerP;
  components LibCoapAdapterC;
  components IPStackC;

  CoapServerP.Boot -> MainC;

#ifdef COAP_SERVER_ENABLED
  components CoapUdpServerC;
  components new UdpSocketC() as UdpServerSocket;
  CoapServerP.CoAPServer -> CoapUdpServerC;
  CoapUdpServerC.LibCoapServer -> LibCoapAdapterC.LibCoapServer;
  LibCoapAdapterC.UDPServer -> UdpServerSocket;


#if defined (COAP_RESOURCE_TEMP)  || defined (COAP_RESOURCE_HUM) 
  components new SensirionSht11C() as HumTempSensor;
#endif

#ifdef COAP_RESOURCE_TEMP
  components new CoapReadResourceC(uint16_t, INDEX_TEMP) as CoapReadTempResource;
  components new CoapBufferTempTranslateC() as CoapBufferTempTranslate;
  CoapReadTempResource.Read -> CoapBufferTempTranslate.ReadTemp;
  CoapBufferTempTranslate.Read -> HumTempSensor.Temperature;
  CoapUdpServerC.CoapResource[INDEX_TEMP] -> CoapReadTempResource.CoapResource;
#endif

#ifdef COAP_RESOURCE_HUM
  components new CoapReadResourceC(uint16_t, INDEX_HUM) as CoapReadHumResource;
  components new CoapBufferHumTranslateC() as CoapBufferHumTranslate;
  CoapReadHumResource.Read -> CoapBufferHumTranslate.ReadHum;
  CoapBufferHumTranslate.Read -> HumTempSensor.Humidity;
  CoapUdpServerC.CoapResource[INDEX_HUM] -> CoapReadHumResource.CoapResource;
#endif

#ifdef COAP_RESOURCE_LED
  components new CoapLedResourceC(INDEX_LED) as CoapLedResource;
  CoapLedResource.Leds -> LedsC;
  CoapUdpServerC.CoapResource[INDEX_LED]  -> CoapLedResource.CoapResource;
#endif

#ifdef COAP_RESOURCE_ROUTE
  components new CoapRouteResourceC(uint16_t, INDEX_ROUTE) as CoapReadRouteResource;
  CoapReadRouteResource.ForwardingTable -> IPStackC;
  CoapUdpServerC.CoapResource[INDEX_ROUTE] -> CoapReadRouteResource.CoapResource;
#endif

#ifdef COAP_RESOURCE_BASE_LEDS
  components new CoapBaseLedResourceC(INDEX_BASE_LEDS) as CoapBaseLedResource;
  CoapBaseLedResource.Leds -> LedsC;
  CoapUdpServerC.CoapResource[INDEX_BASE_LEDS]  -> CoapBaseLedResource.CoapResource;
#endif

#ifdef COAP_RESOURCE_BUTTON_COUNTER
  components new CoapBaseBtnCountResourceC(INDEX_BASE_BUTTON_COUNTER) as CoapBaseButtonCounter;
  CoapUdpServerC.CoapResource[INDEX_BASE_BUTTON_COUNTER]  -> CoapBaseButtonCounter.CoapResource;
#endif

#endif

  }

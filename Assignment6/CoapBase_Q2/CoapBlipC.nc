#include <iprouting.h>

configuration CoapBlipC {

} implementation {
  components MainC;
  components LedsC;
  components CoapBlipP;
  components IPStackC;
//  components UDPShellC;

  CoapBlipP.Boot -> MainC;
  CoapBlipP.Leds -> LedsC;
  CoapBlipP.RadioControl ->  IPStackC;

#ifdef IN6_PREFIX
 components StaticIPAddressTosIdC;
#endif

#ifdef RPL_ROUTING
  components RPLRoutingC;
#endif

  components CoapServerC;

  }

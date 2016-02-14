#include "StorageVolumes.h"

configuration SensingC {

} implementation {
	components MainC, LedsC, SensingP;
	SensingP.Boot -> MainC;
	SensingP.Leds -> LedsC;

	components IPStackC;
	components RPLRoutingC;
	components StaticIPAddressTosIdC;
	SensingP.RadioControl -> IPStackC;

	components UdpC;
	components new UdpSocketC() as UserPacket;
	SensingP.UserPacket -> UserPacket;

	components UDPShellC;

	components new ShellCommandC("start") as StartNwrkCmd;
	SensingP.StartNwrkCmd -> StartNwrkCmd;


	components new TimerMilliC() as WaitTimer;
	SensingP.WaitTimer -> WaitTimer;
}

#include "StorageVolumes.h"
#include "sensing.h"

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
#if ENABLE_DEBUG
	components new ShellCommandC("debug") as DebugCmd;
	SensingP.DebugCmd -> DebugCmd;
#endif

	components new TimerMilliC() as WaitTimer;
	SensingP.WaitTimer -> WaitTimer;
}

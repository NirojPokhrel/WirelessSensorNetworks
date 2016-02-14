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
	components new TimerMilliC() as SyncTimer;
	SensingP.SyncTimer -> SyncTimer;
	components new TimerMilliC() as SenseTimer;
	SensingP.SenseTimer -> SenseTimer;
	components new TimerMilliC() as WatchDogTimer;
	SensingP.WatchDogTimer -> WatchDogTimer;
}

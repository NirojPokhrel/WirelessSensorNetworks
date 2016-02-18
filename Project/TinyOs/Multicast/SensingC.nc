#include "StorageVolumes.h"
#include "tolerant.h"

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
	components new TimerMilliC() as VoltageSensing;
	SensingP.VoltageSensing -> VoltageSensing;
	components new TimerMilliC() as DataCollectionTimer;
	SensingP.DataCollectionTimer -> DataCollectionTimer;

	
	components new HamamatsuS1087ParC() as SensorPar;
	SensingP.LightPar -> SensorPar;
}

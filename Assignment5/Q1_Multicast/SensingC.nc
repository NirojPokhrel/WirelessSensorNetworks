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
	components new UdpSocketC() as VoltSend;
	SensingP.VoltSend -> VoltSend;
	components new UdpSocketC() as Settings;
	SensingP.Settings -> Settings;

	components UDPShellC;
	components new ShellCommandC("get") as GetCmd;
	components new ShellCommandC("set") as SetCmd;
	SensingP.GetCmd -> GetCmd;
	SensingP.SetCmd -> SetCmd;

	components new VoltageC();
	SensingP.Volt -> VoltageC.Read;

	components new TimerMilliC() as VoltTimer;
	SensingP.VoltTimer -> VoltTimer;

	components new ConfigStorageC(VOLUME_CONFIG) as VoltSettings;
	SensingP.ConfigMount -> VoltSettings;
	SensingP.ConfigStorage -> VoltSettings;
}

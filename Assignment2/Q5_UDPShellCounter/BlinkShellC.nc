configuration BlinkShellC {
}
implementation {

	components MainC, BlinkShellP, LedsC;
	BlinkShellP.Boot -> MainC.Boot;
  BlinkShellP.Leds -> LedsC;

	components IPStackC;
	components UDPShellC;
	components RPLRoutingC;
	components StaticIPAddressTosIdC;

	BlinkShellP.RadioControl -> IPStackC;

	components new ShellCommandC("count") as CountCmd;
	BlinkShellP.CountCmd -> CountCmd;

}

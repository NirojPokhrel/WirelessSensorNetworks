#define NEW_PRINTF_SEMANTICS
#define USE_TEMPERATURE_SENSOR
configuration LightC {
}
implementation {

	components MainC, LightP, LedsC;
	LightP -> MainC.Boot;
	LightP.Leds -> LedsC;
	components IPStackC;
	components IPDispatchC;
	components UdpC;
	components UDPShellC;
	components RPLRoutingC;;

	components StaticIPAddressTosIdC;

	LightP.RadioControl -> IPStackC;

	components new ShellCommandC("set") as SetCmd;
	LightP.SetCmd -> SetCmd;

	components new ShellCommandC("get") as GetCmd;
	LightP.GetCmd -> GetCmd;

	components new TimerMilliC() as SensorReadTimer;
	LightP.SensorReadTimer -> SensorReadTimer;

	components new TimerMilliC() as InitialWaitTimer;
	LightP.InitialWaitTimer -> InitialWaitTimer;
#if defined(USE_LIGHT_SENSOR)
	components new HamamatsuS1087ParC() as SensorPar;
	LightP.StreamPar -> SensorPar.ReadStream;
#else if defined(USE_TEMPERATURE_SENSOR)
	components new  SensirionSht11C() as TemperateHumiditySensor;
	LightP.ReadTemp -> TemperateHumiditySensor.Temperature;
#endif
	components new UdpSocketC() as SenseSend;
	LightP.SenseSend -> SenseSend;
	
	components new UdpSocketC() as Settings;
	LightP.Settings -> Settings;

	components new UdpSocketC() as ReportDst;
	LightP.ReportDst -> ReportDst;
#ifdef PRINTFUART_ENABLED
  /* This component wires printf directly to the serial port, and does
   * not use any framing.  You can view the output simply by tailing
   * the serial device.  Unlike the old printfUART, this allows us to
   * use PlatformSerialC to provide the serial driver.
   *
   * For instance:
   * $ stty -F /dev/ttyUSB0 115200
   * $ tail -f /dev/ttyUSB0
  */
  components SerialPrintfC;

  /* This is the alternative printf implementation which puts the
   * output in framed tinyos serial messages.  This lets you operate
   * alongside other users of the tinyos serial stack.
   */
  // components PrintfC;
  // components SerialStartC;
#endif
}

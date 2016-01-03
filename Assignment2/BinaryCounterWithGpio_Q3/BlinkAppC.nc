
configuration BlinkAppC
{
}
implementation
{
  components BlinkC, MainC;
  components new TimerMilliC() as Timer0;
  components HplMsp430GeneralIOC as GeneralIOC;
  components new Msp430GpioC() as MyLed;

  MyLed -> GeneralIOC.Port55; 
  
  BlinkC.Led1 -> MyLed;
  BlinkC.Boot -> MainC.Boot;

  BlinkC.Timer0 -> Timer0;
}



configuration BlinkAppC
{
}
implementation
{
  components BlinkC, MainC;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;
  components HplMsp430GeneralIOC as GeneralIOC;
  components new Msp430GpioC() as Led0;
  components new Msp430GpioC() as Led1;
  components new Msp430GpioC() as Led2;

  Led0 -> GeneralIOC.Port54; 
  Led1 -> GeneralIOC.Port55;
  Led2 -> GeneralIOC.Port56;  
  
  BlinkC.Led0 -> Led0;
  BlinkC.Led1 -> Led1;
  BlinkC.Led2 -> Led2;
  BlinkC.Boot -> MainC.Boot;

  BlinkC.Timer0 -> Timer0;
  BlinkC.Timer1 -> Timer1;
  BlinkC.Timer2 -> Timer2;
}


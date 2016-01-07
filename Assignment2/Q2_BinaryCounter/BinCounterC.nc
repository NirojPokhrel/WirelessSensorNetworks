configuration BinCounterC
{
	provides interface BinCounter;
}
implementation
{
  //Do we need MainC here ??
  components MainC, BinCounterImpl, LedsC;
  components new TimerMilliC() as Timer0;
  BinCounterImpl.BinCounter = BinCounter;
  BinCounterImpl.Timer0 -> Timer0;
  BinCounterImpl.Leds -> LedsC;
}


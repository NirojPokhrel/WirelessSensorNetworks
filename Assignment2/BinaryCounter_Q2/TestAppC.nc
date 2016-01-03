
configuration TestAppC
{
}
implementation
{
  components MainC, TestAppImpl, LedsC, BinCounterC;

  TestAppImpl.Boot -> MainC.Boot;
  TestAppImpl.BinCounter -> BinCounterC.BinCounter;


}
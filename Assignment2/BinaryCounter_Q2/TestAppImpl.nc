#include "Timer.h"
int counter_new = 0;
module TestAppImpl @safe()
{
  uses interface BinCounter;
  uses interface Boot;
}
implementation
{
  
  event void Boot.booted()
  {
    call BinCounter.start();
  }
  
  event void BinCounter.completed()
  {
    counter_new++;
    if( counter_new > 3 ) {
      call BinCounter.stop();
    }
  }
  
}


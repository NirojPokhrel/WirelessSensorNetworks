#include "Timer.h"
int dutyCycle = 0;
module BlinkC @safe()
{
  uses interface Timer<TMilli> as Timer0;
  uses interface Boot;
  uses interface GeneralIO as Led1;
}
implementation
{
  
  
  event void Boot.booted()
  {
    call Timer0.startPeriodic( 100 );
  }

  event void Timer0.fired()
  {
    dbg("BlinkC", "Timer 0 fired @ %s.\n", sim_time_string());
    //call Leds.led0Toggle();
    dutyCycle++;
    if( dutyCycle == 10 ) {
      call Led1.clr();
    }
    else if( dutyCycle == 11 ) {
      call Led1.set();
      dutyCycle = 0;
    }
  }
}


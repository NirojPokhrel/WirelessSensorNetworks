#include "Timer.h"

int led_set[3];
module BlinkC @safe()
{
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as Timer1;
  uses interface Timer<TMilli> as Timer2;
  uses interface Boot;
  uses interface GeneralIO as Led0;
  uses interface GeneralIO as Led1;
  uses interface GeneralIO as Led2;
}
implementation
{
  
  event void Boot.booted()
  {
    call Timer0.startPeriodic( 250 );
    call Timer1.startPeriodic( 500 );
    call Timer2.startPeriodic( 1000 );
  }

  event void Timer0.fired()
  {
    if( led_set[0] ) {
      led_set[0] = 0;
      call Led0.set();
    } else {
      led_set[0] = 1;
      call Led0.clr();
    }
  }


  
  event void Timer1.fired()
  {
    if( led_set[1] ) {
      led_set[1] = 0;
      call Led1.set();
    } else {
      led_set[1] = 1;
      call Led1.clr();
    }
  }
  
  event void Timer2.fired()
  {
    if( led_set[2] ) {
      led_set[2] = 0;
      call Led2.set();
    } else {
      led_set[2] = 1;
      call Led2.clr();
    }
  }
}


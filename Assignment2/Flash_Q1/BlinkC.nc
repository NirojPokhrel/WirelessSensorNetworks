/**
 * Flash application: TurnOff Period: 1000 TurnOn Period: 100
 * @author: Group 5
 **/

#include "Timer.h"
int dutyCycle = 0;
module BlinkC @safe()
{
  uses interface Timer<TMilli> as Timer0;
  uses interface Leds;
  uses interface Boot;
}
implementation
{
  
  
  event void Boot.booted()
  {
    call Timer0.startPeriodic( 100 );
  }

  event void Timer0.fired()
  {
    dutyCycle++;
    if( dutyCycle == 10 )
      call Leds.led0Toggle();
    else if( dutyCycle == 11 ) {
      call Leds.led0Toggle();
      dutyCycle = 0;
    }
  }
}


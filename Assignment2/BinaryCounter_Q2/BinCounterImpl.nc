#include "Timer.h"
int counter = 0, init = 0;
module BinCounterImpl @safe()
{
  uses interface Timer<TMilli> as Timer0;
  uses interface Leds;
  provides interface BinCounter;
}
implementation
{ 
  command void BinCounter.start() {
    call Timer0.startPeriodic( 500 );
  }

  event void Timer0.fired()
  {
    
    if( counter == 0 ) {
      call Leds.led0Off();
      call Leds.led1Off();
      call Leds.led2Off();
    } else if( counter == 1 ) {
      call Leds.led0On();
      call Leds.led1Off();
      call Leds.led2Off();
    } else if (counter ==2 ){
      call Leds.led0Off();
      call Leds.led1On();
      call Leds.led2Off();
    } else if (counter==3) {
      call Leds.led0On();
      call Leds.led1On();
      call Leds.led2Off();
    }else if (counter==4){
      call Leds.led0Off();
      call Leds.led1Off();
      call Leds.led2On();
    }else if (counter==5){
      call Leds.led0On();
      call Leds.led1Off();
      call Leds.led2On();
    }else if (counter==6){
      call Leds.led0Off();
      call Leds.led1On();
      call Leds.led2On();
    }else if (counter==7){
      call Leds.led0On();
      call Leds.led1On();
      call Leds.led2On();
    }
    counter++;
    if( counter > 7 ) {
      counter = 0;
      signal BinCounter.completed();
    }
  }


  command void BinCounter.stop() {
      call Timer0.stop();
      call Leds.led0Off();
      call Leds.led1Off();
      call Leds.led2Off();
  }
}


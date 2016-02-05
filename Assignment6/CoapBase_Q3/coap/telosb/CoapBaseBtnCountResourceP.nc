#include <pdu.h>
#include <async.h>
#include <mem.h>
#include <resource.h>
#include <UserButton.h>
#include <Timer.h>

generic module CoapBaseBtnCountResourceP(uint8_t uri_key) {
  provides interface CoapResource;
  uses interface Boot;
  uses interface Notify<button_state_t>;
} implementation {

  coap_pdu_t *response;

  coap_pdu_t *temp_request;
  bool lock = FALSE; //TODO: atomic
  coap_async_state_t *temp_async_state = NULL;
  coap_resource_t *temp_resource = NULL;
  unsigned int temp_content_format;
  uint16_t btn_counter;
  uint8_t observeFlag = 0;
  char name[64];

  //Code from UserButton
  event void Boot.booted() {
    call Notify.enable();
    btn_counter = 0;
    observeFlag = 0;
    sprintf(name, "%s", "Button:" );
  }


  //Default Code Starting
  command error_t CoapResource.initResourceAttributes(coap_resource_t *r) {
    return SUCCESS;
  }

  ////////////////Observe Method

  task void observeMethod() {

    int datalen = 0;
    char databuf[68]; 

    temp_resource->dirty = 1;
    datalen= snprintf(databuf, sizeof(databuf), "%s%d\n", name, btn_counter);

    response = coap_new_pdu();
    response->hdr->code = COAP_RESPONSE_CODE(205);

    if (temp_resource->data != NULL) {
      coap_free(temp_resource->data);
    }

    if ((temp_resource->data = (uint8_t *) coap_malloc(datalen)) != NULL) {
      memcpy(temp_resource->data, databuf, datalen);
      temp_resource->data_len = datalen;
    } else {
      response->hdr->code = COAP_RESPONSE_CODE(500);
    }
    coap_add_option(response, COAP_OPTION_SUBSCRIPTION, 0, NULL); 

    signal CoapResource.notifyObservers();
    lock = FALSE;

  }

  /////////////////////
  // GET:
  task void getMethod() {

    int datalen = 0;
    char databuf[68]; //ASCII of uint8_t -> max 3 chars + \0

    //uint8_t val = call Leds.get();
    datalen= snprintf(databuf, sizeof(databuf), "%s%d\n", name, btn_counter);

    response = coap_new_pdu();
    response->hdr->code = COAP_RESPONSE_CODE(205);

    if (temp_resource->data != NULL) {
      coap_free(temp_resource->data);
    }

    if ((temp_resource->data = (uint8_t *) coap_malloc(datalen)) != NULL) {
      memcpy(temp_resource->data, databuf, datalen);
      temp_resource->data_len = datalen;
    } else {
      response->hdr->code = COAP_RESPONSE_CODE(500);
    }
    if( observeFlag )
      coap_add_option(response, COAP_OPTION_SUBSCRIPTION, 0, NULL); 
    signal CoapResource.methodDone(SUCCESS,
        temp_async_state,
        temp_request,
        response,
        temp_resource);

    lock = FALSE;
  }

  event void Notify.notify( button_state_t state ) {
    if ( state == BUTTON_PRESSED ) {
      btn_counter++;
      if( observeFlag ) {
          post observeMethod();
          if( lock == FALSE ) 
            lock = TRUE;
      }
    } 
  }

  command int CoapResource.getMethod(coap_async_state_t* async_state,
				     coap_pdu_t* request,
				     coap_resource_t *resource,
				     unsigned int content_format) {
    if (lock == FALSE) {
      lock = TRUE;

      temp_async_state = async_state;
      temp_request = request;
      temp_resource = resource;
      temp_content_format = content_format;

#ifndef WITHOUT_OBSERVE
    if(async_state->flags & COAP_ASYNC_OBSERVED) {
      if(observeFlag) 
        observeFlag = 0;
      else
        observeFlag = 1;
    }
#endif
      post getMethod();
      return COAP_SPLITPHASE;
    } else {
      return COAP_RESPONSE_503;
    }
  }

  /////////////////////
  // PUT:
  task void putMethod() {
    size_t size;
    unsigned char *data;


    response = coap_new_pdu();

    coap_get_data(temp_request, &size, &data);

    //*data = *data - *(uint8_t *)"0";
    //call Leds.set(*data);
    btn_counter = atoi(data);

    response->hdr->code = COAP_RESPONSE_CODE(204);

    signal CoapResource.methodDone(SUCCESS,
				   temp_async_state,
				   temp_request,
				   response,
				   temp_resource);
    lock = FALSE;
  }

  //////////////////////
  ///// POST:
  task void postMethod() {
    size_t size;
    unsigned char *data;


    response = coap_new_pdu();

    coap_get_data(temp_request, &size, &data);

    //sprintf(name, size, "%s:", data);
    sprintf(name, "%s", data );

    response->hdr->code = COAP_RESPONSE_CODE(204);

    signal CoapResource.methodDone(SUCCESS,
           temp_async_state,
           temp_request,
           response,
           temp_resource);
    lock = FALSE;
  }

  command int CoapResource.putMethod(coap_async_state_t* async_state,
				     coap_pdu_t* request,
				     coap_resource_t *resource,
				     unsigned int content_format) {
    if (lock == FALSE) {
      lock = TRUE;

      temp_async_state = async_state;
      temp_request = request;
      temp_resource = resource;
      temp_content_format = content_format;

      post putMethod();
      return COAP_SPLITPHASE;
    } else {
      return COAP_RESPONSE_CODE(503);
    }
  }

  command int CoapResource.postMethod(coap_async_state_t* async_state,
				      coap_pdu_t* request,
				      coap_resource_t *resource,
				      unsigned int content_format) {
    if (lock == FALSE) {
      lock = TRUE;

      temp_async_state = async_state;
      temp_request = request;
      temp_resource = resource;
      temp_content_format = content_format;

      //if(temp_resource->)

      post postMethod();
      return COAP_SPLITPHASE;
    } else {
      return COAP_RESPONSE_CODE(503);
    }
  }

  command int CoapResource.deleteMethod(coap_async_state_t* async_state,
					coap_pdu_t* request,
					coap_resource_t *resource) {
    return COAP_RESPONSE_405;
  }
}

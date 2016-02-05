generic configuration CoapBaseBtnCountResourceC(uint8_t uri_key) {
    provides interface CoapResource;
} implementation {

    components new CoapBaseBtnCountResourceP(uri_key) as CoapBtnCountResourceP;

 	components MainC;
 	CoapBtnCountResourceP.Boot -> MainC;
    CoapResource = CoapBtnCountResourceP;
  
  	components UserButtonC;
  	CoapBtnCountResourceP.Notify -> UserButtonC;
}

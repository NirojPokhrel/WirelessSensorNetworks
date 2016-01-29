generic configuration CoapBaseLedResourceC(uint8_t uri_key) {
    provides interface CoapResource;
    uses interface Leds;
} implementation {
    components new CoapBaseLedResourceP(uri_key) as CoapLedResourceP;

    CoapResource = CoapLedResourceP;
    Leds = CoapLedResourceP;
}

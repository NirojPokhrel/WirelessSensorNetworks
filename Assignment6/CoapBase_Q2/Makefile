COMPONENT=CoapBlipC

CFLAGS += -DCC2420_DEF_CHANNEL=$(TOS_CHANNEL)

################  RPL  ################ 
PFLAGS += -DRPL_ROUTING -DRPL_STORING_MODE -I$(TINYOS_OS_DIR)/lib/net/rpl
PFLAGS += -DRPL_OF_0=1
PFLAGS += -DRPL_OF_MRHOF=0
PFLAGS += -DBLIP_SEND_ROUTER_SOLICITATIONS=1
PFLAGS += -DBLIP_SEND_ROUTER_ADVERTISEMENTS=1

PFLAGS += -DIN6_PREFIX=\"fec0::\"

################ CoAP Server ###############################
CFLAGS += -DCOAP_SERVER_ENABLED
# port where server is listening
#CFLAGS += -DCOAP_SERVER_PORT=5683L
#set max uri length
CFLAGS += -DMAX_URI_LENGTH=14
# set PDU size
CFLAGS += -DCOAP_MAX_PDU_SIZE=127

# disables observe
#CFLAGS += -DWITHOUT_OBSERVE

# disables .well-known/core resource
CFLAGS += -DWITHOUT_WELLKNOWN

# leave out unneeded features
CFLAGS += -DSHORT_ERROR_RESPONSE
CFLAGS += -DWITHOUT_BLOCK

#### set available resources:

# lab session demo resources
#CFLAGS += -DCOAP_RESOURCE_BASE_LEDS

CFLAGS += -DCOAP_RESOURCE_BUTTON_COUNTER

# stock resources that fit on telosb
#CFLAGS += -DCOAP_RESOURCE_TEMP
#CFLAGS += -DCOAP_RESOURCE_HUM
#CFLAGS += -DCOAP_RESOURCE_LED
#CFLAGS += -DCOAP_RESOURCE_ROUTE



CFLAGS += -Icoap/telosb
TINYOS_ROOT_DIR?=$(WSNPR_TOSROOT)

GOALS += blip coap

include $(TINYOS_ROOT_DIR)/Makefile.include

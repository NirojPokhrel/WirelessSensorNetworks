#
# This class is automatically generated by mig. DO NOT EDIT THIS FILE.
# This class implements a Python interface to the 'SmokeDetection'
# message type.
#

import tinyos.message.Message

# The default size of this message type in bytes.
DEFAULT_MESSAGE_SIZE = 2

# The Active Message type associated with this message.
AM_TYPE = -1

class SmokeDetection(tinyos.message.Message.Message):
    # Create a new SmokeDetection of size 2.
    def __init__(self, data="", addr=None, gid=None, base_offset=0, data_length=2):
        tinyos.message.Message.Message.__init__(self, data, addr, gid, base_offset, data_length)
        self.amTypeSet(AM_TYPE)
    
    # Get AM_TYPE
    def get_amType(cls):
        return AM_TYPE
    
    get_amType = classmethod(get_amType)
    
    #
    # Return a String representation of this message. Includes the
    # message type name and the non-indexed field values.
    #
    def __str__(self):
        s = "Message <SmokeDetection> \n"
        try:
            s += "  [source=0x%x]\n" % (self.get_source())
        except:
            pass
        return s

    # Message-type-specific access methods appear below.

    #
    # Accessor methods for field: source
    #   Field type: int
    #   Offset (bits): 0
    #   Size (bits): 16
    #

    #
    # Return whether the field 'source' is signed (False).
    #
    def isSigned_source(self):
        return False
    
    #
    # Return whether the field 'source' is an array (False).
    #
    def isArray_source(self):
        return False
    
    #
    # Return the offset (in bytes) of the field 'source'
    #
    def offset_source(self):
        return (0 / 8)
    
    #
    # Return the offset (in bits) of the field 'source'
    #
    def offsetBits_source(self):
        return 0
    
    #
    # Return the value (as a int) of the field 'source'
    #
    def get_source(self):
        return self.getUIntElement(self.offsetBits_source(), 16, 1)
    
    #
    # Set the value of the field 'source'
    #
    def set_source(self, value):
        self.setUIntElement(self.offsetBits_source(), 16, value, 1)
    
    #
    # Return the size, in bytes, of the field 'source'
    #
    def size_source(self):
        return (16 / 8)
    
    #
    # Return the size, in bits, of the field 'source'
    #
    def sizeBits_source(self):
        return 16
    

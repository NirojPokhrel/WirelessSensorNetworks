README for Q1
Author Group 5

Description:

Function ChangeEndianess can be used to convert little endian memory layout to big endian. 
It can be used to convert 16 bit or 32 bit to big endian layout. However, it can be easily extend to support 64 bit by replacing uint32_t num to uint64_t num and send len = sizeof( uint64_t).

void ChangeEndianess(uint32_t num, char* output, int len);

num = Number to be converted
output = output buffer which contains the big endian layout of num
len = size of num (2, 4, 8)

To convert between 16 bit and 32 bit,
	enum {
		ENUM_ITEM_NUM_SIZE = sizeof(uint16_t),
	};
Change ENUM_ITEM_NUM_SIZE as per the requirement.
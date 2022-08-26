/* Through this source code, you could see the point output architechture of touch device.
You could follow below code to do point parsing. And develop your own app. */

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <limits.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <linux/input.h>

/*Note: If you couldn't build this source code successfully, it may caused by the old kernel issue.
Please enable below define depending on your kernel version */

//#define KERNEL_2_6_35_DOWNWARD	/* As kernel <= 2.6.35 */
//#define KERNEL_2_6_32_DOWNWARD	/* As kernel <= 2.6.32 */
//#define KERNEL_2_6_29_DOWNWARD	/* As kernel <= 2.6.29 */

typedef struct tagevent
{
    struct timeval time;
    unsigned short type;
    unsigned short code;
    int value;
} input_event;

void ParseEvent( input_event ev )
{
    static unsigned short X, Y, State;
    static unsigned short X2, Y2, State2;
    static unsigned char bIsSecond;


	if( ev.type == EV_ABS ) {
        switch( ev.code ) {
#ifndef KERNEL_2_6_35_DOWNWARD
			case ABS_MT_SLOT:
				printf("	[ABS_MT_SLOT]           code = %3d, value = %4d\n", ev.code , ev.value);
				break;
#endif
#ifndef KERNEL_2_6_32_DOWNWARD
			case ABS_MT_PRESSURE: 
				printf("	[ABS_MT_PRESSURE]       code = %3d, value = %4d\n", ev.code , ev.value);
				break;
#endif
#ifndef KERNEL_2_6_29_DOWNWARD
			case ABS_MT_TRACKING_ID:
				printf("	[ABS_MT_TRACKING_ID]    code = %3d, value = %4d\n", ev.code , ev.value);
				break;
			case ABS_MT_POSITION_X: 
				printf("	[ABS_MT_POSITION_X]     code = %3d, value = %4d\n", ev.code , ev.value);
				break;
			case ABS_MT_POSITION_Y: 
				printf("	[ABS_MT_POSITION_Y]     code = %3d, value = %4d\n", ev.code , ev.value);
				break;
			case ABS_MT_TOUCH_MAJOR:
				printf("	[ABS_MT_TOUCH_MAJOR]    code = %3d, value = %4d\n", ev.code , ev.value);
				break;
			case ABS_MT_WIDTH_MAJOR:
				printf("	[ABS_MT_WIDTH_MAJOR]    code = %3d, value = %4d\n", ev.code , ev.value);
				break;
#endif
			case ABS_X: 
				printf("	[ABS_X]                 code = %3d, value = %4d\n", ev.code , ev.value);
				break;
			case ABS_Y: 
				printf("	[ABS_Y]                 code = %3d, value = %4d\n", ev.code , ev.value);
				break;
			case ABS_RX: 
				printf("	[ABS_RX]                code = %3d, value = %4d\n", ev.code , ev.value);
				break;
			case ABS_RY: 
				printf("	[ABS_RY]                code = %3d, value = %4d\n", ev.code , ev.value);
				break;
			case ABS_PRESSURE: 
				printf("	[ABS_PRESSURE]          code = %3d, value = %4d\n", ev.code , ev.value);
				break;
			default:
				break;
        }
    }
	else if( ev.type == EV_KEY ){
		switch( ev.code ){
			case BTN_TOUCH:
				printf("	[BTN_TOUCH]		code = %3d, value = %4d\n", ev.code , ev.value);
				break;
			case BTN_LEFT:
				printf("	[BTN_LEFT]		code = %3d, value = %4d\n", ev.code , ev.value);
				break;
			case BTN_EXTRA:
				printf("	[BTN_EXTRA]		code = %3d, value = %4d\n", ev.code , ev.value);
				break;
			default:
				break;
		}
		
	}
	else if( ev.type == EV_SYN ){
		switch( ev.code ){
			case SYN_REPORT:
				printf("	[SYN_REPORT]		code = %3d, value = %4d\n\n", ev.code , ev.value);
				break;
#ifndef KERNEL_2_6_29_DOWNWARD
			case SYN_MT_REPORT:
				printf("	[SYN_MT_REPORT]		code = %3d, value = %4d\n", ev.code , ev.value);
				break;
#endif
			default:
				break;
		}	
    }
	else if( ev.type == EV_MSC ){
		if( ev.code == MSC_SCAN )
			printf("	[MSC_SCAN]		code = %3d, value = %4d\n", ev.code , ev.value);
	}
}

int main( int argc, char **argv )
{
    int fd;
    unsigned char byFlag = 0; /* 0: Point */
    char strPort[64] = { 0 };
    fd_set readfds;

    if( argc == 1 || argc > 2 ) {
        printf(" \nUsage:\n \tGetEvent [Port]\n");
        printf("Example:\n \tGetEvent /dev/input/event1\n\n");
        return 0;
    }
	
    sprintf( strPort, "%s", argv[1] );
    printf("Event Port = %s ", strPort);
    fd = open(strPort, O_RDONLY );
    if( fd >= 0 ) {	
        printf(" open: ok\n" );
        FD_ZERO( &readfds );
        FD_SET( fd , &readfds );
        while( 1 ) {
            if( select( fd+1, &readfds, NULL, NULL, NULL ) > 0 ) {
                input_event ev;
                if( sizeof( input_event ) == read( fd, &ev, sizeof( input_event ) ) ) {
                    ParseEvent( ev );
                } else {
                    printf(" Nothing read \n" );
                }
            }
        }	
    }
    return 0;
}
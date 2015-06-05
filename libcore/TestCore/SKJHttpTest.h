//
//  SKJHttpTest.h
//  SKCore
//
//  Created by Pete Cole on 05/06/2015.
//  Copyright (c) 2015 SamKnows. All rights reserved.
//
// This file is a direct port from HttpTest.java
//

#import "SKJTest.h"

/* Socket timeout parameters */

#define CONNECTIONTIMEOUT ((int) 10000) 							/* 10 seconds connection timeout */
#define READTIMEOUT ((int) 10000) 								/* 10 seconds read timeout */
#define WRITETIMEOUT ((int) 10000) 								/* 10 seconds write timeout */

/* Http Status codes */
#define HTTPOK ((int) 200)
#define HTTPCONTINUE ((int) 100)

/* error codes and constraints */
#define BYTESREADERR ((int) -1)									/* Error occurred while reading from socket */
//#define MAXNTHREADS ((int) 100)									/* Max number of threads */

/* Parameters name for the setParameter function */
#define _DOWNSTREAM @"downstream"				/* HTTP test types. Static because called from constructors */
#define _UPSTREAM @"upstream"

/* Parameters names for use in Settings XML files */
//private static final String DOWNSTREAM = "downStream";
//private static final String UPSTREAM = "upStream";
#define UPLOADSTRATEGY @"strategy"						/* Use server side calculations, different type of server required  */
#define WARMUPMAXTIME @"warmupMaxTime"					/* Max warmup time in uSecs */
#define WARMUPMAXBYTES @"warmupMaxBytes"					/* Max warmup bytes allowed to be transmitted */
#define TRANSFERMAXTIME @"transferMaxTime"				/* Max transfer time in uSecs. Metrics, measured during this time period contribute to final result */
#define TRANSFERMAXBYTES @"transferMaxBytes"				/* Max transfer bytes allowed to be transmitted */
#define NTHREADS @"numberOfThreads"						/* Max number of threads allowed */
#define BUFFERSIZE @"bufferSize"							/* Socket receive buffer size */
#define SENDBUFFERSIZE @"sendBufferSize"					/* Socket send buffer size */
#define RECEIVEBUFFERSIZE @"receiveBufferSize"			/* Socket receive buffer size */
#define POSTDATALENGTH @"postDataLength"					/* ??? */
#define SENDDATACHUNK @"sendDataChunk"					/* Application send buffer size */
  
/* Messages regarding the status of the test */
#define HTTPGETRUN @"Running download test"
#define HTTPGETDONE @"Download test completed"
#define HTTPPOSTRUN @"Running upload test"
#define HTTPPOSTDONE @"Upload completed"

  /* Test strings for public use. JSON related */
#define DOWNSTREAMSINGLE @"JHTTPGET"
#define DOWNSTREAMMULTI @"JHTTPGETMT"
#define UPSTREAMSINGLE @"JHTTPPOST"
#define UPSTREAMMULTI @"JHTTPPOSTMT"

#define cReasonResetDownload @"Reset Download"
#define cReasonResetUpload @"Reset Upload"
#define cReasonUploadEnd @"Upload End"


@interface SKJHttpTest : SKJTest

typedef enum t_UploadStrategy {
  ACTIVE  = 0,
  PASSIVE = 1
} UploadStrategy;

@property int port;
@property NSString *target;

/* Abstract methods to be implemented in derived classes */
-(BOOL) transferToSocket:(GCDAsyncSocket*)socket ThreadIndex:(int)threadIndex;	/* Generate main traffic for metrics measurements */
  
-(BOOL) warmupToSocket:(GCDAsyncSocket*)socket ThreadIndex:(int)threadIndex;		/* Generate initial traffic for setting optimal TCP parameters */
//protected abstract int getWarmupBytesPerSecond();						/* Initial traffic speed */
//protected abstract int getTransferBytesPerSecond();						/* Main traffic speed */

+(long) sGetMicroTime;
+(long) sGetMilliTime;

@end
#import <XCTest/XCTest.h>

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import <OCMock/OCMock.h>

#import "MSAIAppClient.h"
#import "MSAIChannel.h"
#import "MSAIChannelPrivate.h"
#import "MSAITelemetryContext.h"
#import "MSAITelemetryContextPrivate.h"
#import "MSAIPersistence.h"
#import "MSAIEnvelope.h"

@interface MSAIChannelTests : XCTestCase

@property(nonatomic, strong) MSAIChannel *sut;
@property(nonatomic, strong) MSAIAppClient *appClient;

@end


@implementation MSAIChannelTests

- (void)setUp {
  [super setUp];
  
  self.appClient = [[MSAIAppClient alloc]initWithBaseURL:[NSURL URLWithString:@"http://test.com/"]];
  [MSAIChannel setSharedChannel:[MSAIChannel new]];
  self.sut = [MSAIChannel sharedChannel];
  MSAISafeJsonEventsString = NULL;
}

#pragma mark - Setup Tests

- (void)testsharedChannelCreated {
  XCTAssertNotNil([MSAIChannel sharedChannel]);
}

- (void)testUniqueInstanceCreated {
  XCTAssertNotNil([MSAIChannel new]);
}

- (void)testInstanceInitialised {
  XCTAssertTrue([self.sut.dataItemQueue isEqualToArray:[NSMutableArray array]]);
  XCTAssertEqual((const int)self.sut.senderBatchSize, debugMaxBatchCount);
  XCTAssertEqual((const int)self.sut.senderInterval, debugBatchInterval);
}

- (void)testSingletonReturnsSameInstanceTwice {
  MSAIChannel *m1 = [MSAIChannel sharedChannel];
  XCTAssertEqualObjects(m1, [MSAIChannel sharedChannel]);
}

- (void)testSingletonSeperateFromUniqueInstance {
  XCTAssertNotEqualObjects([MSAIChannel sharedChannel], [MSAIChannel new]);
}

- (void)testMetricsManagerReturnsSeperateUniqueInstances {
  XCTAssertNotEqualObjects([MSAIChannel new], [MSAIChannel new]);
}

- (void)testDataItemsOperationsQueueWasInitialised {
  XCTAssertNotNil(self.sut.dataItemsOperations);
}

- (void)testDataItemsOperationsQueueStaysSame {
  XCTAssertEqualObjects([MSAIChannel sharedChannel].dataItemsOperations, [MSAIChannel sharedChannel].dataItemsOperations);
}

#pragma mark - Queue management

- (void)testEnqueueEnvelopeWithOneEnvelopeAndNormalJSON {
  self.sut = OCMPartialMock(self.sut);
  MSAIOrderedDictionary *dictionary = [MSAIOrderedDictionary new];
  
  [self.sut enqueueDictionary:dictionary];
  
  [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  
  assertThat(self.sut.dataItemQueue, hasCountOf(1));
  XCTAssertEqual(self.sut.dataItemQueue.firstObject, dictionary);
  OCMVerify([self.sut startTimer]);
}

- (void)testEnqueueEnvelopeWithOneEnvelopeAndJSONStream {
  self.sut = OCMPartialMock(self.sut);
  MSAIOrderedDictionary *dictionary = [MSAIOrderedDictionary new];
  self.sut.emitLineDelimitedJson = YES;
  
  [self.sut enqueueDictionary:dictionary];
  
  dispatch_async(self.sut.dataItemsOperations, ^{
    assertThatUnsignedInteger(self.sut.dataItemCount, equalToUnsignedInteger(1));
    XCTAssertTrue(strcmp(MSAISafeJsonEventsString, "{}\n") == 0);
    OCMVerify([self.sut startTimer]);
  });
}

- (void)testEnqueueEnvelopeWithMultipleEnvelopesAndNormalJSON {
  self.sut = OCMPartialMock(self.sut);
  OCMStub([self.sut invalidateTimer]);
  
  self.sut.senderBatchSize = 3;
  
  MSAIOrderedDictionary *dictionary = [MSAIOrderedDictionary new];
  
  assertThat(self.sut.dataItemQueue, hasCountOf(0));
  
  [self.sut enqueueDictionary:dictionary];
  assertThat(self.sut.dataItemQueue, hasCountOf(1));
  
  [self.sut enqueueDictionary:dictionary];
  assertThat(self.sut.dataItemQueue, hasCountOf(2));
  
  [self.sut enqueueDictionary:dictionary];
  assertThat(self.sut.dataItemQueue, hasCountOf(0));
  
  OCMVerify([self.sut invalidateTimer]);
}

- (void)testEnqueueEnvelopeWithMultipleEnvelopesAndJSONStream {
  self.sut = OCMPartialMock(self.sut);
  self.sut.emitLineDelimitedJson = YES;
  
  self.sut.senderBatchSize = 3;
  
  MSAIOrderedDictionary *dictionary = [MSAIOrderedDictionary new];
  
  assertThatUnsignedInteger(self.sut.dataItemCount, equalToUnsignedInteger(0));
  
  [self.sut enqueueDictionary:dictionary];
  [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
  assertThatUnsignedInteger(self.sut.dataItemCount, equalToUnsignedInteger(1));
  XCTAssertTrue(strcmp(MSAISafeJsonEventsString, "{}\n") == 0);
  
  [self.sut enqueueDictionary:dictionary];
  dispatch_async(self.sut.dataItemsOperations, ^{
    assertThatUnsignedInteger(self.sut.dataItemCount, equalToUnsignedInteger(2));
    XCTAssertTrue(strcmp(MSAISafeJsonEventsString, "{}\n{}\n") == 0);
  });
  
  [self.sut enqueueDictionary:dictionary];
  dispatch_async(self.sut.dataItemsOperations, ^{
    OCMVerify([self.sut invalidateTimer]);
    assertThatUnsignedInteger(self.sut.dataItemCount, equalToUnsignedInteger(0));
    XCTAssertTrue(strcmp(MSAISafeJsonEventsString, "") == 0);
  });
}

#pragma mark - Safe JSON String Tests

- (void)testAppendStringToSafeJsonString {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  msai_appendStringToSafeJsonString(nil, 0);
#pragma clang diagnostic pop
  XCTAssertTrue(MSAISafeJsonEventsString == NULL);
  
  MSAISafeJsonEventsString = NULL;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  msai_appendStringToSafeJsonString(nil, &MSAISafeJsonEventsString);
#pragma clang diagnostic pop
  XCTAssertTrue(MSAISafeJsonEventsString == NULL);
  
  msai_appendStringToSafeJsonString(@"", &MSAISafeJsonEventsString);
  XCTAssertEqual(strcmp(MSAISafeJsonEventsString,"[,"), 0);
  
  msai_appendStringToSafeJsonString(@"{\"Key1\":\"Value1\"}", &MSAISafeJsonEventsString);
  XCTAssertEqual(strcmp(MSAISafeJsonEventsString,"[,{\"Key1\":\"Value1\"},"), 0);
}

- (void)testResetSafeJsonString {
  msai_resetSafeJsonString(&MSAISafeJsonEventsString);
  XCTAssertEqual(strcmp(MSAISafeJsonEventsString,"["), 0);
  
  MSAISafeJsonEventsString = NULL;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  msai_resetSafeJsonString(nil);
#pragma clang diagnostic pop
  XCTAssertEqual(MSAISafeJsonEventsString, NULL);
  
  MSAISafeJsonEventsString = strdup("test string");
  msai_resetSafeJsonString(&MSAISafeJsonEventsString);
  XCTAssertEqual(strcmp(MSAISafeJsonEventsString,"["), 0);
}

#pragma mark - Safe JSON Stream Tests

- (void)testAppendStringToSafeJsonStream {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  msai_appendStringToSafeJsonStream(nil, 0);
#pragma clang diagnostic pop
  XCTAssertTrue(MSAISafeJsonEventsString == NULL);
  
  MSAISafeJsonEventsString = NULL;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  msai_appendStringToSafeJsonStream(nil, &MSAISafeJsonEventsString);
#pragma clang diagnostic pop
  XCTAssertTrue(MSAISafeJsonEventsString == NULL);
  
  msai_appendStringToSafeJsonStream(@"", &MSAISafeJsonEventsString);
  XCTAssertEqual(strcmp(MSAISafeJsonEventsString,""), 0);
  
  msai_appendStringToSafeJsonStream(@"{\"Key1\":\"Value1\"}", &MSAISafeJsonEventsString);
  XCTAssertEqual(strcmp(MSAISafeJsonEventsString,"{\"Key1\":\"Value1\"}\n"), 0);
}

- (void)testResetSafeJsonStream {
  msai_resetSafeJsonStream(&MSAISafeJsonEventsString);
  XCTAssertEqual(strcmp(MSAISafeJsonEventsString,""), 0);
  
  MSAISafeJsonEventsString = NULL;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  msai_resetSafeJsonStream(nil);
#pragma clang diagnostic pop
  XCTAssertEqual(MSAISafeJsonEventsString, NULL);
  
  MSAISafeJsonEventsString = strdup("test string");
  msai_resetSafeJsonStream(&MSAISafeJsonEventsString);
  XCTAssertEqual(strcmp(MSAISafeJsonEventsString,""), 0);
}

@end

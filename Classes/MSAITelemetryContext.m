#import <Foundation/Foundation.h>
#import "MSAITelemetryContext.h"
#import "MSAITelemetryContextPrivate.h"
#import "MSAIHelper.h"


#define defaultSessionRenewalMs     30 * 60 * 1000
#define defaultSessionExpirationMs  24 * 60 * 60 * 1000

NSString *const kMSAITelemetrySessionId = @"MSAITelemetrySessionId";
NSString *const kMSAISessionAcquisitionTime = @"MSAISessionAcquisitionTime";

@implementation MSAITelemetryContext

- (instancetype)initWithInstrumentationKey:(NSString *)instrumentationKey
                              endpointPath:(NSString *)endpointPath
                        applicationContext:(MSAIApplication *)applicationContext
                             deviceContext:(MSAIDevice *)deviceContext
                           locationContext:(MSAILocation *)locationContext
                            sessionContext:(MSAISession *)sessionContext
                               userContext:(MSAIUser *)userContext
                           internalContext:(MSAIInternal *)internalContext
                          operationContext:(MSAIOperation *)operationContext{
  if ((self = [self init])) {
    _instrumentationKey = instrumentationKey;
    _endpointPath = endpointPath;
    _application = applicationContext;
    _device = deviceContext;
    _location = locationContext;
    _user = userContext;
    _internal = internalContext;
    _operation = operationContext;
    _session = sessionContext;
    [self updateSessionFromSessionDefaults];
  }
  return self;
}

- (MSAIOrderedDictionary *)contextDictionary {  
  
  [self updateSessionContext];
  MSAIOrderedDictionary *contextDictionary = [self.application serializeToDictionary];
  [contextDictionary addEntriesFromDictionary:[self.session serializeToDictionary]];
  [contextDictionary addEntriesFromDictionary:[self.device serializeToDictionary]];
  [contextDictionary addEntriesFromDictionary:[self.location serializeToDictionary]];
  [contextDictionary addEntriesFromDictionary:[self.user serializeToDictionary]];
  [contextDictionary addEntriesFromDictionary:[self.internal serializeToDictionary]];
  [contextDictionary addEntriesFromDictionary:[self.operation serializeToDictionary]];
  
  return contextDictionary;
}

- (void)writeSessionDefaultsWithSessionId:(NSString *)sessionId acquisitionTime:(long)acquisitionTime{
  [[NSUserDefaults standardUserDefaults] setObject:sessionId forKey:kMSAITelemetrySessionId];
  [[NSUserDefaults standardUserDefaults] setDouble:acquisitionTime forKey:kMSAISessionAcquisitionTime];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)updateSessionFromSessionDefaults{
  _session.sessionId = [[NSUserDefaults standardUserDefaults]objectForKey:kMSAITelemetrySessionId];
  _acquisitionMs = [[NSUserDefaults standardUserDefaults]doubleForKey:kMSAISessionAcquisitionTime];
}

#pragma mark - Helper

- (void)updateSessionContext {
  long currentDateMs = [[NSDate date] timeIntervalSince1970];
  
  BOOL firstSession = [self isFirstSession];
  BOOL acqExpired = (currentDateMs  - _acquisitionMs) > defaultSessionExpirationMs;
  BOOL renewalExpired = (currentDateMs - _renewalMs) > defaultSessionRenewalMs;
  
  _session.isFirst = (firstSession ? @"true" : @"false");
  
  if (firstSession || acqExpired || renewalExpired) {
    [self createNewSessionWithCurrentDateTime:currentDateMs];
  }else{
    [self renewSessionWithCurrentDateTime:currentDateMs];
  }
}

- (BOOL)isFirstSession{
  return _acquisitionMs == 0 || _renewalMs == 0;
}

- (void)createNewSessionWithCurrentDateTime:(long)dateTime{
  _session.sessionId = msai_UUID();
  _session.isFirst = @"true";
  _renewalMs = dateTime;
  _acquisitionMs = dateTime;
  [self writeSessionDefaultsWithSessionId:[_session sessionId] acquisitionTime:_acquisitionMs];
}

- (void)renewSessionWithCurrentDateTime:(long)dateTime{
  _renewalMs = dateTime;
  _session.isFirst = @"false";
}

@end

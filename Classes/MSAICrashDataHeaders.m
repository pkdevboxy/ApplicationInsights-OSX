#import "MSAICrashDataHeaders.h"
/// Data contract class for type CrashDataHeaders.
@implementation MSAICrashDataHeaders

/// Initializes a new instance of the class.
- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

///
/// Adds all members of this class to a dictionary
/// @param dictionary to which the members of this class will be added.
///
- (MSAIOrderedDictionary *)serializeToDictionary {
    MSAIOrderedDictionary *dict = [super serializeToDictionary];
    if (self.crashDataHeadersId != nil) {
        [dict setObject:self.crashDataHeadersId forKey:@"id"];
    }
    if (self.process != nil) {
        [dict setObject:self.process forKey:@"process"];
    }
    if (self.processId != nil) {
        [dict setObject:self.processId forKey:@"processId"];
    }
    if (self.parentProcess != nil) {
        [dict setObject:self.parentProcess forKey:@"parentProcess"];
    }
    if (self.parentProcessId != nil) {
        [dict setObject:self.parentProcessId forKey:@"parentProcessId"];
    }
    if (self.crashThread != nil) {
        [dict setObject:self.crashThread forKey:@"crashThread"];
    }
    if (self.applicationPath != nil) {
        [dict setObject:self.applicationPath forKey:@"applicationPath"];
    }
    if (self.applicationIdentifier != nil) {
        [dict setObject:self.applicationIdentifier forKey:@"applicationIdentifier"];
    }
    if (self.applicationBuild != nil) {
        [dict setObject:self.applicationBuild forKey:@"applicationBuild"];
    }
    if (self.exceptionType != nil) {
        [dict setObject:self.exceptionType forKey:@"exceptionType"];
    }
    if (self.exceptionCode != nil) {
        [dict setObject:self.exceptionCode forKey:@"exceptionCode"];
    }
    if (self.exceptionAddress != nil) {
        [dict setObject:self.exceptionAddress forKey:@"exceptionAddress"];
    }
    if (self.exceptionReason != nil) {
        [dict setObject:self.exceptionReason forKey:@"exceptionReason"];
    }
    return dict;
}

@end

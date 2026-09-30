#import "NativeVisibility.h"
#import <dlfcn.h>
#import <objc/message.h>

@implementation TKNativeVisibility {
    id _restriction;
    id _pendingRestriction;
    NSUInteger _revision;
}

+ (BOOL)available {
    static void *framework;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        framework = dlopen("/System/Library/PrivateFrameworks/MenuBarClientCore.framework/MenuBarClientCore", RTLD_LOCAL | RTLD_NOW);
    });
    Class configuration = NSClassFromString(@"MBAssessmentModeConfiguration");
    Class assertion = NSClassFromString(@"MBAssessmentModeAssertion");
    return framework &&
        [configuration instancesRespondToSelector:NSSelectorFromString(@"initWithAllowedSystemItems:allowedBundleIdentifiers:")] &&
        [assertion instancesRespondToSelector:NSSelectorFromString(@"activateWithConfiguration:completionHandler:")] &&
        [assertion instancesRespondToSelector:NSSelectorFromString(@"invalidate")];
}

static void ReleaseRestriction(id restriction) {
    if (!restriction) return;
    @try {
        ((void (*)(id, SEL))objc_msgSend)(restriction, NSSelectorFromString(@"invalidate"));
    } @catch (NSException *exception) {
        NSLog(@"Tucker: could not release menu bar restriction: %@", exception.reason);
    }
}

- (void)hideExceptBundles:(NSArray<NSString *> *)bundles
              completion:(void (^)(NSString * _Nullable))completion {
    [self restore];
    if (!TKNativeVisibility.available) {
        completion(@"This macOS build does not provide the menu bar visibility service.");
        return;
    }
    NSUInteger revision = _revision;
    __weak TKNativeVisibility *owner = self;
    id pending;
    @try {
        NSMutableArray<NSNumber *> *systemItems = [NSMutableArray array];
        // Keep system controls, including the clock and Control Center.
        for (NSInteger identifier = 0; identifier < 64; identifier++) {
            [systemItems addObject:@(identifier)];
        }
        id configuration = ((id (*)(id, SEL, id, id))objc_msgSend)(
            [NSClassFromString(@"MBAssessmentModeConfiguration") alloc],
            NSSelectorFromString(@"initWithAllowedSystemItems:allowedBundleIdentifiers:"),
            systemItems, [bundles copy]);
        pending = [[NSClassFromString(@"MBAssessmentModeAssertion") alloc] init];
        if (!configuration || !pending) {
            completion(@"Could not create the menu bar visibility session.");
            return;
        }
        id session = pending;
        _pendingRestriction = session;
        ((void (*)(id, SEL, id, id))objc_msgSend)(session,
            NSSelectorFromString(@"activateWithConfiguration:completionHandler:"), configuration,
            ^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    TKNativeVisibility *strongOwner = owner;
                    if (!strongOwner || strongOwner->_revision != revision) {
                        ReleaseRestriction(session);
                        return;
                    }
                    if (error) ReleaseRestriction(session);
                    else strongOwner->_restriction = session;
                    strongOwner->_pendingRestriction = nil;
                    completion(error.localizedDescription);
                });
            });
    } @catch (NSException *exception) {
        ReleaseRestriction(pending);
        _pendingRestriction = nil;
        completion(exception.reason ?: @"The menu bar visibility service failed.");
    }
}

- (void)restore {
    _revision++;
    ReleaseRestriction(_pendingRestriction);
    _pendingRestriction = nil;
    ReleaseRestriction(_restriction);
    _restriction = nil;
}

- (void)dealloc {
    ReleaseRestriction(_pendingRestriction);
    ReleaseRestriction(_restriction);
}
@end

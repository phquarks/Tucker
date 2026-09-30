#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface TKNativeVisibility : NSObject
@property(class, nonatomic, readonly) BOOL available;
- (void)hideExceptBundles:(NSArray<NSString *> *)bundles
              completion:(void (^)(NSString * _Nullable error))completion NS_SWIFT_DISABLE_ASYNC;
- (void)restore;
@end
NS_ASSUME_NONNULL_END

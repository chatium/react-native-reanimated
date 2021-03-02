#import "REATransitionManager.h"

#import <React/RCTUIManager.h>
#import <React/RCTUIManagerObserverCoordinator.h>

#import "REATransition.h"

@interface REATransitionManager () <RCTUIManagerObserver>
@end

@implementation REATransitionManager {
  NSMutableArray *_pendingTransitions;
  RCTUIManager *_uiManager;
}

- (instancetype)initWithUIManager:(id)uiManager
{
  if (self = [super init]) {
    _uiManager = uiManager;
  }
  return self;
}

- (void)beginTransition:(REATransition *)transition forView:(UIView *)view
{
  RCTAssertMainQueue();
    if (_pendingTransitions == nil) {
        _pendingTransitions = [NSMutableArray new];
    }
  [_pendingTransitions addObject:@{@"transition": transition, @"view": view}];
  [transition startCaptureInRoot:view];
}

- (void)uiManagerWillPerformMounting:(RCTUIManager *)manager
{
  [manager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    if (_pendingTransitions != nil) {
        for (NSDictionary *pending in _pendingTransitions) {
            REATransition *transition = [pending objectForKey:@"transition"];
            UIView *view = [pending objectForKey:@"view"];
            [transition playInRoot:view];
        }
        [_pendingTransitions removeAllObjects];
    }
  }];
}

- (void)animateNextTransitionInRoot:(NSNumber *)reactTag withConfig:(NSDictionary *)config
{
  [_uiManager.observerCoordinator addObserver:self];
  [_uiManager prependUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    UIView *view = viewRegistry[reactTag];
    NSArray *transitionConfigs = [RCTConvert NSArray:config[@"transitions"]];
    for (id transitionConfig in transitionConfigs) {
      REATransition *transition = [REATransition inflate:transitionConfig];
      [self beginTransition:transition forView:view];
    }
  }];
  __weak id weakSelf = self;
  [_uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    [uiManager.observerCoordinator removeObserver:weakSelf];
  }];
}

@end

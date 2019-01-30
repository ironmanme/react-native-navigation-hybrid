//
//  HBDScreenNavigator.m
//  NavigationHybrid
//
//  Created by Listen on 2018/6/28.
//  Copyright © 2018年 Listen. All rights reserved.
//

#import "HBDScreenNavigator.h"
#import "HBDReactBridgeManager.h"
#import "HBDNavigationController.h"
#import "HBDModalViewController.h"
#import <React/RCTAssert.h>

@implementation HBDScreenNavigator

- (NSString *)name {
    return @"screen";
}

- (NSArray<NSString *> *)supportActions {
    return @[ @"present", @"presentLayout", @"dismiss", @"showModal", @"hideModal", @"clearModal", @"showModalLayout"];
}

- (UIViewController *)createViewControllerWithLayout:(NSDictionary *)layout {
    NSDictionary *screen = [layout objectForKey:self.name];
    if (screen) {
        NSString *moduleName = [screen objectForKey:@"moduleName"];
        NSDictionary *props = [screen objectForKey:@"props"];
        NSDictionary *options = [screen objectForKey:@"options"];
        return [[HBDReactBridgeManager sharedInstance] controllerWithModuleName:moduleName props:props options:options];
    }
    return nil;
}

- (BOOL)buildRouteGraphWithController:(UIViewController *)vc root:(NSMutableArray *)root {
    
    if ([vc isKindOfClass:[HBDModalViewController class]]) {
        HBDModalViewController *modal = (HBDModalViewController *)vc;
        [[HBDReactBridgeManager sharedInstance] buildRouteGraphWithController:modal.contentViewController root:root];
        return YES;
    }
    
    if ([vc isKindOfClass:[HBDViewController class]]) {
        HBDViewController *screen = (HBDViewController *)vc;
        [root addObject:@{
                          @"layout": @"screen",
                          @"sceneId": screen.sceneId,
                          @"moduleName": screen.moduleName ?: NSNull.null,
                          @"mode": [vc hbd_mode],
                          }];
        return YES;
    }

    return NO;
}

- (HBDViewController *)primaryViewControllerWithViewController:(UIViewController *)vc {
    if ([vc isKindOfClass:[HBDModalViewController class]]) {
        HBDModalViewController *modal = (HBDModalViewController *)vc;
        return [[HBDReactBridgeManager sharedInstance] primaryViewControllerWithViewController:modal.contentViewController];
    } else if ([vc isKindOfClass:[HBDViewController class]]) {
        return (HBDViewController *)vc;
    }
    return nil;
}

- (void)handleNavigationWithViewController:(UIViewController *)vc action:(NSString *)action extras:(NSDictionary *)extras {
    HBDViewController *target = nil;
    NSString *moduleName = [extras objectForKey:@"moduleName"];
    if (moduleName) {
        NSDictionary *props = [extras objectForKey:@"props"];
        NSDictionary *options = [extras objectForKey:@"options"];
        target =[[HBDReactBridgeManager sharedInstance] controllerWithModuleName:moduleName props:props options:options];
    }
    
    if ([action isEqualToString:@"present"]) {
        UIViewController *presented = vc.presentedViewController;
        RCTAssert(presented == nil, @"This scene has present another scene already. You could use Navigator.current() to gain the current navigator to do this job.");
        NSInteger requestCode = [[extras objectForKey:@"requestCode"] integerValue];
        BOOL animated = [[extras objectForKey:@"animated"] boolValue];
        HBDNavigationController *navVC = [[HBDNavigationController alloc] initWithRootViewController:target];
        navVC.modalPresentationStyle = UIModalPresentationCurrentContext;
        [navVC setRequestCode:requestCode];
        [vc beginAppearanceTransition:NO animated:animated];
        [vc endAppearanceTransition];
        [vc presentViewController:navVC animated:animated completion:^{
            
        }];
    } else if ([action isEqualToString:@"dismiss"]) {
        UIViewController *presenting = vc.presentingViewController;
        BOOL animated = [[extras objectForKey:@"animated"] boolValue];
        // make sure extra lifecycle excuting order
        [vc beginAppearanceTransition:NO animated:animated];
        [vc endAppearanceTransition];
        [presenting dismissViewControllerAnimated:animated completion:^{
            
        }];
    } else if ([action isEqualToString:@"showModal"]) {
        NSInteger requestCode = [[extras objectForKey:@"requestCode"] integerValue];
        [target setRequestCode:requestCode];
        [vc hbd_showViewController:target requestCode:requestCode animated:YES completion:nil];
    } else if ([action isEqualToString:@"hideModal"]) {
        [vc hbd_hideViewControllerAnimated:YES completion:nil];
    } else if ([action isEqualToString:@"clearModal"]) {
        UIApplication *application = [[UIApplication class] performSelector:@selector(sharedApplication)];
        for (NSUInteger i = application.windows.count; i > 0; i--) {
            UIWindow *window = application.windows[i-1];
            UIViewController *controller = window.rootViewController;
            if ([controller isKindOfClass:[HBDModalViewController class]]) {
                HBDModalViewController *modal = (HBDModalViewController *)controller;
                [modal.contentViewController hbd_hideViewControllerAnimated:NO completion:nil];
            }
        }
    } else if ([action isEqualToString:@"presentLayout"]) {
        UIViewController *presented = vc.presentedViewController;
        RCTAssert(presented == nil, @"This scene has present another scene already. You could use Navigator.current() to gain the current navigator to do this job.");
        NSDictionary *layout = [extras objectForKey:@"layout"];
        UIViewController *target = [[HBDReactBridgeManager sharedInstance] controllerWithLayout:layout];
        NSInteger requestCode = [[extras objectForKey:@"requestCode"] integerValue];
        BOOL animated = [[extras objectForKey:@"animated"] boolValue];
        [target setRequestCode:requestCode];
        target.modalPresentationStyle = UIModalPresentationCurrentContext;
        // make sure extra lifecycle excuting order
        [vc beginAppearanceTransition:NO animated:animated];
        [vc endAppearanceTransition];
        [vc presentViewController:target animated:animated completion:^{
            
        }];
    } else if ([action isEqualToString:@"showModalLayout"]) {
        NSDictionary *layout = [extras objectForKey:@"layout"];
        UIViewController *target = [[HBDReactBridgeManager sharedInstance] controllerWithLayout:layout];
        NSInteger requestCode = [[extras objectForKey:@"requestCode"] integerValue];
        [target setRequestCode:requestCode];
        [vc hbd_showViewController:target animated:YES completion:^(BOOL finished) {
            
        }];
    }
}

@end

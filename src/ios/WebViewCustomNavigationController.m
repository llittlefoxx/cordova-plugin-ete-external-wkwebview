//
//  WebViewCustomNavigationController.m
//  MO connect
//
//  Created by Mohamed ali Tlili on 06.09.18.
//

#import "WebViewCustomNavigationController.h"
#import "MainViewController.h"
#import "WebViewOverlayPlugin.h"

@interface WebViewCustomNavigationController ()

@end

@implementation WebViewCustomNavigationController

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    if (self.presentedViewController && ([self.presentedViewController isKindOfClass:[UIDocumentMenuViewController class]] || [self.presentedViewController isKindOfClass:[UIImagePickerController class]])) {
        [super dismissViewControllerAnimated:flag completion:completion];
    }
    if (self.allowDismiss && !self.presentedViewController && [self.presentingViewController isKindOfClass:[MainViewController class]] && self.childViewControllers.count == 1 && [self.childViewControllers[0] isKindOfClass:[WebViewOverlayViewController class]]) {
        [super dismissViewControllerAnimated:flag completion:completion];
    }
}

@end

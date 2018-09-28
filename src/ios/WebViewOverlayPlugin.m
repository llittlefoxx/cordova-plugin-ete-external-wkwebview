//  WebViewOverlayPlugin.m

#import "WebViewOverlayPlugin.h"
#import "CDVInAppBrowser.h"
#import "WebViewCustomNavigationController.h"
#import "CDVWKProcessPoolFactory.h"

@interface WebViewOverlayPlugin()

@property (nonatomic, weak) UINavigationController* internalNavigationController;
@property (nonatomic, weak) WebViewOverlayViewController* webViewController;


@end
@implementation WebViewOverlayPlugin

- (void)closeWebView {
    if (self.internalNavigationController) {
        [self.internalNavigationController dismissViewControllerAnimated:NO completion:nil];
    }
    self.webViewController = nil;
    self.internalNavigationController = nil;
}

- (void)open:(CDVInvokedUrlCommand*)command {
    
    self.callbackId = command.callbackId;
 NSLog(@"%@", self.callbackId);

    NSLog(@"WebViewOverlayPlugin :: open");
    NSString* urlString = command.arguments[0];
    NSString * webViewType = command.arguments[2];
    
    NSURL* url = [NSURL URLWithString:urlString];
    NSLog(@"URL -> :: %@",urlString);
    NSString* titleString = nil;
    
    if(![command.arguments[1] isEqualToString: @"no_title"]){
        titleString = command.arguments[1];
    }
    NSLog(@"title  -> :: %@",titleString);
    
    BOOL zoomCommandResult = YES;
    
    @try {
        if ([command.arguments[3] boolValue] == NO){
            zoomCommandResult = NO;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
    }
    
    NSLog(@"Zoomable  -> :: %d",zoomCommandResult);
    
    UINavigationController* navController;
    WebViewOverlayViewController* webViewController = [[WebViewOverlayViewController alloc] initWithURL:url Parameters:nil Zoom:zoomCommandResult];
    self.webViewController = webViewController;
    if (self.viewController.navigationController != nil) {
        navController = self.viewController.navigationController;
        [self.viewController.navigationController pushViewController:webViewController animated:NO];
    } else {
        webViewController.overlayDelegate = self;
        navController = [[WebViewCustomNavigationController alloc] initWithRootViewController:webViewController];
        self.internalNavigationController = navController;
        [self.viewController presentViewController:navController animated:NO completion:nil];
        NSLog(@"PRESENTED VC: %@", self.viewController.presentedViewController);
        NSLog(@"PRESENTED VC CLASS: %@", self.viewController.presentedViewController.class);
    }
    
    webViewController.commandDelegate = self.commandDelegate;
    webViewController.command = command;
    webViewController.title = titleString;
    
    if ([webViewType isEqualToString :@"simple"]){
        
        [navController setNavigationBarHidden : NO animated : NO];
        [navController setToolbarHidden : YES animated : NO];
        
    }else if ([webViewType isEqualToString :@"extended"]){
        
        [navController setNavigationBarHidden : NO animated : NO];
        [navController setToolbarHidden : NO animated : NO];
        
    }else if ([webViewType isEqualToString :@"fullscreen"]){
        
        [navController setNavigationBarHidden : YES animated : NO];
        [navController setToolbarHidden : YES animated : NO];
        
    }
    
    self.webViewController.navigationDelegate = self;
    self.webViewController.callbackIdCopy = self.callbackId;
    NSLog(@"%@", self.webViewController.callbackIdCopy);
}
- (void)didFinishNavigation1: (WKWebView*)theWebView
{/*
    if (self.callbackId != nil) {
        NSLog(@"LOAD STOPPED FULL %@",self.callbackId );
        // TODO: It would be more useful to return the URL the page is actually on (e.g. if it's been redirected).
        
        NSString* url = [theWebView.URL absoluteString];
       // [NSThread sleepForTimeInterval:0.5f];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"loadstop", @"url":url}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        NSLog(@"RESULT SENT TO PLUGIN  %@", pluginResult);
    }else {
        
        NSLog(@"LOAD STOPPED EMPTY  %@", self.callbackId);
    }*/
}
- (void)close:(CDVInvokedUrlCommand*)command {
    NSLog(@"WebViewOverlayPlugin :: close");
    
    [self.webViewController.navigationController dismissViewControllerAnimated:NO completion:nil];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)injectScript:(CDVInvokedUrlCommand*)command
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString* jsCode = [NSString stringWithFormat:@"%@", command.arguments[0]];
        
        // NSString* jsCodeCall = @"myFunction();";
        
        //[self.webViewController.webView stringByEvaluatingJavaScriptFromString:jsCode];
        [self.webViewController.webView evaluateJavaScript:jsCode completionHandler:^(id result, NSError *error) {
            if (error == nil) {
                if (result != nil) {
                    NSLog(@"%@", result);
                    NSData *objectData = [result dataUsingEncoding:NSUTF8StringEncoding];
                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData options:NSJSONReadingMutableContainers error:nil];
                    for (NSString* key in json.allKeys) {
                        NSLog(@"RESULT %@ = %@", key, json[key]);
                    }
                    
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"result": result}];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    
                }
            } else {
                NSLog(@"evaluateJavaScript error : %@ ", error.localizedDescription);
            }
        }];
        
    });
    
}
/*
 - (void)injectScript:(CDVInvokedUrlCommand*)command {
 NSString* js = command.arguments[0];
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
 [self.webViewController.webView stringByEvaluatingJavaScriptFromString:@"myFunction = function(){ return {a : \"Test\"};}"];
 NSString* result = [self.webViewController.webView stringByEvaluatingJavaScriptFromString:@"JSON.stringify(myFunction());"];
 NSLog(@"JS RESULT: %@", result);
 });
 }
 */

- (void)injectDeferredObject:(NSString*)source withWrapper:(NSString*)jsWrapper
{
    // Ensure an iframe bridge is created to communicate with the CDVInAppBrowserViewController
    [self.webViewController.webView evaluateJavaScript:@"(function(d){_cdvIframeBridge=d.getElementById('_cdvIframeBridge');if(!_cdvIframeBridge) {var e = _cdvIframeBridge = d.createElement('iframe');e.id='_cdvIframeBridge'; e.style.display='none';d.body.appendChild(e);}})(document)" completionHandler:^(id result, NSError *error) {
        if (error == nil) {
            if (result != nil) {
                NSLog(@"%@", result);
            }
        } else {
            NSLog(@"evaluateJavaScript error : %@ ", error.localizedDescription);
        }
    }];
    /*
     if (jsWrapper != nil) {
     NSData* jsonData = [NSJSONSerialization dataWithJSONObject:@[source] options:0 error:nil];
     NSString* sourceArrayString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
     if (sourceArrayString) {
     NSString* sourceString = [sourceArrayString substringWithRange:NSMakeRange(1, [sourceArrayString length] - 2)];
     NSString* jsToInject = [NSString stringWithFormat:jsWrapper, sourceString];
     [self.webViewController.webView stringByEvaluatingJavaScriptFromString:jsToInject];
     }
     } else {
     [self.webViewController.webView stringByEvaluatingJavaScriptFromString:source];
     }*/
}


@end

@interface WebViewOverlayViewController() <WKNavigationDelegate,WKUIDelegate,WKScriptMessageHandler>

@property (nonatomic, strong) UIBarButtonItem* buttonBack;
@property (nonatomic, strong) UIBarButtonItem* buttonNext;
@property ( nonatomic, readwrite ) BOOL zoomable;
@property (nonatomic, strong) NSURL* url;
@property (nonatomic, strong) NSArray* parameters;
- (NSString *)evaluateJavaScript:(NSString *)script;
@end

@implementation WebViewOverlayViewController

- (instancetype)initWithURL:(NSURL*)url Parameters:(NSArray*)parameters Zoom:(BOOL)zoomable{
    self = [super init];
    _url = url;
    _parameters = parameters;
    _zoomable=zoomable;
    [UIView setAnimationsEnabled:NO];
    return self;
}


//Synchronus helper for javascript evaluation

- (NSString *)evaluateJavaScript:(NSString *)script {
    __block NSString *resultString = nil;
    __block BOOL finished = NO;
    __block NSString* _script = script;
    
    [self.webView evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
        if (error == nil) {
            if (result != nil) {
                resultString = result;
                NSLog(@"%@", resultString);
            }
        } else {
            NSLog(@"evaluateJavaScript error : %@ : %@", error.localizedDescription, _script);
        }
        finished = YES;
    }];
    
    /* while (!finished)
     {
     [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
     }
     */
    return resultString;
}

- (void)webView:(WKWebView *)theWebView didFinishNavigation:(WKNavigation *)navigation
{
    [self.navigationDelegate didFinishNavigation1:theWebView];
  //
  /*
    if (self.title == nil){
        
        [self.webView evaluateJavaScript:@"document.title"  completionHandler:^(id result, NSError *error) {
            if (error == nil) {
                if (result != nil) {
                    self.title =result;
                    NSLog(@"%@", result);
                    [self updateToolbarButtons];
                }
            } else {
                NSLog(@"getting document.title error : %@ ", error.localizedDescription);
            }
        }];
    }
    
    if (self.callbackIdCopy != nil) {
        NSLog(@"LOAD STOPPED FULL %@",self.callbackIdCopy );
        // TODO: It would be more useful to return the URL the page is actually on (e.g. if it's been redirected).
        
        NSString* url = [theWebView.URL absoluteString];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"loadstop", @"url":url}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackIdCopy];
        NSLog(@"RESULT SENT TO PLUGIN  %@", pluginResult);
    }else {
        
        NSLog(@"LOAD STOPPED EMPTY  %@", self.callbackIdCopy);
    }
*/
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // [self.navigationController setToolbarHidden : YES animated : YES];
    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
    configuration.websiteDataStore = WKWebsiteDataStore.defaultDataStore;
    configuration.processPool = [[CDVWKProcessPoolFactory sharedFactory] sharedProcessPool];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
    
    //self.webView = [[WKWebView alloc] initWithFrame:self.view.frame];
    self.webView.scrollView.bounces = NO;
    [self.view addSubview:self.webView];
    [self.webView setBackgroundColor:[UIColor whiteColor]];
    [self.webView setOpaque:NO];
    NSLog(@"***** %d",self.zoomable);
   //yo self.webView.scalesPageToFit = self.zoomable;
    self.webView.autoresizingMask = self.view.autoresizingMask;
    [self.view addSubview:self.webView];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    
    [self configureWebView];
    self.webView.navigationDelegate = self;
}



- (void)configureWebView {
    
    UIImage * closeImage =[UIImage imageNamed :@"wvo_close"];
    UIImage * previousImage =[UIImage imageNamed :@"wvo_previous"];
    UIImage * nextImage =[UIImage imageNamed :@"wvo_next"];
    
    closeImage =[closeImage imageWithRenderingMode : UIImageRenderingModeAlwaysOriginal];
    previousImage =[previousImage imageWithRenderingMode : UIImageRenderingModeAlwaysOriginal];
    nextImage =[nextImage imageWithRenderingMode : UIImageRenderingModeAlwaysOriginal];
    
    UIBarButtonItem * buttonClose =[[UIBarButtonItem alloc]initWithImage : closeImage style : UIBarButtonItemStylePlain target : self  action :@selector(actionBack :)];
    buttonClose.tintColor = nil;
    self.navigationItem.leftBarButtonItem = buttonClose;
    
    self.buttonBack =[[UIBarButtonItem alloc] initWithImage : previousImage style : UIBarButtonItemStylePlain target : self action :@selector(navigateBack :)];
    
    self.buttonNext =[[UIBarButtonItem alloc]initWithImage : nextImage style : UIBarButtonItemStylePlain target : self action :@selector(navigateNext :)];
    
    self.toolbarItems = @[self.buttonBack, self.buttonNext];
    
    [self updateToolbarButtons];
}

/*
- (void)didFinishNavigation:(WKWebView*)theWebView
{
    if (self.callbackIdCopy != nil) {
        NSString* url = [theWebView.URL absoluteString];
        if(url == nil){
            url = @"";
        }
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"loadstop", @"url":url}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackIdCopy];
    }
}
/*
-(void)didFinishNavigation:(WKWebView*)theWebView {

    if (self.callbackIdCopy != nil) {
        // TODO: It would be more useful to return the URL the page is actually on (e.g. if it's been redirected).
        NSString* url = [self.url absoluteString];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"loadstop", @"url":url}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackIdCopy];
    }
    
    if (self.title == nil){
        
         [self.webView evaluateJavaScript:@"document.title"  completionHandler:^(id result, NSError *error) {
            if (error == nil) {
                if (result != nil) {
                    self.title =result;
                    NSLog(@"%@", result);
                    [self updateToolbarButtons];
                }
            } else {
                NSLog(@"getting document.title error : %@ ", error.localizedDescription);
            }
        }];
    }
}
*/

- (void)updateToolbarButtons {
    self.buttonBack.enabled = self.webView.canGoBack;
    self.buttonNext.enabled = self.webView.canGoForward;
}

- (void)navigateBack:(id)sender {
    [self.webView goBack];
}

- (void)navigateNext:(id)sender {
    [self.webView goForward];
}

- (void)actionBack:(id)sender {
    if ([self.navigationController isKindOfClass:[WebViewCustomNavigationController class]]) {
        ((WebViewCustomNavigationController*)self.navigationController).allowDismiss = YES;
    }
    if ([self.navigationController.viewControllers indexOfObject:self] != 0) {
        // we are pushed on a outer navigationcontroller and so we pop just ourself
        [self.navigationController popViewControllerAnimated:NO];
        [self.navigationController setNavigationBarHidden:YES animated:NO];
        [self.navigationController setToolbarHidden:YES animated:NO];
    } else {
        // we are the root and that is only possible if the navigation controller was manually generated in the plugin
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Successful in opening WebOverlayingPlugin"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
    }
}

- (void)dealloc {
    //yo self.webView.delegate = nil;
    [self.webView stopLoading];
}


// This selector is called when something is loaded in our webview
// By something I don't mean anything but just "some" :
//  - main html document
//  - sub iframes document
//
// But all images, xmlhttprequest, css, ... files/requests doesn't generate such events :/


- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL* url = navigationAction.request.URL;
    if ([[url scheme] isEqualToString:@"gap-iab"]) {
        NSString* scriptCallbackId = [url host];
        CDVPluginResult* pluginResult = nil;
        
        NSString* scriptResult = [url path];
        NSError* __autoreleasing error = nil;
        
        // The message should be a JSON-encoded array of the result of the script which executed.
        if ((scriptResult != nil) && ([scriptResult length] > 1)) {
            scriptResult = [scriptResult substringFromIndex:1];
            NSData* decodedResult = [NSJSONSerialization JSONObjectWithData:[scriptResult dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
            if ((error == nil) && [decodedResult isKindOfClass:[NSArray class]]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:(NSArray*)decodedResult];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION];
            }
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:@[]];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:scriptCallbackId];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    NSString *requestString = [[navigationAction.request URL] absoluteString];
    
    //NSLog(@"request : %@",requestString);
    
    if ([requestString hasPrefix:@"js-frame:"]) {
        
        NSArray *components = [requestString componentsSeparatedByString:@":"];
        
        NSString *function = (NSString*)[components objectAtIndex:1];
        if ([function isEqualToString:@"closeMeNow"])
        {
            [self.navigationController dismissViewControllerAnimated:NO completion:nil];
            
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Close function executed"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (BOOL)webView:(WKWebView *)webView2 shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSURL* url = request.URL;
    if ([[url scheme] isEqualToString:@"gap-iab"]) {
        NSString* scriptCallbackId = [url host];
        CDVPluginResult* pluginResult = nil;
        
        NSString* scriptResult = [url path];
        NSError* __autoreleasing error = nil;
        
        // The message should be a JSON-encoded array of the result of the script which executed.
        if ((scriptResult != nil) && ([scriptResult length] > 1)) {
            scriptResult = [scriptResult substringFromIndex:1];
            NSData* decodedResult = [NSJSONSerialization JSONObjectWithData:[scriptResult dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
            if ((error == nil) && [decodedResult isKindOfClass:[NSArray class]]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:(NSArray*)decodedResult];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION];
            }
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:@[]];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:scriptCallbackId];
        return NO;
    }
    
    NSString *requestString = [[request URL] absoluteString];
    
    //NSLog(@"request : %@",requestString);
    
    if ([requestString hasPrefix:@"js-frame:"]) {
        
        NSArray *components = [requestString componentsSeparatedByString:@":"];
        
        NSString *function = (NSString*)[components objectAtIndex:1];
        if ([function isEqualToString:@"closeMeNow"])
        {
            [self.navigationController dismissViewControllerAnimated:NO completion:nil];
            
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Close function executed"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
        }
        
        return NO;
    }
    
    return YES;
}


- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {

}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {

}

- (void)preferredContentSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container {

}

- (CGSize)sizeForChildContentContainer:(nonnull id<UIContentContainer>)container withParentContainerSize:(CGSize)parentSize {

}

- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container {
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
    
}

- (void)willTransitionToTraitCollection:(nonnull UITraitCollection *)newCollection withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
    
}

- (void)didUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context withAnimationCoordinator:(nonnull UIFocusAnimationCoordinator *)coordinator {
    
}

- (void)setNeedsFocusUpdate {
    
}

- (BOOL)shouldUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context {
    
}

- (void)updateFocusIfNeeded {
    
}

@end

//  WebViewOverlayPlugin.m

#import "WebViewOverlayPlugin.h"
#import "CDVInAppBrowser.h"
#import "WebViewCustomNavigationController.h"
#import "CDVWKProcessPoolFactory.h"

@interface WebViewOverlayPlugin()

@end
@implementation WebViewOverlayPlugin

- (void)closeWebView {
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
    if (self.viewController.navigationController != nil) {
        navController = self.viewController.navigationController;
        [self.viewController.navigationController pushViewController:webViewController animated:NO];
    } else {
        webViewController.overlayDelegate = self;
        navController = [[WebViewCustomNavigationController alloc] initWithRootViewController:webViewController];
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
    // CHANGED
    webViewController.navigationDelegate = self;
}
- (void)didFinishNavigation1: (WKWebView*)theWebView
{
    if (self.callbackId != nil) {
            // TODO: It would be more useful to return the URL the page is actually on (e.g. if it's been redirected).
            NSString* url = [theWebView URL].absoluteString;
            
            NSLog(@"Requested url: %@", url);
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsDictionary:@{@"type":@"loadstop", @"url":url}];
           [pluginResult setKeepCallbackAsBool:true];
            
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        
    }
}

- (void)close:(CDVInvokedUrlCommand*)command {
    NSLog(@"WebViewOverlayPlugin :: close");
    
    // CHANGED
    [self.viewController dismissViewControllerAnimated:NO completion:nil];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [pluginResult setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)hide:(CDVInvokedUrlCommand*)command
{
    
}
-(void)show:(CDVInvokedUrlCommand*)command
{
    [[self webViewController].webView becomeFirstResponder];
}
- (void)injectScript:(CDVInvokedUrlCommand*)command
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString* jsCode = [NSString stringWithFormat:@"%@", command.arguments[0]];
       
        [[self webViewController].webView evaluateJavaScript:jsCode completionHandler:^(id result, NSError *error) {
            if (error == nil) {
                if (result != nil) {
                    NSLog(@"%@", result);
                    NSData *objectData = [result dataUsingEncoding:NSUTF8StringEncoding];
                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData options:NSJSONReadingMutableContainers error:nil];
                    for (NSString* key in json.allKeys) {
                        NSLog(@"RESULT %@ = %@", key, json[key]);
                    }
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"result": result}];
                   [pluginResult setKeepCallbackAsBool:true];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }
            } else {
                NSLog(@"evaluateJavaScript error : %@ ", error.localizedDescription);
            }
        }];
        
    });
    
}
- (void)injectDeferredObject:(NSString*)source withWrapper:(NSString*)jsWrapper
{
    // Ensure an iframe bridge is created to communicate with the CDVInAppBrowserViewController
    // CHANGED
    [[self webViewController].webView evaluateJavaScript:@"(function(d){_cdvIframeBridge=d.getElementById('_cdvIframeBridge');if(!_cdvIframeBridge) {var e = _cdvIframeBridge = d.createElement('iframe');e.id='_cdvIframeBridge'; e.style.display='none';d.body.appendChild(e);}})(document)" completionHandler:^(id result, NSError *error) {
        if (error == nil) {
            if (result != nil) {
                NSLog(@"%@", result);
            }
        } else {
            NSLog(@"evaluateJavaScript error : %@ ", error.localizedDescription);
        }
    }];
}

- (void)dealloc
{
    NSLog(@"Gone - Custom Plugin");
}

#pragma mark - Getter webview
// CHANGED
- (WebViewOverlayViewController *)webViewController {
    return ((UINavigationController *)self.viewController.presentedViewController).viewControllers.firstObject;
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
    return resultString;
}

- (void)webView:(WKWebView *)theWebView didFinishNavigation:(WKNavigation *)navigation
{
    [self updateToolbarButtons];
    [self.navigationDelegate didFinishNavigation1:theWebView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
    configuration.websiteDataStore = WKWebsiteDataStore.defaultDataStore;
    configuration.processPool = [[CDVWKProcessPoolFactory sharedFactory] sharedProcessPool];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
    
    self.webView.scrollView.bounces = NO;
    [self.view addSubview:self.webView];
    [self.webView setBackgroundColor:[UIColor whiteColor]];
    [self.webView setOpaque:NO];
    NSLog(@"***** %d",self.zoomable);
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
        [self.navigationController dismissViewControllerAnimated:NO completion:nil];
    }
    if ([self.navigationController.viewControllers indexOfObject:self] != 0) {
        // we are pushed on a outer navigationcontroller and so we pop just ourself
        [self.navigationController popViewControllerAnimated:NO];
        [self.navigationController setNavigationBarHidden:YES animated:NO];
        [self.navigationController setToolbarHidden:YES animated:NO];
    } else {
        // we are the root and that is only possible if the navigation controller was manually generated in the plugin
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Successful in opening WebOverlayingPlugin"];
        [pluginResult setKeepCallbackAsBool:true];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
    }
}

- (void)dealloc {
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
        [pluginResult setKeepCallbackAsBool:true];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:scriptCallbackId];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    NSString *requestString = [[navigationAction.request URL] absoluteString];
    
    if ([requestString hasPrefix:@"js-frame:"]) {
        
        NSArray *components = [requestString componentsSeparatedByString:@":"];
        
        NSString *function = (NSString*)[components objectAtIndex:1];
        if ([function isEqualToString:@"closeMeNow"])
        {
            [self.navigationController dismissViewControllerAnimated:NO completion:nil];
            
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
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Successful in closing WebOverlayingPlugin"];
                [pluginResult setKeepCallbackAsBool:true];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
            }
        }
        if ([function isEqualToString:@"scanCode"])
        {
                // we are the root and that is only possible if the navigation controller was manually generated in the plugin
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"code_scanner"];
            [pluginResult setKeepCallbackAsBool:true];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
            
        }
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end

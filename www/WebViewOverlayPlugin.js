/**
 * Created by Mohamed ali Tlili
 * mohamedali.tlili@esprit.tn
 * mohamedali.tlili@etecture.de
 */

function WebViewOverlayPlugin() {};
/*
 *  urlString :
 *  String of the URL that you would like to open in an external webview.
 *
 *  webViewType :
 *  "simple" for a webview without navigation buttons.
 *  "extended" for a webview with navigation buttons.
 *  "fullscreen"for a webview without navigation and close button
 *
 *  titleString :
 *  String value that if you provide will be used as title for the ecternal webview.
 */
WebViewOverlayPlugin.prototype.open = function (successCallback, urlString, webViewType, titleString, zoom) {
    var params = [urlString];

    if (titleString != null) {
        params.push(titleString);
    }else{
        params.push("no_title");
    }
    if (webViewType != null) {
        params.push(webViewType);
    }
    if (zoom != null) {
        params.push(zoom);
    }
    cordova.exec(successCallback, null, 'WebViewOverlayPlugin', 'open', params);
};

// closing the external webview
WebViewOverlayPlugin.prototype.close = function() {
    cordova.exec(null, null, 'WebViewOverlayPlugin', 'close', []);
};
// closing the external webview
WebViewOverlayPlugin.prototype.close = function() {
    cordova.exec(null, null, 'WebViewOverlayPlugin', 'close', []);
};

WebViewOverlayPlugin.prototype.injectScript = function(codeToBeInjected, cb) {
    cordova.exec(cb, null, 'WebViewOverlayPlugin', 'injectScript', [codeToBeInjected.code, !!cb]);
};

// Attaching the webViewOverlay object to the window object
window.webViewOverlay = new WebViewOverlayPlugin();
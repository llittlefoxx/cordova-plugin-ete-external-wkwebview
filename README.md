# cordova-plugin-ete-external-web-pages
This is a Cordova plugin which opens, closes and injects js in a webview.

## Installation

    cordova plugin add cordova-plugin-ete-external-web-pages

## Platform 
iOS

## Usage
Using the plugin form your javascript code 

### Open an URL in an external browser 

```javascript
    webViewOverlay.open(successCallback, urlString, webViewType, titleString, zoomable);
```
Example :
```javascript
    webViewOverlay.open(
        function() {
      console.log("succeeded!")
    }, 
    "https://google.de", 
    "extended", 
    "My External Web view", 
    "false"
    );
```
#### parameters
* **urlString** : 
String of the URL that you would like to open in an external webview.

* **webViewType** :

"simple" for a webview without navigation buttons.


"extended" for a webview with navigation buttons.


"fullscreen"for a webview without navigation and close button
 
* **titleString** : 
String value that if you provide will be used as title for the external web view. 

This parameter is optional. If it is not specified, the title of the original page will be used.
The title will be only visible in the modes "extended" and "simple".


* **zoomable** :
This parameter is optional. By default, the external webview will be zoomable. if you want it to be not zoomable you should specify the zoom parameter to 'false'.

### Closing the external browser
Example :
 ```javascript
    webViewOverlay.close();
```


### Injecting js in the external browser
Example :
 ```javascript
        webViewOverlay.injectScript({
            code: "function() {return 'hello world'}"
        },
            function (res) {
                console.log(JSON.stringify(res));
            });
```

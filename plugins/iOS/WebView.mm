/*
 * Copyright (C) 2011 Keijiro Takahashi
 * Copyright (C) 2012 GREE, Inc.
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

#import <UIKit/UIKit.h>

extern UIViewController *UnityGetGLViewController();
extern "C" void UnitySendMessage(const char *, const char *, const char *);

@interface WebViewPlugin : NSObject<UIWebViewDelegate>
{
	UIWebView *webView;
	NSString *gameObjectName;
}
@property (nonatomic, retain) UIActivityIndicatorView *indicator;
@property (nonatomic, retain) UILabel *label;
@end

@implementation WebViewPlugin
@synthesize indicator = _indicator, label = _label;

- (id)initWithGameObjectName:(const char *)gameObjectName_
{
	self = [super init];
    
	UIView *view = UnityGetGLViewController().view;
	webView = [[UIWebView alloc] initWithFrame:view.frame];
	webView.delegate = self;
	webView.hidden = YES;
    webView.scrollView.alwaysBounceVertical = NO;
    webView.scrollView.delaysContentTouches = NO;
	[view addSubview:webView];
	gameObjectName = [[NSString stringWithUTF8String:gameObjectName_] retain];
    [self setScrollable:false];
	return self;
}


- (void)dealloc
{
    self.indicator = nil;
	[webView removeFromSuperview];
	[webView release];
	[gameObjectName release];
	[super dealloc];
}



- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSString *url = [[request URL] absoluteString];
    NSString *scheme = [[request URL] scheme];
    //NSLog(@"%@",[url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
	if ([scheme isEqualToString:@"dandg"]) {
		UnitySendMessage([gameObjectName UTF8String],
                         "CallFromJS", [url UTF8String]);
		return NO;
	}else if ([scheme isEqualToString:@"ohttp"]) {
        UnitySendMessage([gameObjectName UTF8String],
                         "CallFromJS", [[url substringFromIndex:6] UTF8String]);
		return NO;
    } else if ([scheme isEqualToString:@"ohttps"]) {
        UnitySendMessage([gameObjectName UTF8String],
                         "CallFromJS", [[url substringFromIndex:7]UTF8String]);
		return NO;
    }
    else {
		return YES;
	}
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self->webView.scrollView.hidden = YES;
    UIActivityIndicatorView *indicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
    indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    self.indicator = indicator;
    [self->webView addSubview:self.indicator];
    CGRect webViewBounds = self->webView.bounds;
    [indicator setCenter:CGPointMake(webViewBounds.size.width / 2, webViewBounds.size.height / 2)];
    [self.indicator startAnimating];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self->webView.bounds.size.width, self->webView.bounds.size.height * 0.7)];
    self.label = label;
    [self->webView addSubview:label];
    label.text = @"Loading...";
    [self setLabelStatusWithColor:[UIColor whiteColor] BackGroundColor:[UIColor colorWithWhite:1.0 alpha:0] Alignment:UITextAlignmentCenter Font:[UIFont fontWithName:@"HiraKakuProN-W6" size:16]];
    
    CGSize offset;
    offset.width = 1;
    offset.height = 1;
    [self setLabelShadowWithColor:[UIColor blackColor] Offset:offset];
    
    [label release];
}

-(void) setLabelStatusWithColor:(UIColor*)color BackGroundColor:(UIColor*)bgColor Alignment:(UITextAlignment) alignment Font:(UIFont*)font{
    self.label.textColor = color;
    self.label.backgroundColor = bgColor;
    self.label.textAlignment = alignment;
    self.label.font = font;
}

-(void) setLabelShadowWithColor:(UIColor*)color Offset:(CGSize) offset{
    self.label.shadowColor = color;
    self.label.shadowOffset = offset;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self->webView.scrollView.hidden = NO;
    [self.indicator stopAnimating];
    [self.indicator removeFromSuperview];
    [self.label removeFromSuperview];
    self.label = nil;
    self.indicator = nil;
}

- (void)setMargins:(int)left top:(int)top right:(int)right bottom:(int)bottom
{
	UIView *view = UnityGetGLViewController().view;
    
	CGRect frame = view.frame;
	CGFloat scale = view.contentScaleFactor;
	frame.size.width -= (left + right) / scale;
	frame.size.height -= (top + bottom) / scale;
	frame.origin.x += left / scale;
	frame.origin.y += top / scale;
	webView.frame = frame;
    
}

-(void)setBackground:(bool)opaque Color:(UIColor*)color
{
    webView.opaque = opaque;
    webView.backgroundColor = color;
}

- (void)setFrame:(int)x positionY:(int)y width:(int)width height:(int)height
{
    UIView* view = UnityGetGLViewController().view;
    CGRect frame = webView.frame;
    CGRect screen = view.bounds;
    frame.origin.x = x + ((screen.size.width - width)/2);
    frame.origin.y = -y + ((screen.size.height - height)/2);
    frame.size.width = width;
    frame.size.height = height;
    webView.frame = frame;
}

- (void)setVisibility:(BOOL)visibility
{
	webView.hidden = visibility ? NO : YES;
}
-(void)setScrollable:(BOOL)isScrollable
{
    webView.scrollView.scrollEnabled = isScrollable ? YES : NO;
}

-(void)reloadURL{
    [webView reload];
}

- (void)loadURL:(const char *)url
{
	NSString *urlStr = [NSString stringWithUTF8String:url];
	NSURL *nsurl = [NSURL URLWithString:urlStr];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]];
    [webView loadRequest:request];
	request = [NSURLRequest requestWithURL:nsurl];
	[webView loadRequest:request];
}

-(void)setBounceModeOfVertical:(bool)vertical Horizontal:(bool)horizontal{
    webView.scrollView.alwaysBounceVertical = vertical;
    webView.scrollView.alwaysBounceHorizontal = horizontal;
}

- (void)evaluateJS:(const char *)js
{
	NSString *jsStr = [NSString stringWithUTF8String:js];
	[webView stringByEvaluatingJavaScriptFromString:jsStr];
}

@end

extern "C" {
	void *_WebViewPlugin_Init(const char *gameObjectName);
	void _WebViewPlugin_Destroy(void *instance);
	void _WebViewPlugin_SetMargins(void *instance, int left, int top, int right, int bottom);
	void _WebViewPlugin_SetVisibility(void *instance, BOOL visibility);
	void _WebViewPlugin_LoadURL(void *instance, const char *url);
	void _WebViewPlugin_EvaluateJS(void *instance, const char *url);
    void _WebViewPlugin_SetFrame(void* instace,int x,int y,int width,int height);
    void _WebViewPlugin_SetBackgroundColor(void* instance,float r,float g,float b,float a,bool opaque);
    void _WebViewPlugin_SetScrollable(void* instance,bool scrollable);
    void _WebViewPlugin_ReloadURL(void* instance);
    void _WebViewPlugin_SetBounceMode(void* instance,bool vertical,bool horizontal);
    
}

void *_WebViewPlugin_Init(const char *gameObjectName)
{
	id instance = [[WebViewPlugin alloc] initWithGameObjectName:gameObjectName];
	return (void *)instance;
}

void _WebViewPlugin_Destroy(void *instance)
{
	WebViewPlugin *webViewPlugin = (WebViewPlugin *)instance;
	[webViewPlugin release];
}

void _WebViewPlugin_SetMargins(void *instance, int left, int top, int right, int bottom)
{
	WebViewPlugin *webViewPlugin = (WebViewPlugin *)instance;
	[webViewPlugin setMargins:left top:top right:right bottom:bottom];
}

void _WebViewPlugin_SetVisibility(void *instance, BOOL visibility)
{
	WebViewPlugin *webViewPlugin = (WebViewPlugin *)instance;
	[webViewPlugin setVisibility:visibility];
}

void _WebViewPlugin_LoadURL(void *instance, const char *url)
{
	WebViewPlugin *webViewPlugin = (WebViewPlugin *)instance;
	[webViewPlugin loadURL:url];
}

void _WebViewPlugin_EvaluateJS(void *instance, const char *js)
{
	WebViewPlugin *webViewPlugin = (WebViewPlugin *)instance;
	[webViewPlugin evaluateJS:js];
}

void _WebViewPlugin_SetFrame(void* instance,int x,int y,int width,int height)
{
    float screenScale = [ UIScreen instancesRespondToSelector:@selector( scale ) ]?
    [ UIScreen mainScreen ].scale:
    float(1);
    
    WebViewPlugin* webViewPlugin = (WebViewPlugin*)instance;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        if(screenScale == 2.0)
            screenScale = 1.0f;
    }
    [webViewPlugin setFrame:x/screenScale positionY:y/screenScale width:width/screenScale height: height/screenScale];
}

void _WebViewPlugin_SetBackgroundColor(void* instance,float r,float g,float b,float a,bool opaque)
{
    UIColor* color = [UIColor colorWithRed:r green:g blue:b alpha:a];
    WebViewPlugin* webViewPlugin = (WebViewPlugin*)instance;
    [webViewPlugin setBackground:opaque Color:color];
}

void _WebViewPlugin_SetScrollable(void* instance,bool scrollable){
    
    WebViewPlugin* webViewPlugin = (WebViewPlugin*) instance;
    [webViewPlugin setScrollable:scrollable];
}

void _WebViewPlugin_ReloadURL(void* instance){
    WebViewPlugin* webViewPlugin = (WebViewPlugin*) instance;
    [webViewPlugin reloadURL];
}

void _WebViewPlugin_SetBounceMode(void* instance,bool vertical,bool horizontal){
    WebViewPlugin* webViewPlugin = (WebViewPlugin*) instance;
    [webViewPlugin setBounceModeOfVertical:vertical Horizontal:horizontal];
}

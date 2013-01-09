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

#pragma mark - UIWebView Hacks for iOS

@interface UIWebView (ABGUIScrollViewHack)
@property (nonatomic, retain, readonly) UIScrollView *ABG_scrollView;
@end

@implementation UIWebView (ABGUIScrollViewHack)
- (UIScrollView *)ABG_scrollView
{
    if ([self respondsToSelector:@selector(scrollView)]) {
        return [self scrollView];
    }
    
    for (id subview in self.subviews) {
        if ([[subview class] isSubclassOfClass: [UIScrollView class]]) {
            return subview;
        }
    }
    
    return nil;
}
@end

#pragma mark - Objective-C Implementation

@interface WebViewPlugin : NSObject<UIWebViewDelegate>
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSString *gameObjectName;
@property (nonatomic, retain) UIActivityIndicatorView *indicator;
@property (nonatomic, retain) UILabel *label;
@end

@implementation WebViewPlugin

- (id)initWithGameObjectName:(const char *)gameObjectName_
{
    self = [super init];
    
    UIView *view = UnityGetGLViewController().view;
    self.webView = [[UIWebView alloc] initWithFrame:view.frame];
    self.webView.delegate = self;
    self.webView.hidden = YES;
    self.webView.ABG_scrollView.alwaysBounceVertical = NO;
    [view addSubview:self.webView];
    self.gameObjectName = [[NSString stringWithUTF8String:gameObjectName_] retain];
    [self setScrollable:false];
    return self;
}

- (void)dealloc
{
    self.indicator = nil;
    [self.webView removeFromSuperview];
    [self.webView release];
    [self.gameObjectName release];
    [super dealloc];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *url = [[request URL] absoluteString];
    NSString *scheme = [[request URL] scheme];
    if ([scheme isEqualToString:@"dandg"]) {
        UnitySendMessage([self.gameObjectName UTF8String],
                         "CallFromJS", [[url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] UTF8String]);
        return NO;
    }else if ([scheme isEqualToString:@"ohttp"]) {
        UnitySendMessage([self.gameObjectName UTF8String],
                         "CallFromJS", [[[url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] substringFromIndex:6] UTF8String]);
        return NO;
    } else if ([scheme isEqualToString:@"ohttps"]) {
        UnitySendMessage([self.gameObjectName UTF8String],
                         "CallFromJS", [[[url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] substringFromIndex:7]UTF8String]);
        return NO;
    }
    else {
        return YES;
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.webView.ABG_scrollView.hidden = YES;
    UIActivityIndicatorView *indicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
    indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    self.indicator = indicator;
    [self.webView addSubview:self.indicator];
    CGRect webViewBounds = self.webView.bounds;
    [indicator setCenter:CGPointMake(webViewBounds.size.width / 2, webViewBounds.size.height / 2)];
    [self.indicator startAnimating];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.webView.bounds.size.width, self.webView.bounds.size.height * 0.7)];
    self.label = label;
    [self.webView addSubview:label];
    label.text = @"Loading...";
    [self setLabelStatusWithColor:[UIColor whiteColor] BackGroundColor:[UIColor colorWithWhite:1.0 alpha:0] Alignment:UITextAlignmentCenter Font:[UIFont fontWithName:@"HiraKakuProN-W6" size:16]];
    
    CGSize offset;
    offset.width = 1;
    offset.height = 1;
    [self setLabelShadowWithColor:[UIColor blackColor] Offset:offset];
    
    [label release];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.webView.ABG_scrollView.hidden = NO;
    [self.indicator stopAnimating];
    [self.indicator removeFromSuperview];
    [self.label removeFromSuperview];
    self.label = nil;
    self.indicator = nil;
}

- (void)loadURL:(const char *)url
{
    NSString *urlStr = [NSString stringWithUTF8String:url];
    NSURL *nsurl = [NSURL URLWithString:urlStr];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]];
    [self.webView loadRequest:request];
    request = [NSURLRequest requestWithURL:nsurl];
    [self.webView loadRequest:request];
}

-(void)reloadURL{
    [self.webView reload];
}

- (void)evaluateJS:(const char *)js
{
    NSString *jsStr = [NSString stringWithUTF8String:js];
    [self.webView stringByEvaluatingJavaScriptFromString:jsStr];
}

- (void)setVisibility:(BOOL)visibility
{
    self.webView.hidden = visibility ? NO : YES;
}

-(void)setScrollable:(BOOL)isScrollable
{
    self.webView.ABG_scrollView.scrollEnabled = isScrollable ? YES : NO;
}

-(void)setBounceModeOfVertical:(BOOL)vertical Horizontal:(BOOL)horizontal{
    self.webView.ABG_scrollView.alwaysBounceVertical = vertical;
    self.webView.ABG_scrollView.alwaysBounceHorizontal = horizontal;
}

-(void)setDelaysContentTouchesEnable:(BOOL) deferrable{
    self.webView.ABG_scrollView.delaysContentTouches = deferrable;
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

-(void)setBackground:(BOOL)opaque Color:(UIColor*)color
{
    self.webView.opaque = opaque;
    self.webView.backgroundColor = color;
}

- (void)setFrame:(NSInteger)x positionY:(NSInteger)y width:(NSInteger)width height:(NSInteger)height
{
    UIView* view = UnityGetGLViewController().view;
    CGRect frame = self.webView.frame;
    CGRect screen = view.bounds;
    frame.origin.x = x + ((screen.size.width - width)/2);
    frame.origin.y = -y + ((screen.size.height - height)/2);
    frame.size.width = width;
    frame.size.height = height;
    self.webView.frame = frame;
}

- (void)setMargins:(NSInteger)left top:(NSInteger)top right:(NSInteger)right bottom:(NSInteger)bottom
{
    UIView *view = UnityGetGLViewController().view;
    
    CGRect frame = view.frame;
    CGFloat scale = view.contentScaleFactor;
    frame.size.width -= (left + right) / scale;
    frame.size.height -= (top + bottom) / scale;
    frame.origin.x += left / scale;
    frame.origin.y += top / scale;
    self.webView.frame = frame;
    
}

@end

#pragma mark - Unity Plugin

extern "C" {
    void *_WebViewPlugin_Init(const char *gameObjectName);
    void _WebViewPlugin_Destroy(void *instance);
    void _WebViewPlugin_LoadURL(void *instance, const char *url);
    void _WebViewPlugin_ReloadURL(void* instance);
    void _WebViewPlugin_EvaluateJS(void *instance, const char *url);
    void _WebViewPlugin_SetVisibility(void *instance, BOOL visibility);
    void _WebViewPlugin_SetBackgroundColor(void* instance,CGFloat r,CGFloat g,CGFloat b,CGFloat a,BOOL opaque);
    void _WebViewPlugin_SetScrollable(void* instance,BOOL scrollable);
    void _WebViewPlugin_SetBounceMode(void* instance,BOOL vertical,BOOL horizontal);
    void _WebViewPlugin_SetDelaysTouchEnable(void* instance,BOOL deferrable );
    void _WebViewPlugin_SetFrame(void* instace,NSInteger x,NSInteger y,NSInteger width,NSInteger height);
    void _WebViewPlugin_SetMargins(void *instance, NSInteger left, NSInteger top, NSInteger right, NSInteger bottom);
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

void _WebViewPlugin_LoadURL(void *instance, const char *url)
{
    WebViewPlugin *webViewPlugin = (WebViewPlugin *)instance;
    [webViewPlugin loadURL:url];
}
void _WebViewPlugin_ReloadURL(void* instance){
    WebViewPlugin* webViewPlugin = (WebViewPlugin*) instance;
    [webViewPlugin reloadURL];
}

void _WebViewPlugin_EvaluateJS(void *instance, const char *js)
{
    WebViewPlugin *webViewPlugin = (WebViewPlugin *)instance;
    [webViewPlugin evaluateJS:js];
}

void _WebViewPlugin_SetVisibility(void *instance, BOOL visibility)
{
    WebViewPlugin *webViewPlugin = (WebViewPlugin *)instance;
    [webViewPlugin setVisibility:visibility];
}

void _WebViewPlugin_SetBackgroundColor(void* instance,CGFloat r,CGFloat g,CGFloat b,CGFloat a,BOOL opaque)
{
    UIColor* color = [UIColor colorWithRed:r green:g blue:b alpha:a];
    WebViewPlugin* webViewPlugin = (WebViewPlugin*)instance;
    [webViewPlugin setBackground:opaque Color:color];
}

void _WebViewPlugin_SetScrollable(void* instance,BOOL scrollable){
    
    WebViewPlugin* webViewPlugin = (WebViewPlugin*) instance;
    [webViewPlugin setScrollable:scrollable];
}

void _WebViewPlugin_SetBounceMode(void* instance,BOOL vertical,BOOL horizontal){
    WebViewPlugin* webViewPlugin = (WebViewPlugin*) instance;
    [webViewPlugin setBounceModeOfVertical:vertical Horizontal:horizontal];
}

void _WebViewPlugin_SetDelaysTouchEnable(void* instance,BOOL deferrable){
    WebViewPlugin* webViewPlugin = (WebViewPlugin*) instance;
    [webViewPlugin setDelaysContentTouchesEnable:deferrable];
}

void _WebViewPlugin_SetFrame(void* instance,NSInteger x,NSInteger y,NSInteger width,NSInteger height)
{
    float screenScale = [ UIScreen instancesRespondToSelector:@selector( scale ) ]?
    [ UIScreen mainScreen ].scale:1.0f;
    
    WebViewPlugin* webViewPlugin = (WebViewPlugin*)instance;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        if(screenScale == 2.0)
            screenScale = 1.0f;
    }
    [webViewPlugin setFrame:x/screenScale positionY:y/screenScale width:width/screenScale height: height/screenScale];
}

void _WebViewPlugin_SetMargins(void *instance, NSInteger left, NSInteger top, NSInteger right, NSInteger bottom)
{
    WebViewPlugin *webViewPlugin = (WebViewPlugin *)instance;
    [webViewPlugin setMargins:left top:top right:right bottom:bottom];
}

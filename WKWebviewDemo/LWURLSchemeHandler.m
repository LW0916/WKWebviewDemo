//
//  LWURLSchemeHandler.m
//  WKWebviewDemo
//
//  Created by lwmini on 2018/9/13.
//  Copyright © 2018年 lw. All rights reserved.
//

#import "LWURLSchemeHandler.h"

@implementation LWURLSchemeHandler
#pragma mark -- WKURLSchemeHandler
- (void)webView:(WKWebView *)webView startURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask API_AVAILABLE(ios(11.0)){
    NSLog(@"startURLSchemeTask==>%@",urlSchemeTask.request.URL.absoluteString);
}
- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask API_AVAILABLE(ios(11.0)){
    NSLog(@"stopURLSchemeTask==>%@",urlSchemeTask.request.URL.absoluteString);
}

@end

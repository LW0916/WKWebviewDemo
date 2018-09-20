//
//  LWScriptMessageHandler.m
//  WKWebviewDemo
//
//  Created by lwmini on 2018/9/13.
//  Copyright © 2018年 lw. All rights reserved.
//

#import "LWScriptMessageHandler.h"

@implementation LWScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    NSLog(@"%sbody===>%@ name===>%@",__func__,message.body,message.name);
}

@end

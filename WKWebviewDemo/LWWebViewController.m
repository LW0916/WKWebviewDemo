//
//  LWWebViewController.m
//  WKWebviewDemo
//
//  Created by lwmini on 2018/9/13.
//  Copyright © 2018年 lw. All rights reserved.
//

#import "LWWebViewController.h"
#import <WebKit/WebKit.h>
#import "LWScriptMessageHandler.h"
#import "LWURLSchemeHandler.h"

/*
 WKWebView：网页的渲染与展示，通过WKWebViewConfiguration可以进行配置。
 
 WKWebViewConfiguration：这个类专门用来配置WKWebView。
 
 WKPreference:这个类用来进行M相关设置。
 
 WKProcessPool：这个类用来配置进程池，与网页视图的资源共享有关。
 
 WKUserContentController：这个类主要用来做native与JavaScript的交互管理。
 
 WKUserScript：用于进行JavaScript注入。
 
 WKScriptMessageHandler：这个类专门用来处理JavaScript调用native的方法。
 
 WKNavigationDelegate：网页跳转间的导航管理协议，这个协议可以监听网页的活动。
 
 WKNavigationAction：网页某个活动的示例化对象。
 
 WKUIDelegate：用于交互处理JavaScript中的一些弹出框。
 
 WKBackForwardList：堆栈管理的网页列表。
 
 WKBackForwardListItem：每个网页节点对象。
 
*/
@interface LWWebViewController ()<WKNavigationDelegate,WKUIDelegate>

@property(nonatomic,strong)WKWebView *webView;
@property(nonatomic,strong)UIProgressView *progressView;
@property(nonatomic,strong)UIButton *backBtn;
@property(nonatomic,strong)UIButton *goForwardBtn;
@property(nonatomic,strong)WKWebViewConfiguration *webviewConfig;

@end

@implementation LWWebViewController
- (void)dealloc{
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}
#pragma mark -- getter

-(UIButton *)backBtn
{
    if (!_backBtn) {
        _backBtn=[UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setTitle:@"返回" forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}
-(UIButton *)goForwardBtn
{
    if (!_goForwardBtn) {
        _goForwardBtn=[UIButton buttonWithType:UIButtonTypeCustom];
        [_goForwardBtn setTitle:@"前进" forState:UIControlStateNormal];
        [_goForwardBtn addTarget:self action:@selector(goForwardBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    return _goForwardBtn;
}
- (WKWebView *)webView{
    if (_webView == nil) {
        _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:self.webviewConfig];
        _webView.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _webView.navigationDelegate = self;
        _webView.UIDelegate = self;
    }
    return _webView;
}
- (WKWebViewConfiguration *)webviewConfig{
    if (_webviewConfig == nil) {
         _webviewConfig = [[WKWebViewConfiguration alloc] init];
        //Web内容进程池。
        WKProcessPool *processPool = [[WKProcessPool alloc]init];
        _webviewConfig.processPool = processPool;
        //进行偏好设置
        WKPreferences *preferences = [[WKPreferences alloc]init];
        preferences.javaScriptCanOpenWindowsAutomatically = YES;
        preferences.minimumFontSize = 0; //最小字体大小 当将javaScriptEnabled属性设置为false时，可以看到明显的效果
        preferences.javaScriptEnabled = YES;//设置是否支持javaScript 默认是支持的
        preferences.javaScriptCanOpenWindowsAutomatically = true;//(设置是否允许不经过用户交互由javaScript自动打开窗口) 很重要，如果没有设置这个则不会回调createWebViewWithConfiguration方法，也不会回应window.open()方法
        _webviewConfig.preferences = preferences;
        
        _webviewConfig.suppressesIncrementalRendering = NO; //设置是否将网页内容全部加载到内存后再渲染
        _webviewConfig.allowsInlineMediaPlayback = YES; //设置HTML5视频是否允许网页播放 设置为false则会使用本地播放器
        _webviewConfig.allowsAirPlayForMediaPlayback = YES; //设置是否允许ariPlay播放
        if (@available(iOS 10.0, *)) {
            _webviewConfig.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeAll;
        } else {
            _webviewConfig.requiresUserActionForMediaPlayback = NO ;//ios9 设置视频是否需要用户手动播放  设置为false则会允许自动播放
        }
        _webviewConfig.allowsPictureInPictureMediaPlayback = YES; //设置是否允许画中画技术 在特定设备上有效
        _webviewConfig.selectionGranularity= WKSelectionGranularityDynamic;//设置选择模式 是按字符选择 还是按模块选择
        _webviewConfig.applicationNameForUserAgent = @"WKWebviewDemo";//设置请求的User-Agent信息中应用程序名称 iOS9后可用
        if (@available(iOS 10.0, *)) {
            _webviewConfig.dataDetectorTypes = WKDataDetectorTypeAll;//设置了该属性，系统可以自动检测电话、链接、地址、日历、邮箱。并且可以点击，当点击的时候可以在API中自定义事件
            _webviewConfig.ignoresViewportScaleLimits = NO;//覆盖用户可伸缩属性。

        } else {
            // Fallback on earlier versions
        }
        if (@available(iOS 11.0, *)) {
            [_webviewConfig setURLSchemeHandler:[LWURLSchemeHandler new] forURLScheme:@"mobile-service"];
        } else {
            // Fallback on earlier versions
        }
        //  处理与js的交互
        WKUserContentController *userContent = [[WKUserContentController alloc]init];
        [userContent addScriptMessageHandler:[LWScriptMessageHandler new] name:@"name"];//添加一个名称为name的WKScriptMessageHandler将会导致在所有使用该WKScriptMessageHandler的WebView的所有frame中定义一个JavaScript函数window.webkit.messageHandlers.name.postMessage(messageBody)
        WKUserScript *userScript = [[WKUserScript alloc]initWithSource:@"function userFunc(){window.webkit.messageHandlers.name.postMessage( {\"name\":\"haha\"})}" injectionTime:(WKUserScriptInjectionTimeAtDocumentEnd) forMainFrameOnly:NO];
        [userContent addUserScript:userScript];//添加一个WKUserScript
//        [userContent removeAllUserScripts];//移除所有的WKUserScript
//        [userContent removeScriptMessageHandlerForName:@"name"];//移除name名字的WKScriptMessageHandler
        NSLog(@"%@",userContent.userScripts); //关联的所有WKScriptMessageHandler
        _webviewConfig.userContentController = userContent;
        _webviewConfig.websiteDataStore = [WKWebsiteDataStore defaultDataStore];
    }
    return _webviewConfig;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *backBtn =[[UIBarButtonItem alloc]initWithCustomView:self.backBtn];
    self.navigationItem.leftBarButtonItem=backBtn;
    UIBarButtonItem *goBtn =[[UIBarButtonItem alloc]initWithCustomView:self.goForwardBtn];
    self.navigationItem.rightBarButtonItem=goBtn;
    [self.view addSubview:self.webView];
    self.progressView = [[UIProgressView alloc]initWithFrame:CGRectMake(0, 64, CGRectGetWidth(self.view.frame), 2)];
    self.progressView.progressTintColor = [UIColor greenColor];
    [self.view addSubview:self.progressView];
    // 给webview添加进度条监听
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];

    [self loadLocalBlueFile];

}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqual:@"estimatedProgress"] && object == self.webView) {
        [self.progressView setAlpha:1.0f];
        [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
        if (self.webView.estimatedProgress  >= 1.0f) {
            [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:YES];
            }];
        }
    }else if([keyPath isEqual:@"title"] && object == self.webView){
        self.navigationItem.title = self.webView.title;
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
- (void)testCookie{
    /*defaultDataStore:返回默认的WKWebsiteDataStore
     nonPersistentDataStore:返回一个新的非持久化的WKWebsiteDataStore
     如果一个WebView关联了一个非持久化的WKWebsiteDataStore，将不会有数据被写入到文件系统
     该特性可以用来实现隐私浏览
     nonPersistentDataStore用于实现私密的浏览器，即该浏览器的数据与其他WebView不共享。苹果本质的意愿应该是一个WKWebView和一个nonPersistentDataStore的绑定。以前的策略应该是多个WKWebView可以和一个non-persistent的datastore绑定。只要它和普通的datastore隔离即可。
     persistent:是否是非持久化的
     httpCookieStore:
     allWebsiteDataTypes:获取所有可用的数据类型 网站数据类型定义 Available Data Types
     
     WKHTTPCookieStore:管理与特定的WKWebsiteDataStore关联的HTTP cookie的对象
     - (void)getAllCookies:(void (^)(NSArray<NSHTTPCookie *> *))completionHandler; 获取所有的cookies
     - (void)setCookie:(NSHTTPCookie *)cookie completionHandler:(void (^)(void))completionHandler; 设置一个cookie
     - (void)deleteCookie:(NSHTTPCookie *)cookie completionHandler:(void (^)(void))completionHandler; 移除一个cookie
     
     添加一个WKHTTPCookieStoreObserver观察者
     - (void)addObserver:(id<WKHTTPCookieStoreObserver>)observer;
     WKHTTPCookieStore不会强引用持有该observer
     你应当在不用observer的时候主动将其移除掉
     移除一个WKHTTPCookieStoreObserver
     - (void)removeObserver:(id<WKHTTPCookieStoreObserver>)observer;
     
     WKHTTPCookieStoreObserver
     当WKHTTPCookieStore的cookies发生变化时调用
     - (void)cookiesDidChangeInCookieStore:(WKHTTPCookieStore *)cookieStore;
     
     */
    //移除网页缓存
    NSSet *websiteDataTypes = [NSSet setWithArray:@[WKWebsiteDataTypeDiskCache]];
    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
        
    }];
    //获取包含给定网站数据类型的数据记录。
    NSSet *dataRecordsOfTypes = [NSSet setWithArray:@[WKWebsiteDataTypeCookies]];
    [[WKWebsiteDataStore defaultDataStore] fetchDataRecordsOfTypes:dataRecordsOfTypes completionHandler:^(NSArray<WKWebsiteDataRecord *> * _Nonnull array) {
        NSLog(@"%@",array);
    }];
}
#pragma mark -- 加载文件
- (void)loadRequestWithURL{
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com"] cachePolicy:(NSURLRequestReloadIgnoringLocalAndRemoteCacheData) timeoutInterval:3.0];
    [self.webView loadRequest:request];
}
//加载本地文件蓝色文件夹下面的文件
- (void)loadLocalBlueFile {
    NSString *bundleFile = [[NSBundle mainBundle] pathForResource:@"LocalFile" ofType:nil];
    NSString *htmlFile = [bundleFile stringByAppendingPathComponent:@"/index.html"];
    NSData *htmlData = [NSData dataWithContentsOfFile:htmlFile];
    [self.webView loadData:htmlData MIMEType:@"text/html" characterEncodingName:@"UTF-8" baseURL:[NSURL fileURLWithPath:bundleFile]];
}
//加载本地文件
- (void)loadLocalFile{
    //mainBundle下面的调用逻辑
    NSString *path = [[NSBundle mainBundle] pathForResource:@"index2" ofType:@"html"];
    if(path){
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
            // iOS9. One year later things are OK.
            NSURL *fileURL = [NSURL fileURLWithPath:path];
            [self.webView loadFileURL:fileURL allowingReadAccessToURL:fileURL];
        } else {
            // iOS8. Things can be workaround-ed
            //   Brave people can do just this
            //   fileURL = try! pathForBuggyWKWebView8(fileURL)
            //   webView.loadRequest(NSURLRequest(URL: fileURL))
            NSURL *fileURL = [self fileURLForBuggyWKWebView8:[NSURL fileURLWithPath:path]];
            NSURLRequest *request = [NSURLRequest requestWithURL:fileURL];
            [self.webView loadRequest:request];
        }
    }
}
//将文件copy到tmp目录
- (NSURL *)fileURLForBuggyWKWebView8:(NSURL *)fileURL {
    NSError *error = nil;
    if (!fileURL.fileURL || ![fileURL checkResourceIsReachableAndReturnError:&error]) {
        return nil;
    }
    // Create "/temp/www" directory
    NSFileManager *fileManager= [NSFileManager defaultManager];
    NSURL *temDirURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"www"];
    [fileManager createDirectoryAtURL:temDirURL withIntermediateDirectories:YES attributes:nil error:&error];
    
    NSURL *dstURL = [temDirURL URLByAppendingPathComponent:fileURL.lastPathComponent];
    // Now copy given file to the temp directory
    [fileManager removeItemAtURL:dstURL error:&error];
    [fileManager copyItemAtURL:fileURL toURL:dstURL error:&error];
    // Files in "/temp/www" load flawlesly :)
    return dstURL;
}

#pragma mark - ClickMethods
- (void)backBtnClicked{
    NSLog(@"backForwardList===>%@",self.webView.backForwardList);
//    goToBackForwardListItem 能返回之前的某个item
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}
- (void)goForwardBtnClicked{
    if ([self.webView canGoForward]) {
        [self.webView goForward];
    }
}
#pragma mark -- WKNavigationDelegate
/// 1 在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    NSString *requestString = navigationAction.request.URL.absoluteString;
    NSLog(@"decidePolicyForNavigationAction=requestString:%@",requestString);
    WKNavigationActionPolicy actionPolicy = WKNavigationActionPolicyAllow;
    if([requestString hasPrefix:@"aaa"]){
        actionPolicy = WKNavigationActionPolicyCancel;
    }
    //这句是必须加上的，不然会异常
    decisionHandler(actionPolicy);
}
/// 3 在收到服务器的响应头，根据response相关信息，决定是否跳转。decisionHandler必须调用，来决定是否跳转，参数WKNavigationResponsePolicyCancel取消跳转，WKNavigationResponsePolicyAllow允许跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    //获取请求的url路径
    NSString *requestString = navigationResponse.response.URL.absoluteString;
    NSLog(@"decidePolicyForNavigationResponse=requestString:%@",requestString);
    // 遇到要做出改变的字符串
    NSString *subStr = @"22222";
    WKNavigationResponsePolicy actionPolicy = WKNavigationResponsePolicyAllow;
    if ([requestString rangeOfString:subStr].location != NSNotFound) {
        NSLog(@"这个字符串中有subStr");
        actionPolicy = WKNavigationResponsePolicyCancel;
    }
    decisionHandler(actionPolicy);
    
}
/// 2 页面开始加载
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation{
    NSLog(@"%s",__func__);
    
}
/// 接收到服务器跳转请求之后调用 (服务器端redirect)，不一定调用
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation{
    NSLog(@"%s",__func__);
    
}
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error{
    NSLog(@"%s",__func__);
    
}
/// 4 开始获取到网页内容时返回
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation{
    NSLog(@"%s",__func__);
    
}
/// 5 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation{
    NSLog(@"%s",__func__);
}
/// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error{
    NSLog(@"%s error==》%@",__func__,error.description);
    
}
/*
 WKWebView加载HTTPS的链接
 HTTPS已经越来越被重视，前面我也写过一系列的HTTPS的相关文章HTTPS从原理到应用(四)：iOS中HTTPS实际使用当加载一些HTTPS的页面的时候，如果此网站使用的根证书已经内置到了手机中这些HTTPS的链接可以正常的通过验证并正常加载。但是如果使用的证书(一般为自建证书)的根证书并没有内置到手机中，这时是链接是无法正常加载的，必须要做一个权限认证。开始在UIWebView的时候，是把请求存储下来然后使用NSURLConnection去重新发起请求，然后走NSURLConnection的权限认证通道，认证通过后，在使用UIWebView去加载这个请求。
 这个方法比原来UIWebView的认证简单的多。但是使用中却发现了一个很蛋疼的问题，iOS8系统下，自建证书的HTTPS链接，不调用此代理方法。查来查去，原来是一个bug，在iOS9中已经修复，这明显就是不管iOS8的情况了，而且此方法也没有标记在iOS9中使用，这点让我感到有点失望。这样我就又想到了换回原来UIWebView的权限认证方式，但是试来试去，发现也不能使用了。所以关于自建证书的HTTPS链接在iOS8下面使用WKWebView加载，我没有找到很好的办法去解决此问题。这样我不得已有些链接换回了HTTP，或者在iOS8下面在换回UIWebView。
 */
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    NSLog(@"https验证%s",__func__);
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([challenge previousFailureCount] == 0) {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        } else {
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
    } else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
}
//当 WKWebView 总体内存占用过大，页面即将白屏的时候，系统会调用上面的回调函数，我们在该函数里执行[webView reload](这个时候 webView.URL 取值尚不为 nil）解决白屏问题。在一些高内存消耗的页面可能会频繁刷新当前页面，H5侧也要做相应的适配操作。
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
    NSLog(@"%s",__func__);
    if (webView.URL != nil) {
        [webView reload];
    }
}
#pragma mark - WKUIDelegate
//1.创建一个新的WebVeiw
// 可以指定配置对象、导航动作对象、window特性
- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"createWebViewWithConfiguration  request     %@",navigationAction.request);
    if (!navigationAction.targetFrame.isMainFrame || navigationAction.targetFrame == nil) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}
//2.WebVeiw关闭（9.0中的新方法） window.close()
- (void)webViewDidClose:(WKWebView *)webView{
    NSLog(@"%s", __FUNCTION__);
    [self.navigationController popViewControllerAnimated:YES];
}
//3.显示一个JS的Alert（与JS交互）
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    NSLog(@"%s", __FUNCTION__);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    [self presentViewController:alert animated:YES completion:NULL];
    NSLog(@"%@", message);
}
//4.弹出一个输入框（与JS交互的）
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler{
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"%@", prompt);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"prompt" message:prompt preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *_Nonnull textField) {
        textField.textColor = [UIColor redColor];
        textField.placeholder = defaultText;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler([[alert.textFields lastObject] text]);
        
    }]];
    [self presentViewController:alert animated:YES completion:NULL];
}
//5.显示一个确认框（JS的）
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler{
    NSLog(@"%s", __FUNCTION__);
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"confirm" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    [self presentViewController:alert animated:YES completion:NULL];
    NSLog(@"%@", message);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end


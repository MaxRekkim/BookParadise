#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

// MARK: - Кастомный URL Scheme Handler для надежной загрузки React/Vite без CORS-блокировок
@interface AppSchemeHandler : NSObject <WKURLSchemeHandler>
@property (strong) NSURL *baseDirectory;
@property (strong) NSMutableSet<id<WKURLSchemeTask>> *activeTasks;
@end

@implementation AppSchemeHandler

- (instancetype)init {
    self = [super init];
    if (self) {
        _activeTasks = [NSMutableSet set];
    }
    return self;
}

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    @synchronized (self.activeTasks) {
        [self.activeTasks addObject:urlSchemeTask];
    }
    
    NSURL *url = urlSchemeTask.request.URL;
    NSString *path = url.path;
    
    // Поддержка нативного проксирования сетевых запросов (CORS bypass для Google Таблиц и внешних API)
    if ([path isEqualToString:@"/api/proxy"] || [path hasPrefix:@"/api/proxy"]) {
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        NSString *targetUrlStr = nil;
        for (NSURLQueryItem *item in components.queryItems) {
            if ([item.name isEqualToString:@"url"]) {
                targetUrlStr = item.value;
                break;
            }
        }
        
        if (!targetUrlStr || targetUrlStr.length == 0) {
            NSHTTPURLResponse *badReq = [[NSHTTPURLResponse alloc] initWithURL:url
                                                                    statusCode:400
                                                                   HTTPVersion:@"HTTP/1.1"
                                                                  headerFields:@{ @"Access-Control-Allow-Origin": @"*" }];
            @synchronized (self.activeTasks) {
                if ([self.activeTasks containsObject:urlSchemeTask]) {
                    [urlSchemeTask didReceiveResponse:badReq];
                    [urlSchemeTask didFinish];
                    [self.activeTasks removeObject:urlSchemeTask];
                }
            }
            return;
        }
        
        NSURL *targetURL = [NSURL URLWithString:targetUrlStr];
        if (!targetURL) {
            NSHTTPURLResponse *badReq = [[NSHTTPURLResponse alloc] initWithURL:url
                                                                    statusCode:400
                                                                   HTTPVersion:@"HTTP/1.1"
                                                                  headerFields:@{ @"Access-Control-Allow-Origin": @"*" }];
            @synchronized (self.activeTasks) {
                if ([self.activeTasks containsObject:urlSchemeTask]) {
                    [urlSchemeTask didReceiveResponse:badReq];
                    [urlSchemeTask didFinish];
                    [self.activeTasks removeObject:urlSchemeTask];
                }
            }
            return;
        }
        
        NSMutableURLRequest *remoteReq = [NSMutableURLRequest requestWithURL:targetURL
                                                                 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                             timeoutInterval:30.0];
        [remoteReq setValue:@"BookParadise-Mac/2.12.2" forHTTPHeaderField:@"User-Agent"];
        [remoteReq setValue:@"application/json, text/plain, */*" forHTTPHeaderField:@"Accept"];
        
        __weak typeof(self) weakSelf = self;
        NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:remoteReq
                                                                         completionHandler:^(NSData *remoteData, NSURLResponse *remoteResponse, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                
                @synchronized (strongSelf.activeTasks) {
                    if (![strongSelf.activeTasks containsObject:urlSchemeTask]) {
                        return; // Задача была остановлена/отменена вебвью
                    }
                    
                    if (error || !remoteData) {
                        NSLog(@"[BookParadise Proxy Error] %@: %@", targetUrlStr, error.localizedDescription);
                        NSDictionary *errHeaders = @{
                            @"Content-Type": @"application/json; charset=utf-8",
                            @"Access-Control-Allow-Origin": @"*"
                        };
                        NSHTTPURLResponse *errResp = [[NSHTTPURLResponse alloc] initWithURL:url
                                                                                 statusCode:502
                                                                                HTTPVersion:@"HTTP/1.1"
                                                                               headerFields:errHeaders];
                        NSData *errData = [NSJSONSerialization dataWithJSONObject:@{
                            @"success": @NO,
                            @"error": error.localizedDescription ?: @"Proxy connection failed"
                        } options:0 error:nil];
                        [urlSchemeTask didReceiveResponse:errResp];
                        if (errData) [urlSchemeTask didReceiveData:errData];
                        [urlSchemeTask didFinish];
                        [strongSelf.activeTasks removeObject:urlSchemeTask];
                        return;
                    }
                    
                    NSInteger statusCode = 200;
                    NSString *contentType = @"application/json; charset=utf-8";
                    if ([remoteResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)remoteResponse;
                        statusCode = httpResp.statusCode;
                        NSString *remoteContentType = httpResp.allHeaderFields[@"Content-Type"] ?: httpResp.allHeaderFields[@"content-type"];
                        if (remoteContentType) {
                            contentType = remoteContentType;
                        }
                    }
                    
                    NSDictionary *respHeaders = @{
                        @"Content-Type": contentType,
                        @"Access-Control-Allow-Origin": @"*",
                        @"Cache-Control": @"no-cache"
                    };
                    
                    NSHTTPURLResponse *proxyResp = [[NSHTTPURLResponse alloc] initWithURL:url
                                                                               statusCode:statusCode
                                                                              HTTPVersion:@"HTTP/1.1"
                                                                             headerFields:respHeaders];
                    [urlSchemeTask didReceiveResponse:proxyResp];
                    [urlSchemeTask didReceiveData:remoteData];
                    [urlSchemeTask didFinish];
                    [strongSelf.activeTasks removeObject:urlSchemeTask];
                }
            });
        }];
        [dataTask resume];
        return;
    }
    
    // Статическая раздача файлов приложения из папки dist
    if ([path isEqualToString:@"/"] || [path length] == 0) {
        path = @"/index.html";
    }
    
    if ([path hasPrefix:@"/"]) {
        path = [path substringFromIndex:1];
    }
    
    NSURL *fileURL = [self.baseDirectory URLByAppendingPathComponent:path];
    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    
    @synchronized (self.activeTasks) {
        if (![self.activeTasks containsObject:urlSchemeTask]) return;
        
        if (data) {
            NSString *ext = [[fileURL pathExtension] lowercaseString];
            NSString *mimeType = @"application/octet-stream";
            if ([ext isEqualToString:@"html"]) mimeType = @"text/html; charset=utf-8";
            else if ([ext isEqualToString:@"js"]) mimeType = @"application/javascript; charset=utf-8";
            else if ([ext isEqualToString:@"css"]) mimeType = @"text/css; charset=utf-8";
            else if ([ext isEqualToString:@"svg"]) mimeType = @"image/svg+xml";
            else if ([ext isEqualToString:@"png"]) mimeType = @"image/png";
            else if ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"]) mimeType = @"image/jpeg";
            else if ([ext isEqualToString:@"json"]) mimeType = @"application/json; charset=utf-8";
            else if ([ext isEqualToString:@"woff2"]) mimeType = @"font/woff2";
            else if ([ext isEqualToString:@"woff"]) mimeType = @"font/woff";
            else if ([ext isEqualToString:@"ttf"]) mimeType = @"font/ttf";
            
            NSDictionary *headers = @{
                @"Content-Type": mimeType,
                @"Access-Control-Allow-Origin": @"*",
                @"Cache-Control": @"no-cache"
            };
            
            NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url
                                                                      statusCode:200
                                                                     HTTPVersion:@"HTTP/1.1"
                                                                    headerFields:headers];
            [urlSchemeTask didReceiveResponse:response];
            [urlSchemeTask didReceiveData:data];
            [urlSchemeTask didFinish];
        } else {
            NSLog(@"[BookParadise Scheme] 404 Not Found: %@ (resolved to %@)", path, fileURL.path);
            NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url
                                                                      statusCode:404
                                                                     HTTPVersion:@"HTTP/1.1"
                                                                    headerFields:@{ @"Access-Control-Allow-Origin": @"*" }];
            [urlSchemeTask didReceiveResponse:response];
            [urlSchemeTask didFinish];
        }
        [self.activeTasks removeObject:urlSchemeTask];
    }
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    @synchronized (self.activeTasks) {
        [self.activeTasks removeObject:urlSchemeTask];
    }
}

@end

// MARK: - AppDelegate
@interface AppDelegate : NSObject <NSApplicationDelegate, WKNavigationDelegate, WKScriptMessageHandler>
@property (strong) NSWindow *window;
@property (strong) WKWebView *webView;
@property (strong) AppSchemeHandler *schemeHandler;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSRect frame = NSMakeRect(100, 100, 1280, 820);
    NSWindowStyleMask style = NSWindowStyleMaskTitled | 
                              NSWindowStyleMaskClosable | 
                              NSWindowStyleMaskMiniaturizable | 
                              NSWindowStyleMaskResizable | 
                              NSWindowStyleMaskFullSizeContentView;

    self.window = [[NSWindow alloc] initWithContentRect:frame styleMask:style backing:NSBackingStoreBuffered defer:NO];
    [self.window setTitle:@"Книжный Рай"];
    [self.window setTitlebarAppearsTransparent:YES];
    [self.window setTitleVisibility:NSWindowTitleHidden];
    [self.window setMovableByWindowBackground:YES];
    [self.window setMinSize:NSMakeSize(900, 600)];
    [self.window setBackgroundColor:[NSColor colorWithRed:0.07 green:0.07 blue:0.09 alpha:1.0]];

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    
    // Включаем Developer Extras (Inspect Element) и доступ к локальным файлам
    [config.preferences setValue:@YES forKey:@"developerExtrasEnabled"];
    [config.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];
    [config setValue:@YES forKey:@"allowUniversalAccessFromFileURLs"];

    // Перехват console.log/console.error в NSLog для мгновенной диагностики
    WKUserContentController *contentController = [[WKUserContentController alloc] init];
    [contentController addScriptMessageHandler:self name:@"consoleLog"];
    NSString *consoleOverride = @"\
        (function() {\
            var originalLog = console.log;\
            var originalError = console.error;\
            var originalWarn = console.warn;\
            console.log = function() { window.webkit.messageHandlers.consoleLog.postMessage('[JS LOG] ' + Array.from(arguments).join(' ')); originalLog.apply(console, arguments); };\
            console.error = function() { window.webkit.messageHandlers.consoleLog.postMessage('[JS ERR] ' + Array.from(arguments).join(' ')); originalError.apply(console, arguments); };\
            console.warn = function() { window.webkit.messageHandlers.consoleLog.postMessage('[JS WARN] ' + Array.from(arguments).join(' ')); originalWarn.apply(console, arguments); };\
            window.onerror = function(msg, url, line) { window.webkit.messageHandlers.consoleLog.postMessage('[JS UNCAUGHT] ' + msg + ' at ' + url + ':' + line); };\
        })();";
    WKUserScript *script = [[WKUserScript alloc] initWithSource:consoleOverride injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [contentController addUserScript:script];

    // Автоматическая передача сохраненного в macOS UserDefaults URL Google Таблицы
    NSString *savedSheetsUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"GoogleAppsScriptURL"];
    if (savedSheetsUrl && [savedSheetsUrl length] > 0) {
        NSString *escapedUrl = [savedSheetsUrl stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        NSString *injectDefaults = [NSString stringWithFormat:@"window.__NATIVE_DEFAULT_SHEETS_URL = \"%@\";", escapedUrl];
        WKUserScript *defaultsScript = [[WKUserScript alloc] initWithSource:injectDefaults
                                                              injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                           forMainFrameOnly:NO];
        [contentController addUserScript:defaultsScript];
        NSLog(@"[BookParadise] Injected native GoogleAppsScriptURL from NSUserDefaults: %@", savedSheetsUrl);
    }
    
    config.userContentController = contentController;

    // Регистрация кастомного протокола app://
    self.schemeHandler = [[AppSchemeHandler alloc] init];
    NSURL *distDir = [[NSBundle mainBundle] URLForResource:@"dist" withExtension:nil];
    if (!distDir) {
        distDir = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"dist"];
    }
    self.schemeHandler.baseDirectory = distDir;
    [config setURLSchemeHandler:self.schemeHandler forURLScheme:@"app"];

    self.webView = [[WKWebView alloc] initWithFrame:[[self.window contentView] bounds] configuration:config];
    [self.webView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [self.webView setValue:@NO forKey:@"drawsBackground"];
    [self.webView setNavigationDelegate:self];

    [[self.window contentView] addSubview:self.webView];
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];

    [self setupMenus];
    [self loadContent];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"%@", message.body);
}

- (void)loadContent {
    NSURL *distIndex = [self.schemeHandler.baseDirectory URLByAppendingPathComponent:@"index.html"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[distIndex path]]) {
        NSLog(@"[BookParadise] Loading bundle via app://localhost/index.html (from %@)", [distIndex path]);
        NSURL *appURL = [NSURL URLWithString:@"app://localhost/index.html"];
        [self.webView loadRequest:[NSURLRequest requestWithURL:appURL]];
    } else {
        NSLog(@"[BookParadise] Bundle not found at %@, trying localhost dev server...", [distIndex path]);
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:5173"]]];
    }
}

// MARK: - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"[BookParadise] Start loading page");
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"[BookParadise] Page finished loading successfully");
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"[BookParadise] Failed provisional navigation: %@", error.localizedDescription);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"[BookParadise] Failed navigation: %@", error.localizedDescription);
}

- (void)setupMenus {
    NSMenu *mainMenu = [[NSMenu alloc] init];

    // 1. App menu
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    [mainMenu addItem:appMenuItem];
    NSMenu *appMenu = [[NSMenu alloc] init];
    [appMenuItem setSubmenu:appMenu];

    [appMenu addItemWithTitle:@"О программе Книжный Рай" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Настройки..." action:@selector(openSettings) keyEquivalent:@","];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Скрыть Книжный Рай" action:@selector(hide:) keyEquivalent:@"h"];
    [appMenu addItemWithTitle:@"Скрыть остальные" action:@selector(hideOtherApplications:) keyEquivalent:@"h"];
    [appMenu addItemWithTitle:@"Показать все" action:@selector(unhideAllApplications:) keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Завершить Книжный Рай" action:@selector(terminate:) keyEquivalent:@"q"];

    // 2. Edit menu
    NSMenuItem *editMenuItem = [[NSMenuItem alloc] init];
    [mainMenu addItem:editMenuItem];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Правка"];
    [editMenuItem setSubmenu:editMenu];
    [editMenu addItemWithTitle:@"Отменить" action:@selector(undo:) keyEquivalent:@"z"];
    [editMenu addItemWithTitle:@"Повторить" action:@selector(redo:) keyEquivalent:@"Z"];
    [editMenu addItem:[NSMenuItem separatorItem]];
    [editMenu addItemWithTitle:@"Вырезать" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Скопировать" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Вставить" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Выбрать всё" action:@selector(selectAll:) keyEquivalent:@"a"];

    // 3. View menu
    NSMenuItem *viewMenuItem = [[NSMenuItem alloc] init];
    [mainMenu addItem:viewMenuItem];
    NSMenu *viewMenu = [[NSMenu alloc] initWithTitle:@"Вид"];
    [viewMenuItem setSubmenu:viewMenu];
    [viewMenu addItemWithTitle:@"Перезагрузить" action:@selector(reloadPage) keyEquivalent:@"r"];
    [viewMenu addItemWithTitle:@"Полноэкранный режим" action:@selector(toggleFullScreen:) keyEquivalent:@"f"];

    // 4. Window menu
    NSMenuItem *windowMenuItem = [[NSMenuItem alloc] init];
    [mainMenu addItem:windowMenuItem];
    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Окно"];
    [windowMenuItem setSubmenu:windowMenu];
    [windowMenu addItemWithTitle:@"Свернуть" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
    [windowMenu addItemWithTitle:@"Закрыть" action:@selector(performClose:) keyEquivalent:@"w"];

    [NSApp setMainMenu:mainMenu];
}

- (void)openSettings {
    [self.webView evaluateJavaScript:@"window.dispatchEvent(new KeyboardEvent('keydown', { key: ',', metaKey: true }))" completionHandler:nil];
}

- (void)reloadPage {
    [self loadContent];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        [app setDelegate:delegate];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        [app activateIgnoringOtherApps:YES];
        [app run];
    }
    return 0;
}

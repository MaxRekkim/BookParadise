#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

// MARK: - Кастомный URL Scheme Handler для надежной загрузки React/Vite без CORS-блокировок
@interface AppSchemeHandler : NSObject <WKURLSchemeHandler>
@property (strong) NSURL *baseDirectory;
@end

@implementation AppSchemeHandler

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    NSURL *url = urlSchemeTask.request.URL;
    NSString *path = url.path;
    if ([path isEqualToString:@"/"] || [path length] == 0) {
        path = @"/index.html";
    }
    
    if ([path hasPrefix:@"/"]) {
        path = [path substringFromIndex:1];
    }
    
    NSURL *fileURL = [self.baseDirectory URLByAppendingPathComponent:path];
    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    
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
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
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

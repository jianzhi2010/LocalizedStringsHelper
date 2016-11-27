//
//  LocalizedStringsHelper.m
//  LocalizedStringsHelper
//
//  Created by liang on 16/11/27.
//  Copyright © 2016年 liang. All rights reserved.
//

#import "LocalizedStringsHelper.h"

// Models
#import "LINLocalizationParser.h"
#import "LINLocalization.h"

static LocalizedStringsHelper *sharedPlugin;

@interface LocalizedStringsHelper()

@property (nonatomic, assign) BOOL isInLocalizebleStringsFile;
@property (nonatomic, strong) LINLocalizationParser *parser;
@property (nonatomic, strong) NSOperationQueue *detectQueue;

@end

@implementation LocalizedStringsHelper

#pragma mark - Initialization

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    NSArray *allowedLoaders = [plugin objectForInfoDictionaryKey:@"me.delisa.XcodePluginBase.AllowedLoaders"];
    if ([allowedLoaders containsObject:[[NSBundle mainBundle] bundleIdentifier]]) {
        sharedPlugin = [[self alloc] initWithBundle:plugin];
    }
}

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)bundle
{
    if (self = [super init]) {
        // reference to plugin's bundle, for resource access
        _bundle = bundle;
        // NSApp may be nil if the plugin is loaded from the xcodebuild command line tool
        if (NSApp && !NSApp.mainMenu) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(applicationDidFinishLaunching:)
                                                         name:NSApplicationDidFinishLaunchingNotification
                                                       object:nil];
        }
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChangeSelectionNotification:) name:NSTextViewDidChangeSelectionNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editorDocumentDidChangeNotification:) name:@"IDEEditorDocumentDidChangeNotification" object:nil];

    
    self.detectQueue = [NSOperationQueue new];
    self.detectQueue.maxConcurrentOperationCount = 1;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

# pragma mark - Notifications

- (void)textViewDidChangeSelectionNotification:(NSNotification *)notification
{
    if (!self.isInLocalizebleStringsFile) {
        return ;
    }
    
    NSTextView *textView = notification.object;
    NSString *text = textView.textStorage.string;
    
    // Add detect operation
    NSBlockOperation *operation = [NSBlockOperation new];
    __weak NSBlockOperation *weakOperation = operation;
    
    [operation addExecutionBlock:^{
        
        NSArray *parsedLocalizations = [LINLocalizationParser localizationsFromTextString:text];
        
        if ([weakOperation isCancelled]) return;

        NSMutableArray *keys = [NSMutableArray array];
        for (LINLocalization *localization in parsedLocalizations) {
            if ([weakOperation isCancelled]) return;
            
            if ([keys containsObject:localization.key]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [textView.layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName value:[[NSColor yellowColor] colorWithAlphaComponent:0.2] forCharacterRange:localization.lineRange];
                });
//                NSLog(@"Duplicate key:%@", localization.key);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([textView.layoutManager temporaryAttribute:NSBackgroundColorAttributeName atCharacterIndex:localization.lineRange.location effectiveRange:NULL]) {
                        [textView.layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:localization.lineRange];
                    }
                });
                
                [keys addObject:localization.key];
            }
        }
    }];
    
    [self.detectQueue cancelAllOperations];
    [self.detectQueue addOperation:operation];
}

- (void)editorDocumentDidChangeNotification:(NSNotification *)notify
{
    //Track the current open paths
    NSObject *array = notify.userInfo[@"IDEEditorDocumentChangeLocationsKey"];

    NSURL *url = [[array valueForKey:@"documentURL"] firstObject];
    if (![url isKindOfClass:[NSNull class]]) {
    
        if ([[url absoluteString] containsString:@"Localizable.strings"]) {
            self.isInLocalizebleStringsFile = YES;
        } else {
            self.isInLocalizebleStringsFile = NO;
            [self.detectQueue cancelAllOperations];
        }
    }
}

@end

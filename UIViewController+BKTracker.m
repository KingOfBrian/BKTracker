//
//  UIViewController+BKTracker.m
//  lifelapse
//
//  Created by Brian King on 1/27/11.
//  Copyright 2011 King Software Design. All rights reserved.
//

#import "UIViewController+BKTracker.h"

#import <objc/runtime.h>
#import <objc/message.h>

#import "BKTracker.h"

static NSString *UIViewControllerStateNameKey = @"UIViewControllerStateNameKey";
@interface UIViewController(BKTrackerPrivate)

- (void) bkTrackerViewWillAppear:(BOOL)animated ;
- (void) bkTrackerViewDidAppear:(BOOL)animated;
- (void) bkTrackerViewWillDisappear:(BOOL)animated;
- (void) bkTrackerViewDidDisappear:(BOOL)animated;

@end



@implementation UIViewController(BKTracker)

- (void) setTrackerState:(NSString*)stateName {
	[[BKTracker sharedTracker] addState:stateName];
	objc_setAssociatedObject(self, UIViewControllerStateNameKey, stateName, OBJC_ASSOCIATION_RETAIN);
}

- (NSString*) trackerState {
	NSString *stateName = objc_getAssociatedObject(self, UIViewControllerStateNameKey);
	return stateName;
}

- (void) enterState {
	[[BKTracker sharedTracker] enterState:self.trackerState stateInstance:self];
}
- (void) exitState {
	[[BKTracker sharedTracker] exitState:self.trackerState];
}

- (void) trackKeyPath:(NSString*)keyPath as:(NSString*)name {
	[[BKTracker sharedTracker] addVariable:name keypath:keyPath toState:self.trackerState];
}

- (void) trackEvent:(NSString*)eventName {
	[[BKTracker sharedTracker] event:eventName];
}


void BKPerformSwizzle(Class aClass, SEL originalSel, SEL bkSel) {
    Method newMethod = class_getInstanceMethod(aClass, originalSel);
    Method altMethod = class_getInstanceMethod(aClass, bkSel);
	
	method_exchangeImplementations(altMethod, newMethod);
}

+ (void) BKSwizzleTracker {
	BKPerformSwizzle([UIViewController class], @selector(viewDidAppear:),@selector(bkTrackerViewDidAppear:));
	BKPerformSwizzle([UIViewController class], @selector(viewDidDisappear:),@selector(bkTrackerViewDidDisappear:));
}

- (void) bkTrackerViewDidAppear:(BOOL)animated {
	if (self.trackerState) {
		[[BKTracker sharedTracker] enterState:self.trackerState stateInstance:self];
	}

	// This method is swizzled so this calls the original
	[self bkTrackerViewDidAppear:animated];
}

- (void) bkTrackerViewDidDisappear:(BOOL)animated {
	if (self.trackerState) {
		[[BKTracker sharedTracker] exitState:self.trackerState];
	}
	// This method is swizzled so this calls the original
	[self bkTrackerViewDidDisappear:animated];
}



@end

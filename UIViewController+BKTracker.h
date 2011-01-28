//
//  UIViewController+BKTracker.h
//  lifelapse
//
//  Created by Brian King on 1/27/11.
//  Copyright 2011 King Software Design. All rights reserved.
//

#import <Foundation/Foundation.h>

void BKPerformSwizzle(Class aClass, SEL originalSel, SEL bkSel);

@interface UIViewController(BKTracker)

+ (void) BKSwizzleTracker;

- (void) trackKeyPath:(NSString*)keyPath as:(NSString*)name;
- (void) trackEvent:(NSString*)eventName;

@property (nonatomic, retain) NSString *trackerState;

@end

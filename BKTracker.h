//
//  BKTracker.h
//  lifelapse
//
//  Created by Brian King on 1/27/11.
//  Copyright 2011 King Software Design. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol BKTrackerDelegate;

@interface BKTracker : NSObject {
	NSMutableDictionary *stateDefinitions;
	
	NSMutableDictionary *openStates;
	
	id<BKTrackerDelegate> delegate;
	
	NSDate *lastEvent;
}
+ (BKTracker*) sharedTracker;

- (void) enterState:(NSString*)stateName stateInstance:(id<NSObject>)instance;
- (void) exitState:(NSString*)stateName;
- (void) event:(NSString*)eventName;

@property (nonatomic, assign) id<BKTrackerDelegate> delegate;

- (void) addState:(NSString*)stateName;
- (void) addVariable:(NSString*)variableName keypath:(NSString*)keypath toState:(NSString*)stateName;

@end

@protocol BKTrackerDelegate <NSObject>
- (void) tracker:(BKTracker*)tracker event:(NSString*)eventName withAttributes:(NSDictionary*)attributes;
- (void) tracker:(BKTracker*)tracker enterState:(NSString*)stateName withAttributes:(NSDictionary*)attributes;
- (void) tracker:(BKTracker*)tracker exitState:(NSString*)stateName withAttributes:(NSDictionary*)attributes;

@end
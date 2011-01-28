//
//  BKTracker.m
//  lifelapse
//
//  Created by Brian King on 1/27/11.
//  Copyright 2011 King Software Design. All rights reserved.
//

#import "BKTracker.h"

static NSString * const BKKVCVariablesKey = @"BKKVCVariablesKey";
static NSString * const BKStateNameKey = @"BKStateNameKey";
static NSString * const BKStateInstanceKey = @"BKStateInstanceKey";
static NSString * const BKStateActionsKey = @"BKStateActionsKey";
static NSString * const BKActionNameKey = @"BKActionNameKey";
static NSString * const BKStateEnterKey = @"BKStateEnterKey";
static NSString * const BKStateLastActionDateKey = @"BKStateLastActionDateKey";
static NSString * const BKStateExitKey = @"BKStateExitKey";
static NSString * const BKStateDurationAttrKey = @"Duration";
static NSString * const BKActionDateAttrKey = @"Date";
static NSString * const BKStateSecondsSinceLastAttrKey = @"Since Last";
@interface BKTracker()
- (NSMutableDictionary*) grabStateForVariables:(NSDictionary*)kvcDict onInstance:(id)object;
- (void) delegateEventNamed:(NSString*)name attributes:(NSDictionary*)attributes;
- (void) delegateEnterStateNamed:(NSString*)name attributes:(NSDictionary*)attributes;
- (void) delegateExitStateNamed:(NSString*)name attributes:(NSDictionary*)attributes;
	
@property (nonatomic, retain) NSDate *lastEvent;
@end

@implementation BKTracker
@synthesize delegate, lastEvent;

- (id) init {
	self = [super init];
	if (self) {
		stateDefinitions = [[NSMutableDictionary alloc] init];
		openStates = [[NSMutableDictionary alloc] init];
	}
	return self;
}
- (void) dealloc {
	[stateDefinitions release];
	[openStates release];
	[super dealloc];
}

+ (BKTracker*) sharedTracker {
	static BKTracker *sharedTracker = nil;
	@synchronized([BKTracker class]) {
		if(!sharedTracker) {
			sharedTracker = [[self alloc] init];
		}
	}
	return sharedTracker;
}

- (void) enterState:(NSString*)stateName stateInstance:(id<NSObject>)instance {
	
	NSMutableDictionary *state = [stateDefinitions objectForKey:stateName];
	NSAssert(state != nil, @"Unknown State");
	NSMutableDictionary *variables = [state objectForKey:BKKVCVariablesKey];
	NSAssert(variables != nil, @"No Variables Dictionary");
	
	NSMutableDictionary *stateState = [self grabStateForVariables:variables onInstance:instance];
	NSDate *enterDate = [NSDate date];
	
	[stateState setObject:enterDate forKey:BKStateEnterKey];

	[self delegateEnterStateNamed:stateName attributes:stateState];
	
	[stateState setObject:enterDate forKey:BKStateLastActionDateKey];
	[stateState setObject:stateName forKey:BKStateNameKey];
	[stateState setObject:instance forKey:BKStateInstanceKey];

	[openStates setObject:stateState forKey:stateName];
}

- (void) exitState:(NSString*)stateName {
	NSMutableDictionary *stateState = [openStates objectForKey:stateName];
	NSMutableDictionary *state = [stateDefinitions objectForKey:stateName];
	NSAssert(state != nil, @"Unknown State");
	NSMutableDictionary *variables = [state objectForKey:BKKVCVariablesKey];
	NSAssert(variables != nil, @"No Variables Dictionary");
	
	id instance       = [stateState objectForKey:BKStateInstanceKey];
	NSDate *enterDate = [stateState objectForKey:BKStateEnterKey];
	NSDate *exitDate  = [NSDate date];
						 
	
	NSMutableDictionary *exitState = [self grabStateForVariables:variables onInstance:instance];
	[stateState setObject:exitDate forKey:BKStateExitKey];

	NSTimeInterval passedSeconds = [exitDate timeIntervalSinceDate:enterDate];
	[exitState setObject:[NSNumber numberWithDouble:passedSeconds] forKey:BKStateDurationAttrKey];
	
	[self delegateExitStateNamed:stateName attributes:exitState];

	[openStates removeObjectForKey:stateName];
}

- (void) event:(NSString*)eventName {
	NSMutableDictionary *actionState = [NSMutableDictionary dictionary];
	NSDate *actionDate = [NSDate date];
	

	for (NSString *key in [openStates allKeys]) {
		NSMutableDictionary *stateState = [openStates objectForKey:key];
	
		NSMutableDictionary *state = [stateDefinitions objectForKey:key];
		NSAssert(state != nil, @"Unknown State");
		NSMutableDictionary *variables = [state objectForKey:BKKVCVariablesKey];
		NSAssert(variables != nil, @"No Variables Dictionary");
	
		id instance        = [stateState objectForKey:BKStateInstanceKey];
	
		[actionState setValuesForKeysWithDictionary:[self grabStateForVariables:variables onInstance:instance]];
	}
	
	NSTimeInterval passedSeconds = [actionDate timeIntervalSinceDate:self.lastEvent];
	[actionState setObject:[NSNumber numberWithDouble:passedSeconds] forKey:BKStateSecondsSinceLastAttrKey];
	self.lastEvent = actionDate;
	
	[self delegateEventNamed:eventName attributes:actionState];
}

- (NSMutableDictionary*) grabStateForVariables:(NSDictionary*)kvcDict onInstance:(id)object {
	NSMutableDictionary *state = [NSMutableDictionary dictionaryWithCapacity:[kvcDict count]];
	
	for (NSString* key in [kvcDict allKeys]) {
		NSString* keyPath = [kvcDict objectForKey:key];
		id value = [object valueForKeyPath:keyPath];
		id outValue = nil;
		if ([value isKindOfClass:[NSString class]]) {
			outValue = value;
		} else if ([value isKindOfClass:[NSNumber class]]) {
			outValue = value;			
		} else {
			outValue = [value description];
		}
		[state setValue:outValue forKey:key];
	}
	return state;
}

- (void) delegateEventNamed:(NSString*)name attributes:(NSDictionary*)attributes {
	if ([delegate respondsToSelector:@selector(tracker:event:withAttributes:)]) {
		[delegate tracker:self event:name withAttributes:attributes];
	} else {
		NSLog(@"delegateEventNamed:%@ attributes:%@", name, attributes);
	}
}

- (void) delegateEnterStateNamed:(NSString*)name attributes:(NSDictionary*)attributes {
	if ([delegate respondsToSelector:@selector(tracker:enterState:withAttributes:)]) {
		[delegate tracker:self enterState:name withAttributes:attributes];
	} else {
		NSLog(@"delegateEnterStateNamed:%@ attributes:%@", name, attributes);
	}
}

- (void) delegateExitStateNamed:(NSString*)name attributes:(NSDictionary*)attributes {
	if ([delegate respondsToSelector:@selector(tracker:exitState:withAttributes:)]) {
		[delegate tracker:self exitState:name withAttributes:attributes];
	} else {
		NSLog(@"delegateExitStateNamed:%@ attributes:%@", name, attributes);
	}
}


- (void) addState:(NSString*)name {
	NSParameterAssert(name);

	NSMutableDictionary *state = [NSMutableDictionary dictionary];
	[state setObject:name forKey:BKStateNameKey];
	[state setObject:[NSMutableDictionary dictionary] forKey:BKKVCVariablesKey];
	[state setObject:[NSMutableDictionary dictionary] forKey:BKStateActionsKey];
	
	[stateDefinitions setObject:state forKey:name];
}

- (void) addVariable:(NSString*)variableName keypath:(NSString*)keyPath toState:(NSString*)stateName {
	NSParameterAssert(keyPath);
	NSParameterAssert(stateName);
	NSParameterAssert(variableName);
	
	NSMutableDictionary *state = [stateDefinitions objectForKey:stateName];
	NSAssert(state != nil, @"Unknown State");
	NSMutableDictionary *variables = [state objectForKey:BKKVCVariablesKey];
	NSAssert(variables != nil, @"No Variables Dictionary");

	[variables setObject:keyPath forKey:variableName];
}




@end

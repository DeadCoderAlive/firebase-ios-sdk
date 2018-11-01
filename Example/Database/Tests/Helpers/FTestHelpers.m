/*
 * Copyright 2017 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FTestHelpers.h"

#import "FConstants.h"

#import <FirebaseAuthInterop/FIRAuthInterop.h>
#import <FirebaseCore/FIRAppInternal.h>
#import <FirebaseCore/FIRComponent.h>
#import <FirebaseCore/FIRComponentContainer.h>
#import <FirebaseCore/FIROptions.h>
#import "FIRDatabaseConfig_Private.h"
#import "FTestAuthTokenGenerator.h"

@implementation FTestHelpers

+ (NSTimeInterval) waitUntil:(BOOL (^)())predicate timeout:(NSTimeInterval)seconds {
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:seconds];
    NSTimeInterval timeoutTime = [timeoutDate timeIntervalSinceReferenceDate];
    NSTimeInterval currentTime;

    for (currentTime = [NSDate timeIntervalSinceReferenceDate];
         !predicate() && currentTime < timeoutTime;
         currentTime = [NSDate timeIntervalSinceReferenceDate]) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
    }

    NSTimeInterval finish = [NSDate timeIntervalSinceReferenceDate];

    NSAssert(currentTime <= timeoutTime, @"Timed out");

    return (finish - start);
}

+ (NSArray*) getRandomNodes:(int)num persistence:(BOOL)persistence {
    static dispatch_once_t pred = 0;
    static NSMutableArray *persistenceRefs = nil;
    static NSMutableArray *noPersistenceRefs = nil;
    dispatch_once(&pred, ^{
        persistenceRefs = [[NSMutableArray alloc] init];
        noPersistenceRefs = [[NSMutableArray alloc] init];
        // Uncomment the following line to run tests against a background thread
        //[Firebase setDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    });

    NSMutableArray *refs = (persistence) ? persistenceRefs : noPersistenceRefs;

    id<FAuthTokenProvider> authTokenProvider =
        [FAuthTokenProvider authTokenProviderWithAuthInterop:
            FIR_COMPONENT(FIRAuthInterop, [FIRApp defaultApp].container)];

    while (num > refs.count) {
        NSString *sessionIdentifier = [NSString stringWithFormat:@"test-config-%@persistence-%lu", (persistence) ? @"" : @"no-", refs.count];
        FIRDatabaseConfig *config = [[FIRDatabaseConfig alloc] initWithSessionIdentifier:sessionIdentifier authTokenProvider:authTokenProvider];
        config.persistenceEnabled = persistence;
        FIRDatabaseReference * ref = [[FIRDatabaseReference alloc] initWithConfig:config];
        [refs addObject:ref];
    }

    NSMutableArray* results = [[NSMutableArray alloc] init];
    NSString* name = nil;
    for (int i = 0; i < num; ++i) {
        FIRDatabaseReference * ref = [refs objectAtIndex:i];
        if (!name) {
            name = [ref childByAutoId].key;
        }
        [results addObject:[ref child:name]];
    }
    return results;
}

// Helpers
+ (FIRDatabaseReference *) getRandomNode {
    NSArray* refs = [self getRandomNodes:1 persistence:YES];
    return [refs objectAtIndex:0];
}

+ (FIRDatabaseReference *) getRandomNodeWithoutPersistence {
    NSArray* refs = [self getRandomNodes:1 persistence:NO];
    return refs[0];
}

+ (FTupleFirebase *) getRandomNodePair {
    NSArray* refs = [self getRandomNodes:2 persistence:YES];

    FTupleFirebase* tuple = [[FTupleFirebase alloc] init];
    tuple.one = [refs objectAtIndex:0];
    tuple.two = [refs objectAtIndex:1];

    return tuple;
}

+ (FTupleFirebase *) getRandomNodePairWithoutPersistence {
    NSArray* refs = [self getRandomNodes:2 persistence:NO];

    FTupleFirebase* tuple = [[FTupleFirebase alloc] init];
    tuple.one = refs[0];
    tuple.two = refs[1];

    return tuple;
}

+ (FTupleFirebase *) getRandomNodeTriple {
    NSArray* refs = [self getRandomNodes:3 persistence:YES];
    FTupleFirebase* triple = [[FTupleFirebase alloc] init];
    triple.one = [refs objectAtIndex:0];
    triple.two = [refs objectAtIndex:1];
    triple.three = [refs objectAtIndex:2];

    return triple;
}

+ (id<FNode>)leafNodeOfSize:(NSUInteger)size {
    NSMutableString *string = [NSMutableString string];
    NSString *pattern = @"abdefghijklmopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    for (NSUInteger i = 0; i < size - pattern.length; i = i + pattern.length) {
        [string appendString:pattern];
    }
    NSUInteger remainingLength = size - string.length;
    [string appendString:[pattern substringToIndex:remainingLength]];
    return [FSnapshotUtilities nodeFrom:string];
}

@end

//
//  SMRequestOSRM.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 06/02/2013.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import "SMRequestOSRM.h"
#import "NSString+URLEncode.h"
#import "SMGPSUtil.h"
#import "Reachability.h"

@interface SMRequestOSRM()
@property (nonatomic, strong) NSURLConnection * conn;
@property (nonatomic, strong) NSString * currentRequest;

@property (nonatomic, strong) CLLocation * startLoc;
@property (nonatomic, strong) CLLocation * endLoc;
@property NSInteger locStep;

@property NSInteger currentZ;
@property (nonatomic, strong) NSDictionary * originalJSON;
@property (nonatomic, strong) NSString * originalChecksum;
@property (nonatomic, strong) NSString * originalStartHint;
@property (nonatomic, strong) NSString * originalDestinationHint;

@property (nonatomic, strong) NSArray * originalViaPoints;
@property CLLocationCoordinate2D originalStart;
@property CLLocationCoordinate2D originalEnd;
@end

static dispatch_queue_t reachabilityQueue;

@implementation SMRequestOSRM

#define DEFAULT_Z 18
#define MINIMUM_Z 10

- (id)initWithDelegate:(id<SMRequestOSRMDelegate>)dlg {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        reachabilityQueue= dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0L);
    });
    
    self = [super init];
    if (self) {
        [self setDelegate:dlg];
        self.locStep = 0;
        self.osrmServer = OSRM_SERVER;
    }
    return self;
}

- (BOOL)serverReachable {
    Reachability * r = [Reachability reachabilityWithHostName:OSRM_ADDRESS];
    NetworkStatus s = [r currentReachabilityStatus];
    if (s == NotReachable) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(serverNotReachable)]) {
            [self.delegate serverNotReachable];
        }
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Network error!" forKey:NSLocalizedDescriptionKey];
        NSError * error = [NSError errorWithDomain:@"" code:0 userInfo:details];
        if (self.delegate && [self.delegate respondsToSelector:@selector(request:failedWithError:)]) {
            [self.delegate request:self failedWithError:error];
        }
        return NO;
    }
    return YES;
}

- (void)findNearestPointForLocation:(CLLocation*)loc {
    [self runBlockIfServerReachable:^{
        self.currentRequest = @"findNearestPointForLocation:";
        self.coord = loc;
        NSString * s = [NSString stringWithFormat:@"%@/nearest?loc=%.6f,%.6f", self.osrmServer, loc.coordinate.latitude, loc.coordinate.longitude];
        NSMutableURLRequest * req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:s]];
        [req setValue:USER_AGENT forHTTPHeaderField:@"User-Agent"];
        if (self.conn) {
            [self.conn cancel];
            self.conn = nil;
        }
        self.responseData = [NSMutableData data];
        NSURLConnection * c = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
        self.conn = c;
        [self.conn start];
    }];

}
 
// via may be null
- (void)getRouteFrom:(CLLocationCoordinate2D)start to:(CLLocationCoordinate2D)end via:(NSArray *)viaPoints {
    [self getRouteFrom:start to:end via:viaPoints checksum:nil destinationHint:nil];    
}

- (void)getRouteFrom:(CLLocationCoordinate2D)start to:(CLLocationCoordinate2D)end via:(NSArray *)viaPoints checksum:(NSString*)chksum {
    [self getRouteFrom:start to:end via:viaPoints checksum:chksum destinationHint:nil];
}

- (void)getRouteFrom:(CLLocationCoordinate2D)start to:(CLLocationCoordinate2D)end via:(NSArray *)viaPoints checksum:(NSString*)chksum destinationHint:(NSString*)hint {
    self.originalJSON = nil;
    self.originalStart = start;
    self.originalEnd = end;
    self.originalViaPoints = viaPoints;
    self.originalDestinationHint = hint;
    self.originalStartHint = nil;
    self.originalChecksum = chksum;
    [self getRouteFrom:start to:end via:viaPoints checksum:chksum andStartHint:nil destinationHint:hint andZ:DEFAULT_Z];
}

- (void)getRouteFrom:(CLLocationCoordinate2D)start to:(CLLocationCoordinate2D)end via:(NSArray *)viaPoints checksum:(NSString*)chksum andStartHint:(NSString*)startHint destinationHint:(NSString*)hint andZ:(NSInteger)z{
    [self runBlockIfServerReachable:^{
        
        self.currentZ = z;
        self.currentRequest = @"getRouteFrom:to:via:";
        
        NSMutableString * s1 =[NSMutableString stringWithFormat:@"%@/viaroute?z=%d&alt=false", self.osrmServer, z];
        
        if (startHint) {
            s1 = [NSMutableString stringWithFormat:@"%@&loc=%.6f,%.6f&hint=%@", s1, start.latitude, start.longitude, startHint];
        } else {
            s1 = [NSMutableString stringWithFormat:@"%@&loc=%.6f,%.6f", s1, start.latitude, start.longitude];
        }
        
        if (viaPoints) {
            for (CLLocation *point in viaPoints)
                [s1 appendFormat:@"&loc=%f.6,%.6f", point.coordinate.latitude, point.coordinate.longitude];
        }
        NSString *s = @"";
        
        if (chksum) {
            if (hint) {
                s = [NSString stringWithFormat:@"%@&loc=%.6f,%.6f&hint=%@&instructions=true&checksum=%@", s1, end.latitude, end.longitude, hint, chksum];
            } else {
                s = [NSString stringWithFormat:@"%@&loc=%.6f,%.6f&instructions=true&checksum=%@", s1, end.latitude, end.longitude, chksum];
            }
        } else {
            s = [NSString stringWithFormat:@"%@&loc=%.6f,%.6f&instructions=true", s1, end.latitude, end.longitude];
        }
        
        debugLog(@"%@", s);
        
        NSMutableURLRequest * req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:s]];
        [req setValue:USER_AGENT forHTTPHeaderField:@"User-Agent"];
        if (self.conn) {
            [self.conn cancel];
            self.conn = nil;
        }
        self.responseData = [NSMutableData data];
        NSURLConnection * c = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
        self.conn = c;
        [self.conn start];
    }];
}

- (void)findNearestPointForStart:(CLLocation*)start andEnd:(CLLocation*)end {
    [self runBlockIfServerReachable:^{
        self.currentRequest = @"findNearestPointForStart:andEnd:";
        NSString * s;
        if (self.locStep == 0) {
            self.startLoc = start;
            self.endLoc = end;
            s = [NSString stringWithFormat:@"%@/nearest?loc=%.6f,%.6f", self.osrmServer, start.coordinate.latitude, start.coordinate.longitude];
        } else {
            s = [NSString stringWithFormat:@"%@/nearest?loc=%.6f,%.6f", self.osrmServer, end.coordinate.latitude, end.coordinate.longitude];
        }
        self.locStep += 1;
        NSMutableURLRequest * req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:s]];
        [req setValue:USER_AGENT forHTTPHeaderField:@"User-Agent"];
        if (self.conn) {
            [self.conn cancel];
            self.conn = nil;
        }
        self.responseData = [NSMutableData data];
        NSURLConnection * c = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
        self.conn = c;
        [self.conn start];
        
    }];
//    if ([self serverReachable] == NO) {
//        return;
//    }
}

#pragma mark - url connection delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if ([self.responseData length] > 0) {
        NSString * str = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
        debugLog(@"%@", str);
        id r = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingAllowFragments error:nil];//[[[SBJsonParser alloc] init] objectWithData:self.responseData];
        if ([self.currentRequest isEqualToString:@"findNearestPointForStart:andEnd:"]) {
            if (self.locStep > 1) {
                if (r[@"mapped_coordinate"] && [r[@"mapped_coordinate"] isKindOfClass:[NSArray class]] && ([r[@"mapped_coordinate"] count] > 1)) {
                    self.endLoc = [[CLLocation alloc] initWithLatitude:[r[@"mapped_coordinate"][0] doubleValue] longitude:[r[@"mapped_coordinate"][1] doubleValue]];
                }
                if ([self.delegate conformsToProtocol:@protocol(SMRequestOSRMDelegate)]) {
                    [self.delegate request:self finishedWithResult:@{@"start" : self.startLoc, @"end" : self.endLoc}];
                }
                self.locStep = 0;
            } else {
                if (r[@"mapped_coordinate"] && [r[@"mapped_coordinate"] isKindOfClass:[NSArray class]] && ([r[@"mapped_coordinate"] count] > 1)) {
                    self.startLoc = [[CLLocation alloc] initWithLatitude:[r[@"mapped_coordinate"][0] doubleValue] longitude:[r[@"mapped_coordinate"][1] doubleValue]];
                }
                [self findNearestPointForStart:self.startLoc andEnd:self.endLoc];
            }
        } else if ([self.currentRequest isEqualToString:@"findNearestPointForLocation:"])  {
            if ([self.delegate conformsToProtocol:@protocol(SMRequestOSRMDelegate)]) {
                [self.delegate request:self finishedWithResult:r];
            }
        } else {
            
            if (!r || ([r isKindOfClass:[NSDictionary class]] == NO) || ([r[@"status"] intValue] != 0)) {
                if (self.currentZ == DEFAULT_Z) {
                    if (self.originalJSON) {
                        if ([self.delegate conformsToProtocol:@protocol(SMRequestOSRMDelegate)]) {
                            [self.delegate request:self finishedWithResult:self.originalJSON];
                        }
                    } else {
                        [self getRouteFrom:self.originalStart to:self.originalEnd via:self.originalViaPoints checksum:self.originalChecksum andStartHint:self.originalStartHint destinationHint:self.originalDestinationHint andZ:MINIMUM_Z];
                    }
                } else {
                    if ([self.delegate conformsToProtocol:@protocol(SMRequestOSRMDelegate)]) {
                        [self.delegate request:self finishedWithResult:r];
                    }                    
                }
            } else {
                if (self.currentZ == DEFAULT_Z) {
                    if ([self.delegate conformsToProtocol:@protocol(SMRequestOSRMDelegate)]) {
                        [self.delegate request:self finishedWithResult:r];
                    }
                } else {
                    self.originalJSON = r;
                    self.originalChecksum = [NSString stringWithFormat:@"%@", r[@"hint_data"][@"checksum"]];
                    self.originalStartHint = [NSString stringWithFormat:@"%@", [NSString stringWithFormat:@"%@", r[@"hint_data"][@"locations"][0]]];
                    self.originalDestinationHint = [NSString stringWithFormat:@"%@", [NSString stringWithFormat:@"%@", [r[@"hint_data"][@"locations"] lastObject]]];
                    if (r[@"route_geometry"]) {
                        NSMutableArray * points = [SMGPSUtil decodePolyline:r[@"route_geometry"]];
                        CLLocationCoordinate2D start = ((CLLocation*)[points objectAtIndex:0]).coordinate;
                        CLLocationCoordinate2D end = ((CLLocation*)[points lastObject]).coordinate;
                        [self getRouteFrom:start to:end via:self.originalViaPoints checksum:[NSString stringWithFormat:@"%@", r[@"hint_data"][@"checksum"]] andStartHint:self.originalStartHint destinationHint:self.originalDestinationHint andZ:DEFAULT_Z];
                    } else {
                        [self getRouteFrom:self.originalStart to:self.originalEnd via:self.originalViaPoints checksum:self.originalChecksum andStartHint:self.originalStartHint destinationHint:self.originalDestinationHint andZ:DEFAULT_Z];
                    }
                }
            }
            
            
        }
    }
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Connection didFailWithError %@",error.localizedDescription);
    if ([self.delegate conformsToProtocol:@protocol(SMRequestOSRMDelegate)]) {
        [self.delegate request:self failedWithError:error];
    }
}

-(void)runBlockIfServerReachable:(void (^)(void))block{
    __weak SMRequestOSRM* selfRef= self;
    __weak NSThread* threadRef= [NSThread currentThread];
    dispatch_async(reachabilityQueue, ^{
        if([selfRef serverReachable]){
            [selfRef performSelector:@selector(runBlock:) onThread:threadRef withObject:block waitUntilDone:NO];
        }
    });
}

-(void)runBlock:(void (^)(void))block{
    block();
}

@end

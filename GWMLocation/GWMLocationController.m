//
//  LocationController.m
//  GWMKit
//
//  Created by Gregory Moore on 4/10/12.
//  Copyright (c) 2012 Gregory Moore All rights reserved.
//

#import "GWMLocationController.h"

#pragma mark Notification Names
NSNotificationName const GWMLocationControllerDidStartUpdatingLocationsNotification = @"GWMLocationControllerDidStartUpdatingLocationsNotification";
NSNotificationName const GWMLocationControllerDidStopUpdatingLocationsNotification = @"GWMLocationControllerDidStopUpdatingLocationsNotification";
NSNotificationName const GWMLocationControllerDidStartMonitoringSignificantLocationChangesNotification = @"GWMLocationControllerDidStartMonitoringSignificantLocationChangesNotification";
NSNotificationName const GWMLocationControllerDidStopMonitoringSignificantLocationChangesNotification = @"GWMLocationControllerDidStopMonitoringSignificantLocationChangesNotification";
NSNotificationName const GWMLocationControllerDidUpdateLocationNotification = @"GWMLocationControllerDidUpdateLocationNotification";
NSNotificationName const GWMLocationControllerDidUpdateSignificantLocationNotification = @"GWMLocationControllerDidUpdateSignificantLocationNotification";
NSNotificationName const GWMLocationControllerDidStartUpdatingHeadingNotification = @"GWMLocationControllerDidStartUpdatingHeadingNotification";
NSNotificationName const GWMLocationControllerDidStopUpdatingHeadingNotification = @"GWMLocationControllerDidStopUpdatingHeadingNotification";
NSNotificationName const GWMLocationControllerDidUpdateHeadingNotification = @"GWMLocationControllerDidUpdateHeading";
NSNotificationName const GWMLocationControllerDidFailWithErrorNotification = @"GWMLocationControllerDidFailWithErrorNotification";
NSNotificationName const GWMLocationControllerDidUpdateAuthorizationStatusNotification = @"GWMLocationControllerDidUpdateAuthorizationStatusNotification";

#pragma mark Preference Keys
NSString * const GWMPK_LocationDesiredAccuracy = @"GWMPK_LocationDesiredAccuracy";
NSString * const GWMPK_LocationDistanceFilter = @"GWMPK_LocationDistanceFilter";
NSString * const GWMPK_LocationUpdateFrquency = @"GWMPK_LocationUpdateFrquency";
NSString * const GWMPK_LocationUserTrackingMode = @"GWMPK_LocationUserTrackingMode";
NSString * const GWMPK_LocationPreferedUpdateMode = @"GWMPK_LocationPreferedUpdateMode";

#pragma mark Notification User Info Keys
NSString * const GWMLocationControllerCurrentLocation = @"GWMLocationControllerCurrentLocation";
NSString * const GWMLocationControllerCurrentHeading = @"GWMLocationControllerCurrentHeading";
NSString * const GWMLocationControllerAuthorizationStatus = @"GWMLocationControllerAuthorizationStatus";
NSString * const GWMLocationControllerError = @"GWMLocationControllerError";

NSTimeInterval const kGWMMaximumUsableLocationAge = 5.0;

@interface GWMLocationController ()

@property (nonatomic, strong) CLLocation *_Nullable location;
@property (nonatomic, strong) CLHeading *_Nullable heading;

@property (nonatomic, strong) GWMLocationCompletionBlock _Nullable locationCompletionHandler;
@property (nonatomic, strong) GWMLocationsUpdateBlock _Nullable locationsUpdateHandler;
@property (nonatomic, strong) GWMHeadingUpdateBlock _Nullable headingUpdateHandler;
@property (nonatomic, readonly) NSMutableDictionary<NSString*,GWMRegionChangeCompletionBlock> *_Nullable regionUpdateHandlerInfo;

@end

@implementation GWMLocationController

#pragma mark - Life Cycle

+(instancetype)sharedController
{
    static GWMLocationController *_sharedLocationController = nil;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        _sharedLocationController = [[self alloc] init];
    });
    
    return _sharedLocationController;
}

-(instancetype)init
{
    if (self = [super init]) {
        
        self.desiredAccuracy = [[[NSUserDefaults standardUserDefaults] valueForKey:GWMPK_LocationDesiredAccuracy] integerValue];
        
        self.distanceFilter = [[[NSUserDefaults standardUserDefaults] valueForKey:GWMPK_LocationDistanceFilter] integerValue];
        
        self.manager.activityType = CLActivityTypeOther;
        self.manager.desiredAccuracy = kCLLocationAccuracyBest;
        self.manager.distanceFilter = kCLDistanceFilterNone;
    }
    return self;
}

-(NSMutableDictionary *)regionUpdateHandlerInfo
{
    if(!_regionChangeCompletionInfo)
        _regionChangeCompletionInfo = [NSMutableDictionary<NSString*,GWMRegionChangeCompletionBlock> new];
    return _regionChangeCompletionInfo;
}

#pragma mark - Controllers

-(CLLocationManager *)manager
{
    if (!_manager) {
        _manager = [[CLLocationManager alloc] init];
        _manager.delegate = self;
    }
    return _manager;
}

#pragma mark - Authorization

-(void)requestAuthorization
{
    [self.manager requestWhenInUseAuthorization];
}

-(void)requestAlwaysAuthorization
{
    [self.manager requestAlwaysAuthorization];
}

#pragma mark - LocationAccuracy

-(CLLocationAccuracy)desiredAccuracy
{
    return self.manager.desiredAccuracy;
}

-(void)setDesiredAccuracy:(CLLocationAccuracy)locationAccuracy
{
    self.manager.desiredAccuracy = locationAccuracy;
}

#pragma mark - Distance Filter

-(CLLocationDistance)distanceFilter
{
    return self.manager.distanceFilter;
}

-(void)setDistanceFilter:(CLLocationDistance)distanceFilter
{
    self.manager.distanceFilter = distanceFilter;
}

#pragma mark - Activity Type

-(CLActivityType)activityType
{
    return self.manager.activityType;
}

-(void)setActivityType:(CLActivityType)activityType
{
    self.manager.activityType = activityType;
}

#pragma mark - Testing Locations

-(BOOL)locationPassesTest:(CLLocation *)location
{
    if (location.timestamp.timeIntervalSinceNow > kGWMMaximumUsableLocationAge)
        return NO;
    
    if (location.horizontalAccuracy < 0)
        return NO;
    
    if (self.desiredAccuracy != kCLLocationAccuracyBest && self.desiredAccuracy != kCLLocationAccuracyBestForNavigation && location.horizontalAccuracy > self.desiredAccuracy)
        return NO;
    
    return YES;
}

#pragma mark - CLLocationManagerDelegate Methods

#pragma mark Location Updated

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = locations.lastObject;
    switch (self.updateMode) {
        case GWMLocationUpdateModeNone:{
            return;
        }
        case GWMLocationUpdateModeSignificant:{
            
            if (location.timestamp.timeIntervalSinceNow > kGWMMaximumUsableLocationAge)
                return;
            
            self.location = location;
            
            NSDictionary *userInfo = @{GWMLocationControllerCurrentLocation: self.location};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidUpdateSignificantLocationNotification object:self userInfo:userInfo];
            
            NSLog(@"Notification (Significant) Posted: %@ Selector: %@", GWMLocationControllerDidUpdateSignificantLocationNotification, NSStringFromSelector(@selector(locationManager:didUpdateLocations:)));
            
            break;
        }
        case GWMLocationUpdateModeStandard:{
            
            if ([locations count] > 0) {
                
                if ([self locationPassesTest:location]){
                    self.location = location;
                    
                    switch (self.updateStyle) {
                        case GWMLocationUpdateStyleSingle:{
                            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopStandardLocationUpdates) object:nil];
                            [self stopStandardLocationUpdates];
                            
                            if(self.locationCompletionHandler)
                                self.locationCompletionHandler(self.location, nil);
                            self.locationCompletionHandler = nil;
                            break;
                        }
                        case GWMLocationUpdateStyleMultiple:{
                            if(self.locationsUpdateHandler)
                                self.locationsUpdateHandler(locations, nil);
                        }
                        default:
                            break;
                    }
                    
                    NSDictionary *userInfo = @{GWMLocationControllerCurrentLocation: self.location};
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidUpdateLocationNotification object:self userInfo:userInfo];
                    
                    NSLog(@"Notification (Standard) Posted: %@ Selector: %@", GWMLocationControllerDidUpdateLocationNotification, NSStringFromSelector(@selector(locationManager:didUpdateLocations:)));
                }
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark Heading Updated

-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    self.heading = newHeading;
    if(self.headingUpdateHandler)
        self.headingUpdateHandler(self.heading, nil);
    
    NSDictionary *userInfo = @{GWMLocationControllerCurrentHeading: newHeading};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidUpdateHeadingNotification object:self userInfo:userInfo];
    
//    NSLog(@"Notification Posted: %@", GWMLocationControllerDidUpdateHeadingNotification);
}

#pragma mark Failed

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    switch (error.code) {
        case kCLErrorDenied:
        case kCLErrorLocationUnknown:{
            
            if (error.code == kCLErrorDenied)
                [self stopAllLocationServices];
            
            if(self.locationCompletionHandler)
                self.locationCompletionHandler(nil, error);
            
            if(self.locationsUpdateHandler)
                self.locationsUpdateHandler(nil, error);
            break;
        }
        case kCLErrorHeadingFailure:{
            if(self.headingUpdateHandler)
                self.headingUpdateHandler(nil, error);
            break;
        }
        default:
            break;
    }
    
    NSDictionary *userInfo = @{GWMLocationControllerError: error};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidFailWithErrorNotification object:self userInfo:userInfo];
    
    
}

#pragma mark Paused

-(void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{

}

-(void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager
{

}

#pragma mark Region Monitoring

-(void)startMonitoringForRegion:(CLRegion *)region withBlock:(nonnull GWMRegionChangeCompletionBlock)completion
{
    if (self.authorizationStatus != kCLAuthorizationStatusAuthorizedAlways)
        [self.manager requestAlwaysAuthorization];
    
    self.regionUpdateHandlerInfo[region.identifier] = completion;
    [self.manager startMonitoringForRegion:region];
}

-(void)stopMonitoringForRegion:(CLRegion *)region
{
    [self.manager stopMonitoringForRegion:region];
    self.regionUpdateHandlerInfo[region.identifier] = nil;
}

-(void)stopMonitoringAllRegions
{
    [self.monitoredRegions enumerateObjectsUsingBlock:^(__kindof CLRegion *_Nonnull reg, BOOL *stop){
        [self stopMonitoringForRegion:reg];
    }];
}

-(void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    
}

-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    GWMRegionChangeCompletionBlock completion = self.regionUpdateHandlerInfo[region.identifier];
    if(completion)
        completion(GWMRegionEntered, region, nil);
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    GWMRegionChangeCompletionBlock completion = self.regionUpdateHandlerInfo[region.identifier];
    if(completion)
        completion(GWMRegionExited, region, nil);
}

-(void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    GWMRegionChangeCompletionBlock completion = self.regionUpdateHandlerInfo[region.identifier];
    if(completion)
        completion(GWMRegionError, region, error);
}

#pragma mark Authorization

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
        {
            [self startSignificantChangeLocationUpdates];
            break;
        }
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            [self stopSignificantChangeLocationUpdates];
            [self stopMonitoringAllRegions];
            break;
        }
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusNotDetermined:
        {
            [self stopStandardLocationUpdates];
            [self stopSignificantChangeLocationUpdates];
            [self stopMonitoringAllRegions];
            break;
        }
        default:
            break;
    }
    
    NSDictionary *userInfo = @{GWMLocationControllerAuthorizationStatus: @(status)};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidUpdateAuthorizationStatusNotification object:self userInfo:userInfo];
    
//    NSLog(@"Notification Posted: %@", GWMLocationControllerDidUpdateAuthorizationStatusNotification);
}

#pragma mark - Location and Heading

//-(CLLocation *)location
//{
//    return self.locationManager.location;
//}

//-(CLHeading *)heading
//{
//    return self.manager.heading;
//}

#pragma mark - Testing Location Services availability

-(BOOL)significantChangeLocationMonitoringAvailable
{
    return [CLLocationManager significantLocationChangeMonitoringAvailable];
}

-(CLAuthorizationStatus)authorizationStatus
{
    return [CLLocationManager authorizationStatus];
}

-(BOOL)isAuthorized
{
    return (self.authorizationStatus == kCLAuthorizationStatusAuthorizedAlways || self.authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse);
}

-(BOOL)locationServicesAvailable
{
    if (![CLLocationManager locationServicesEnabled])
        return NO;
    
    BOOL available = NO;
        
    switch (self.authorizationStatus) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            available = YES;
            break;
        }
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusNotDetermined:
        {
            available =  NO;
            break;
        }
        default:
            break;
    }
    
    return available;
}

-(BOOL)headingAvailable
{
    return [CLLocationManager headingAvailable];
}

#pragma mark - Regions

-(NSSet<CLRegion*>*)monitoredRegions
{
    return self.manager.monitoredRegions;
}

#pragma mark - Starting and stopping location updates

-(void)requestLocationWithCompletion:(GWMLocationCompletionBlock)completionHandler
{
    self.updateStyle = GWMLocationUpdateStyleSingle;
    self.locationsUpdateHandler = nil;
    self.locationCompletionHandler = completionHandler;
    
    [self startStandardLocationUpdates];
}

-(void)requestLocationsWithBlock:(GWMLocationsUpdateBlock)completionHandler
{
    self.updateStyle = GWMLocationUpdateStyleMultiple;
    self.locationCompletionHandler = nil;
    self.locationsUpdateHandler = completionHandler;
    
    [self startStandardLocationUpdates];
}

-(void)startStandardLocationUpdatesWithAccuracy:(CLLocationAccuracy)accuracy distance:(CLLocationDistance)distance
{
    if (!self.locationServicesAvailable)
        return;
    
    [self.manager stopUpdatingLocation];
    [self.manager stopMonitoringSignificantLocationChanges];
    
    self.desiredAccuracy = accuracy;
    
    self.distanceFilter = distance;
    
    self.updateMode = GWMLocationUpdateModeStandard;
    [self.manager startUpdatingLocation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidStartUpdatingLocationsNotification object:self];
    
//    NSLog(@"Notification Posted: %@ Class: %@ Selector: %@", GWMLocationControllerDidStartUpdatingLocationsNotification, NSStringFromClass([self class]), NSStringFromSelector(@selector(startStandardLocationUpdatesWithAccuracy:distance:)));
}

-(void)startStandardLocationUpdates
{
    if (!self.locationServicesAvailable)
        return;
    
    [self.manager stopUpdatingLocation];
    [self.manager stopMonitoringSignificantLocationChanges];
    
    self.updateMode = GWMLocationUpdateModeStandard;
    [self.manager startUpdatingLocation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidStartUpdatingLocationsNotification object:self];
    
//    NSLog(@"Notification Posted: %@ Class: %@ Selector: %@", GWMLocationControllerDidStartUpdatingLocationsNotification, NSStringFromClass([self class]), NSStringFromSelector(@selector(startStandardLocationUpdates)));
}

-(void)stopStandardLocationUpdates
{
    self.updateMode = GWMLocationUpdateModeNone;
    self.updateStyle = GWMLocationUpdateStyleNone;
    [self.manager stopUpdatingLocation];
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidStopUpdatingLocationsNotification object:self];
    
//    NSLog(@"Notification Posted: %@", GWMLocationControllerDidStopUpdatingLocationsNotification);
}

-(void)startSignificantChangeLocationUpdates
{
    if (![self locationServicesAvailable] || ![self significantChangeLocationMonitoringAvailable])
        return;
        
    [self.manager stopUpdatingLocation];
    
    self.updateMode = GWMLocationUpdateModeSignificant;
    [self.manager startMonitoringSignificantLocationChanges];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidStartMonitoringSignificantLocationChangesNotification object:self];
    
//    NSLog(@"Notification Posted: %@", GWMLocationControllerDidStartMonitoringSignificantLocationChangesNotification);
}

-(void)stopSignificantChangeLocationUpdates
{
    self.updateMode = GWMLocationUpdateModeNone;
    self.updateStyle = GWMLocationUpdateStyleNone;
    [self.manager stopMonitoringSignificantLocationChanges];
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidStopMonitoringSignificantLocationChangesNotification object:self];
//    NSLog(@"Notification Posted: %@", GWMLocationControllerDidStopMonitoringSignificantLocationChangesNotification);
}

-(void)stopAllLocationServices
{
    [self stopUpdatingHeading];
    [self stopStandardLocationUpdates];
    [self stopSignificantChangeLocationUpdates];
    [self stopMonitoringAllRegions];
}

#pragma mark - Starting and stopping heading updates

-(void)requestHeadingsWithBlock:(GWMHeadingUpdateBlock)headingUpdateHandler
{
    self.headingUpdateHandler = headingUpdateHandler;
    [self startUpdatingHeading];
}

-(void)startUpdatingHeading
{
    if (!self.headingAvailable)
        return;
    
    [self.manager startUpdatingHeading];
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidStartUpdatingHeadingNotification object:self];
//    NSLog(@"Notification Posted: %@", GWMLocationControllerDidStartUpdatingHeadingNotification);
}

-(void)stopUpdatingHeading
{
    self.headingUpdateHandler = nil;
    [self.manager stopUpdatingHeading];
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidStopUpdatingHeadingNotification object:self];
//    NSLog(@"Notification Posted: %@", GWMLocationControllerDidStopUpdatingHeadingNotification);
}

@end

//
//  LocationController.m
//  GWMKit
//
//  Created by Gregory Moore on 4/10/12.
//  Copyright (c) 2012 Gregory Moore All rights reserved.
//

#import "GWMLocationController.h"

NSString * const GWMLocationControllerDidStartUpdatingLocationsNotification = @"GWMLocationControllerDidStartUpdatingLocationsNotification";
NSString * const GWMLocationControllerDidStopUpdatingLocationsNotification = @"GWMLocationControllerDidStopUpdatingLocationsNotification";
NSString * const GWMLocationControllerDidStartMonitoringSignificantLocationChangesNotification = @"GWMLocationControllerDidStartMonitoringSignificantLocationChangesNotification";
NSString * const GWMLocationControllerDidStopMonitoringSignificantLocationChangesNotification = @"GWMLocationControllerDidStopMonitoringSignificantLocationChangesNotification";
NSString * const GWMLocationControllerDidUpdateLocationNotification = @"GWMLocationControllerDidUpdateLocationNotification";
NSString * const GWMLocationControllerDidUpdateSignificantLocationNotification = @"GWMLocationControllerDidUpdateSignificantLocationNotification";
NSString * const GWMLocationControllerDidStartUpdatingHeadingNotification = @"GWMLocationControllerDidStartUpdatingHeadingNotification";
NSString * const GWMLocationControllerDidStopUpdatingHeadingNotification = @"GWMLocationControllerDidStopUpdatingHeadingNotification";
NSString * const GWMLocationControllerDidUpdateHeadingNotification = @"GWMLocationControllerDidUpdateHeading";
NSString * const GWMLocationControllerDidFailWithErrorNotification = @"GWMLocationControllerDidFailWithErrorNotification";
NSString * const GWMLocationControllerDidUpdateAuthorizationStatusNotification = @"GWMLocationControllerDidUpdateAuthorizationStatusNotification";

NSString * const GWMPK_LocationDesiredAccuracy = @"GWMPK_LocationDesiredAccuracy";
NSString * const GWMPK_LocationDistanceFilter = @"GWMPK_LocationDistanceFilter";
NSString * const GWMPK_LocationUpdateFrquency = @"GWMPK_LocationUpdateFrquency";
NSString * const GWMPK_LocationUserTrackingMode = @"GWMPK_LocationUserTrackingMode";
NSString * const GWMPK_LocationPreferedUpdateMode = @"GWMPK_LocationPreferedUpdateMode";

NSString * const GWMLocationControllerCurrentLocation = @"GWMLocationControllerCurrentLocation";
NSString * const GWMLocationControllerCurrentHeading = @"GWMLocationControllerCurrentHeading";
NSString * const GWMLocationControllerAuthorizationStatus = @"GWMLocationControllerAuthorizationStatus";
NSString * const GWMLocationControllerError = @"GWMLocationControllerError";

NSTimeInterval const kGWMMaximumUsableLocationAge = 5.0;

@interface GWMLocationController ()

@property (nonatomic, strong) CLLocation *_Nullable location;

@property (nonatomic, strong) GWMSingleLocationCompletionBlock _Nullable singleLocationCompletion;
@property (nonatomic, strong) GWMMultipleLocationsCompletionBlock _Nullable multipleLocationsCompletion;

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
        self.locationAccuracy = [[[NSUserDefaults standardUserDefaults] valueForKey:GWMPK_LocationDesiredAccuracy] integerValue];
        
        self.distanceFilter = [[[NSUserDefaults standardUserDefaults] valueForKey:GWMPK_LocationDistanceFilter] integerValue];
        
        self.locationManager.activityType = CLActivityTypeOther;
        
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    
}

-(void)applicationDidReceiveMemoryWarning
{
    [self stopAllLocationServices];
    _locationManager.delegate = nil;
    _locationManager = nil;
}

#pragma mark - Controllers

-(CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

#pragma mark - LocationAccuracy

-(GWMLocationDesiredAccuracy)locationAccuracy
{
    return _locationAccuracy;
}

-(void)setLocationAccuracy:(GWMLocationDesiredAccuracy)locationAccuracy
{
    _locationAccuracy = locationAccuracy;
    switch (locationAccuracy) {
        case GWMLocationDesiredAccuracyBest:
        {
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            break;
        }
        case GWMLocationDesiredAccuracyTenMeters:
        {
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
            break;
        }
        case GWMLocationDesiredAccuracyHundredMeters:
        {
            self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
            break;
        }
        case GWMLocationDesiredAccuracyKilometer:
        {
            self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
            break;
        }
        default:
            break;
    }
}

#pragma mark - Distance Filter

-(GWMDistanceFilter)distanceFilter
{
    return _distanceFilter;
}

-(void)setDistanceFilter:(GWMDistanceFilter)distanceFilter
{
    _distanceFilter = distanceFilter;
    switch (distanceFilter) {
        case GWMDistanceFilterNone:
        {
            self.locationManager.distanceFilter = kCLDistanceFilterNone;
            break;
        }
        case GWMDistanceFilterFiveMeters:
        {
            self.locationManager.distanceFilter = 5;
            break;
        }
        case GWMDistanceFilterTenMeters:
        {
            self.locationManager.distanceFilter = 10;
            break;
        }
        default:
            break;
    }
}

#pragma mark - Getting Locations

-(void)singleLocationWithCompletion:(GWMSingleLocationCompletionBlock)completionHandler
{
    self.multipleLocationsCompletion = nil;
    self.singleLocationCompletion = completionHandler;
    
    [self startStandardLocationUpdates];
}

-(void)multipleLocationsWithCompletion:(GWMMultipleLocationsCompletionBlock)completionHandler
{
    self.singleLocationCompletion = nil;
    self.multipleLocationsCompletion = completionHandler;
    
    [self startStandardLocationUpdates];
}

#pragma mark - Testing Locations

-(BOOL)locationPassesTest:(CLLocation *)location
{
    if (location.timestamp.timeIntervalSinceNow > kGWMMaximumUsableLocationAge)
        return NO;
    
    if (location.horizontalAccuracy < 0)
        return NO;
    
    if (location.horizontalAccuracy > self.locationManager.desiredAccuracy)
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
            
            [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidUpdateSignificantLocationNotification object:self userInfo:userInfo];NSLog(@"Notification (Significant) Posted: %@ Selector: %@", GWMLocationControllerDidUpdateSignificantLocationNotification, NSStringFromSelector(@selector(locationManager:didUpdateLocations:)));
            
            break;
        }
        case GWMLocationUpdateModeStandard:{
            
            if ([locations count] > 0) {
                
                if ([self locationPassesTest:location]){
                    self.location = location;
                    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopStandardLocationUpdates) object:nil];
                    [self stopStandardLocationUpdates];
                    
                    if(self.singleLocationCompletion)
                        self.singleLocationCompletion(self.location);
                    
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
    NSDictionary *userInfo = @{GWMLocationControllerCurrentHeading: newHeading};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidUpdateHeadingNotification object:self userInfo:userInfo];
    
//    NSLog(@"Notification Posted: %@", GWMLocationControllerDidUpdateHeadingNotification);
}

#pragma mark Failed

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    switch (error.code) {
        case kCLErrorDenied:
            [self stopAllLocationServices];
            break;
            
        case kCLErrorLocationUnknown:
        case kCLErrorHeadingFailure:
            break;
        default:
            break;
    }
    
    NSDictionary *userInfo = @{GWMLocationControllerError: error};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidFailWithErrorNotification object:self userInfo:userInfo];
    
//    NSLog(@"Notification Posted: %@ Message: %@", GWMLocationControllerDidFailWithErrorNotification, error.localizedDescription);
}

#pragma mark Paused

-(void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{

}

-(void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager
{

}

#pragma mark Region Monitoring

-(void)startMonitoringForRegion:(CLRegion *)region
{
    [self.locationManager startMonitoringForRegion:region];
}

-(void)stopMonitoringForRegion:(CLRegion *)region
{
    [self.locationManager stopMonitoringForRegion:region];
}

-(void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    
}

-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    
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
            break;
        }
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusNotDetermined:
        {
            [self stopStandardLocationUpdates];
            [self stopSignificantChangeLocationUpdates];
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

-(CLHeading *)heading
{
    return self.locationManager.heading;
}

#pragma mark - Testing Location Services availability

-(BOOL)significantChangeLocationMonitoringAvailable
{
    return [CLLocationManager significantLocationChangeMonitoringAvailable];
}

-(CLAuthorizationStatus)authorizationStatus
{
    return [CLLocationManager authorizationStatus];
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

#pragma mark - Starting and stopping location updates

-(void)startStandardLocationUpdatesWithAccuracy:(GWMLocationDesiredAccuracy)accuracy distance:(GWMDistanceFilter)distance
{
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopMonitoringSignificantLocationChanges];
    
    if (!self.locationServicesAvailable)
        return;
    
    self.locationAccuracy = accuracy;
    
    self.distanceFilter = distance;
    
    self.updateMode = GWMLocationUpdateModeStandard;
    [self.locationManager startUpdatingLocation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidStartUpdatingLocationsNotification object:self];
    
//    NSLog(@"Notification Posted: %@ Class: %@ Selector: %@", GWMLocationControllerDidStartUpdatingLocationsNotification, NSStringFromClass([self class]), NSStringFromSelector(@selector(startStandardLocationUpdatesWithAccuracy:distance:)));
}

-(void)startStandardLocationUpdates
{
    [self.locationManager stopUpdatingLocation];
    
    self.locationAccuracy = [[[NSUserDefaults standardUserDefaults] valueForKey:GWMPK_LocationDesiredAccuracy] integerValue];
    
    self.distanceFilter = [[[NSUserDefaults standardUserDefaults] valueForKey:GWMPK_LocationDistanceFilter] integerValue];
    
    self.updateMode = GWMLocationUpdateModeStandard;
    [self.locationManager startUpdatingLocation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidStartUpdatingLocationsNotification object:self];
    
//    NSLog(@"Notification Posted: %@ Class: %@ Selector: %@", GWMLocationControllerDidStartUpdatingLocationsNotification, NSStringFromClass([self class]), NSStringFromSelector(@selector(startStandardLocationUpdates)));
}

-(void)stopStandardLocationUpdates
{
    self.updateMode = GWMLocationUpdateModeNone;
    [self.locationManager stopUpdatingLocation];
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidStopUpdatingLocationsNotification object:self];
    
//    NSLog(@"Notification Posted: %@", GWMLocationControllerDidStopUpdatingLocationsNotification);
}

-(void)startSignificantChangeLocationUpdates
{
    if (![self locationServicesAvailable] || ![self significantChangeLocationMonitoringAvailable])
        return;
        
    [self.locationManager stopUpdatingLocation];
    
    self.updateMode = GWMLocationUpdateModeSignificant;
    [self.locationManager startMonitoringSignificantLocationChanges];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidStartMonitoringSignificantLocationChangesNotification object:self];
    
//    NSLog(@"Notification Posted: %@", GWMLocationControllerDidStartMonitoringSignificantLocationChangesNotification);
}

-(void)stopSignificantChangeLocationUpdates
{
    self.updateMode = GWMLocationUpdateModeNone;
    [self.locationManager stopMonitoringSignificantLocationChanges];
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidStopMonitoringSignificantLocationChangesNotification object:self];
//    NSLog(@"Notification Posted: %@", GWMLocationControllerDidStopMonitoringSignificantLocationChangesNotification);
}

-(void)requestLocationAuthorization
{
    [self.locationManager requestWhenInUseAuthorization];
}

-(void)stopAllLocationServices
{
    [self stopUpdatingHeading];
    [self stopStandardLocationUpdates];
    [self stopSignificantChangeLocationUpdates];
}

#pragma mark - Starting and stopping heading updates

-(void)startUpdatingHeading
{
    if (!self.headingAvailable)
        return;
    
    [self.locationManager startUpdatingHeading];
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidStartUpdatingHeadingNotification object:self];
//    NSLog(@"Notification Posted: %@", GWMLocationControllerDidStartUpdatingHeadingNotification);
}

-(void)stopUpdatingHeading
{
    [self.locationManager stopUpdatingHeading];
    [[NSNotificationCenter defaultCenter] postNotificationName:GWMLocationControllerDidStopUpdatingHeadingNotification object:self];
//    NSLog(@"Notification Posted: %@", GWMLocationControllerDidStopUpdatingHeadingNotification);
}

@end

//
//  LocationController.h
//  GWMKit
//
//  Created by Gregory Moore on 4/10/12.
//  Copyright (c) 2012 Gregory Moore All rights reserved.
//

@import Foundation;
@import CoreLocation;

#if TARGET_IPHONE_SIMULATOR
@import UIKit;
#elif TARGET_OS_IPHONE
@import UIKit;
#elif TARGET_OS_MAC
@import AppKit;
#endif

typedef NS_ENUM(NSInteger, GWMLocationUpdateMode) {
    GWMLocationUpdateModeNone = 0,
    GWMLocationUpdateModeStandard,
    GWMLocationUpdateModeSignificant
};

typedef NS_ENUM(NSInteger, GWMLocationDesiredAccuracy) {
    GWMLocationDesiredAccuracyBest = 0,
    GWMLocationDesiredAccuracyTenMeters,
    GWMLocationDesiredAccuracyHundredMeters,
    GWMLocationDesiredAccuracyKilometer
};

typedef NS_ENUM(NSInteger, GWMDistanceFilter) {
    GWMDistanceFilterNone = 0,
    GWMDistanceFilterFiveMeters,
    GWMDistanceFilterTenMeters
};

NS_ASSUME_NONNULL_BEGIN

extern NSString * const GWMLocationControllerDidStartUpdatingLocationsNotification;
extern NSString * const GWMLocationControllerDidStopUpdatingLocationsNotification;
extern NSString * const GWMLocationControllerDidStartMonitoringSignificantLocationChangesNotification;
extern NSString * const GWMLocationControllerDidStopMonitoringSignificantLocationChangesNotification;
extern NSString * const GWMLocationControllerDidUpdateLocationNotification;
extern NSString * const GWMLocationControllerDidUpdateSignificantLocationNotification;
extern NSString * const GWMLocationControllerDidStartUpdatingHeadingNotification;
extern NSString * const GWMLocationControllerDidStopUpdatingHeadingNotification;
extern NSString * const GWMLocationControllerDidUpdateHeadingNotification;
extern NSString * const GWMLocationControllerDidFailWithErrorNotification;
extern NSString * const GWMLocationControllerDidUpdateAuthorizationStatusNotification;

extern NSString * const GWMPK_LocationDesiredAccuracy;
extern NSString * const GWMPK_LocationDistanceFilter;
extern NSString * const GWMPK_LocationUpdateFrquency;
extern NSString * const GWMPK_LocationUserTrackingMode;
extern NSString * const GWMPK_LocationPreferedUpdateMode;

extern NSString * const GWMLocationControllerCurrentLocation;
extern NSString * const GWMLocationControllerCurrentHeading;
extern NSString * const GWMLocationControllerAuthorizationStatus;
/*!
 * @brief An NSString key into an NSDictionary.
 * @discussion Used to retrieve an NSError object from an NSNotification's userInfo dictionary.
 */
extern NSString * const GWMLocationControllerError;

extern NSTimeInterval const kGWMMaximumUsableLocationAge;

typedef void (^GWMSingleLocationCompletionBlock)(CLLocation *location);
typedef void (^GWMMultipleLocationsCompletionBlock)(NSArray<CLLocation*> *locations);

@interface GWMLocationController : NSObject <CLLocationManagerDelegate>
{
    GWMLocationDesiredAccuracy _locationAccuracy;
    GWMDistanceFilter _distanceFilter;
    CLLocationManager *_locationManager;
}

@property (nonatomic, assign) GWMLocationUpdateMode updateMode;

@property (nonatomic) GWMLocationDesiredAccuracy locationAccuracy;
@property (nonatomic) GWMDistanceFilter distanceFilter;

@property (nonatomic, readonly) BOOL locationServicesAvailable;
@property (nonatomic, readonly) BOOL significantChangeLocationMonitoringAvailable;

@property (nonatomic, readonly) CLLocationManager *locationManager;
@property (nonatomic, readonly) CLLocation *_Nullable location;
@property (nonatomic, readonly) CLHeading *_Nullable heading;

@property (nonatomic, readonly) BOOL headingAvailable;

@property (nonatomic, readonly) CLAuthorizationStatus authorizationStatus;

+(instancetype)sharedController;

#pragma mark - Getting Locations

-(void)singleLocationWithCompletion:(GWMSingleLocationCompletionBlock)completionHandler;
-(void)multipleLocationsWithCompletion:(GWMMultipleLocationsCompletionBlock)completionHandler;

#pragma mark -

-(void)startStandardLocationUpdatesWithAccuracy:(GWMLocationDesiredAccuracy)accuracy distance:(GWMDistanceFilter)distance;

-(void)startStandardLocationUpdates;
-(void)stopStandardLocationUpdates;

-(void)startSignificantChangeLocationUpdates;
-(void)stopSignificantChangeLocationUpdates;

-(void)startMonitoringForRegion:(CLRegion *)region;
-(void)stopMonitoringForRegion:(CLRegion *)region;

-(void)requestLocationAuthorization;
-(void)stopAllLocationServices;

-(void)startUpdatingHeading;
-(void)stopUpdatingHeading;

@end

NS_ASSUME_NONNULL_END

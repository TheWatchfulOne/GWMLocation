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
///@discussion Used to retrieve an NSError object from an NSNotification's userInfo dictionary.
extern NSString * const GWMLocationControllerError;

///@discussion An NSArray containing the query results.
extern NSTimeInterval const kGWMMaximumUsableLocationAge;
/*!
 * @brief A block that runs on completion of some SQLite queries. Can be nil.
 * @param location A GWMDataItem containing the itemID of the record that was just inserted or updated.
 * @param error A GWMDataItem containing the itemID of the record that was just inserted or updated.
 */
typedef void (^GWMSingleLocationCompletionBlock)(CLLocation *_Nullable location, NSError *_Nullable error);
/*!
 * @brief A block that runs on completion of some SQLite queries. Can be nil.
 * @param locations A GWMDataItem containing the itemID of the record that was just inserted or updated.
 * @param error A GWMDataItem containing the itemID of the record that was just inserted or updated.
 */
typedef void (^GWMMultipleLocationsCompletionBlock)(NSArray<CLLocation*> *_Nullable locations, NSError *_Nullable error);

/*!
 * @class GWMLocationController
 * @discussion Use an instance of this class to interact with Location Services.
 */
@interface GWMLocationController : NSObject <CLLocationManagerDelegate>
{
    GWMLocationDesiredAccuracy _locationAccuracy;
    GWMDistanceFilter _distanceFilter;
    CLLocationManager *_locationManager;
}

///@discussion An NSArray containing the query results.
@property (nonatomic, assign) GWMLocationUpdateMode updateMode;

///@discussion An NSArray containing the query results.
@property (nonatomic) GWMLocationDesiredAccuracy locationAccuracy;
///@discussion An NSArray containing the query results.
@property (nonatomic) GWMDistanceFilter distanceFilter;

///@discussion An NSArray containing the query results.
@property (nonatomic, readonly) BOOL locationServicesAvailable;
///@discussion An NSArray containing the query results.
@property (nonatomic, readonly) BOOL significantChangeLocationMonitoringAvailable;

///@discussion An NSArray containing the query results.
@property (nonatomic, readonly) CLLocationManager *locationManager;
///@discussion An NSArray containing the query results.
@property (nonatomic, readonly) CLLocation *_Nullable location;
///@discussion An NSArray containing the query results.
@property (nonatomic, readonly) CLHeading *_Nullable heading;

///@discussion An NSArray containing the query results.
@property (nonatomic, readonly) BOOL headingAvailable;

///@discussion An NSArray containing the query results.
@property (nonatomic, readonly) CLAuthorizationStatus authorizationStatus;

+(instancetype)sharedController;

#pragma mark - Getting Locations

-(void)singleLocationWithCompletion:(GWMSingleLocationCompletionBlock)completionHandler;
-(void)multipleLocationsWithCompletion:(GWMMultipleLocationsCompletionBlock)completionHandler;

#pragma mark -

-(void)startStandardLocationUpdatesWithAccuracy:(GWMLocationDesiredAccuracy)accuracy distance:(GWMDistanceFilter)distance;

///@discussion Start receiving location updates.
-(void)startStandardLocationUpdates;
///@discussion Stop receiving location updates.
-(void)stopStandardLocationUpdates;

///@discussion Start receiving significant location updates.
-(void)startSignificantChangeLocationUpdates;
///@discussion Stop receiving significant location updates.
-(void)stopSignificantChangeLocationUpdates;

/*!
 * @discussion Start monitoring the specified region.
 * @param region The CLRegion to monitor.
 */
-(void)startMonitoringForRegion:(CLRegion *)region;
/*!
 * @discussion Stop monitoring the specified region.
 * @param region The CLRegion to stop monitoring.
 */
-(void)stopMonitoringForRegion:(CLRegion *)region;

-(void)requestLocationAuthorization;
-(void)stopAllLocationServices;

///@discussion Start receiving heading updates.
-(void)startUpdatingHeading;
///@discussion Stop receiving heading updates.
-(void)stopUpdatingHeading;

@end

NS_ASSUME_NONNULL_END

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

typedef NS_ENUM(NSInteger, GWMRegionChange) {
    GWMRegionEntered = 0,
    GWMRegionExited,
    GWMRegionError
};

NS_ASSUME_NONNULL_BEGIN

#pragma mark Notification Names
///@brief Posted when location updates have started.
extern NSNotificationName const GWMLocationControllerDidStartUpdatingLocationsNotification;
///@brief Posted when location updates have stopped.
extern NSNotificationName const GWMLocationControllerDidStopUpdatingLocationsNotification;
///@brief Posted when significant location updates have started.
extern NSNotificationName const GWMLocationControllerDidStartMonitoringSignificantLocationChangesNotification;
///@brief Posted when significant location updates have stopped.
extern NSNotificationName const GWMLocationControllerDidStopMonitoringSignificantLocationChangesNotification;
///@brief Posted when location is updated.
extern NSNotificationName const GWMLocationControllerDidUpdateLocationNotification;
///@brief Posted when location is updated by a significant location change.
extern NSNotificationName const GWMLocationControllerDidUpdateSignificantLocationNotification;
///@brief Posted when heading updates have started.
extern NSNotificationName const GWMLocationControllerDidStartUpdatingHeadingNotification;
///@brief Posted when heading updates have stopped.
extern NSNotificationName const GWMLocationControllerDidStopUpdatingHeadingNotification;
///@brief Posted when heading is updated.
extern NSNotificationName const GWMLocationControllerDidUpdateHeadingNotification;
///@brief Posted when location updates have failed.
extern NSNotificationName const GWMLocationControllerDidFailWithErrorNotification;
///@brief Posted when location authorization status changes.
extern NSNotificationName const GWMLocationControllerDidUpdateAuthorizationStatusNotification;
#pragma mark Preference Keys
extern NSString * const GWMPK_LocationDesiredAccuracy;
extern NSString * const GWMPK_LocationDistanceFilter;
extern NSString * const GWMPK_LocationUpdateFrquency;
extern NSString * const GWMPK_LocationUserTrackingMode;
extern NSString * const GWMPK_LocationPreferedUpdateMode;
#pragma mark Notification UserInfo Keys
///@brief Used to retrieve the CLLocation object representing the current location from an NSNotification's userInfo dictionary.
extern NSString * const GWMLocationControllerCurrentLocation;
///@brief Used to retrieve the CLHeading object representing the current heading from an NSNotification's userInfo dictionary.
extern NSString * const GWMLocationControllerCurrentHeading;
extern NSString * const GWMLocationControllerAuthorizationStatus;
///@brief Used to retrieve an NSError object from an NSNotification's userInfo dictionary.
extern NSString * const GWMLocationControllerError;

///@brief An NSArray containing the query results.
extern NSTimeInterval const kGWMMaximumUsableLocationAge;
/*!
 * @brief This block gets called when a new location is acquired.
 * @param location A CLLocation oject representing the most recent acquired location.
 * @param error A NSError object.
 */
typedef void (^GWMSingleLocationCompletionBlock)(CLLocation *_Nullable location, NSError *_Nullable error);
/*!
 * @brief This block gets called when a new location is acquired.
 * @param locations A NSArray of CLLocation objects.
 * @param error A NSError object.
 */
typedef void (^GWMMultipleLocationsCompletionBlock)(NSArray<CLLocation*> *_Nullable locations, NSError *_Nullable error);
/*!
 * @brief This block gets called when entering or exiting a new region.
 * @param region A CLRegion oject representing the region that was just entered or exited.
 * @param change A GWMRegionChange value indicating whether the region was entered or exited.
 * @param error A NSError object.
 */
typedef void (^GWMRegionChangeCompletionBlock)(GWMRegionChange change, CLRegion *_Nullable region, NSError *_Nullable error);

/*!
 * @class GWMLocationController
 * @discussion Use an instance of this class to interact with Location Services.
 */
@interface GWMLocationController : NSObject <CLLocationManagerDelegate>
{
    CLLocationManager *_locationManager;
    NSMutableDictionary<NSString*,GWMRegionChangeCompletionBlock> *_regionChangeCompletionInfo;
}

/*!
 * @brief Indicates the frequency at which location updates might happen.
 * @discussion The basic value choices are 'none', 'standard' and 'significant'. A value of 'significant' indicates significant change location monitoring is happening and therefore acquired locations will be scrutinized less strenuously than for standard location updates.
 */
@property (nonatomic, assign) GWMLocationUpdateMode updateMode;

///@brief The current minimum accuracy of locations acquired by the device.
@property (nonatomic) CLLocationAccuracy desiredAccuracy;
///@brief The minimum distance the device needs to move before a new location event is triggered.
@property (nonatomic) CLLocationDistance distanceFilter;
/*!
 * @brief Tells whether Location Services are available on the device.
 * @discussion This is affected by the capabilities of the device as well as the authorization status.
 */
@property (nonatomic, readonly) BOOL locationServicesAvailable;
///@brief Tells whether the device is capable of monitoring for significant location changes.
@property (nonatomic, readonly) BOOL significantChangeLocationMonitoringAvailable;

///@brief The location manager.
@property (nonatomic, readonly) CLLocationManager *locationManager;
///@brief The most recently acquired location.
@property (nonatomic, readonly) CLLocation *_Nullable location;
///@brief The most recently acquired heading.
@property (nonatomic, readonly) CLHeading *_Nullable heading;

///@brief Tells whether the device can acquire a heading.
@property (nonatomic, readonly) BOOL headingAvailable;

///@brief The current permission granted for acquiring locations.
@property (nonatomic, readonly) CLAuthorizationStatus authorizationStatus;

///@brief The shared GWMLocationController instance.
+(instancetype)sharedController;

#pragma mark - Authorization

-(void)requestAuthorization;
-(void)requestAlwaysAuthorization;

#pragma mark - Getting Locations

-(void)singleLocationWithCompletion:(GWMSingleLocationCompletionBlock)completionHandler;
-(void)multipleLocationsWithCompletion:(GWMMultipleLocationsCompletionBlock)completionHandler;

#pragma mark -

-(void)startStandardLocationUpdatesWithAccuracy:(CLLocationAccuracy)accuracy distance:(CLLocationDistance)distance;

///@brief Start receiving location updates.
-(void)startStandardLocationUpdates;
///@brief Stop receiving location updates.
-(void)stopStandardLocationUpdates;

///@brief Start receiving significant location updates.
-(void)startSignificantChangeLocationUpdates;
///@brief Stop receiving significant location updates.
-(void)stopSignificantChangeLocationUpdates;

/*!
 * @brief Start monitoring the specified region.
 * @param region The CLRegion to monitor.
 */
-(void)startMonitoringForRegion:(CLRegion *)region completion:(GWMRegionChangeCompletionBlock)completion;
/*!
 * @brief Stop monitoring the specified region.
 * @param region The CLRegion to stop monitoring.
 */
-(void)stopMonitoringForRegion:(CLRegion *)region;

-(void)stopMonitorigAllRegions;
-(void)stopAllLocationServices;

///@brief Start receiving heading updates.
-(void)startUpdatingHeading;
///@brief Stop receiving heading updates.
-(void)stopUpdatingHeading;

@end

NS_ASSUME_NONNULL_END

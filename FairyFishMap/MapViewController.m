//
//  MapViewController.m
//  FairyFishMap
//
//  Created by jinhui005 on 16/9/14.
//  Copyright © 2016年 yhl. All rights reserved.
//

#import "MapViewController.h"
#import "MapKit/MapKit.h"               //原生地图头文件
#import "CoreLocation/CoreLocation.h"   //核心定位服务头文件
#import "CLLocation+Sino.h"

@interface MapViewController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) UISegmentedControl *segment;

@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addSubview:self.mapView];
    [self.view addSubview:self.segment];
 
    CGRect rect = [UIScreen mainScreen].bounds;
    self.mapView.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);
    self.segment.frame=CGRectMake(30,30,180,30);
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (kCLAuthorizationStatusNotDetermined == status) {
        [self.locationManager requestAlwaysAuthorization];
    }
    [self.locationManager startUpdatingLocation];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - 交互
- (void)longPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) {
        return;
    }
    CGPoint longPressPoint = [sender locationInView:self.mapView];
    CLLocationCoordinate2D coordinate2d = [self.mapView convertPoint:longPressPoint toCoordinateFromView:self.mapView];
    
    //添加大头针
    MKPointAnnotation *pointAnnotation = [[MKPointAnnotation alloc] init];
    pointAnnotation.coordinate = coordinate2d;
    pointAnnotation.title = @"我在这里";
    pointAnnotation.subtitle = @"使用这个位置";
    
    [self.mapView addAnnotation:pointAnnotation];
    MKCircle *circle =[MKCircle circleWithCenterCoordinate:coordinate2d radius:20];
    
    //先添加，在回调方法中创建覆盖物
    
    [_mapView addOverlay:circle];
    
}

//大头针的回调方法（与cell的复用机制很相似）
-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id)annotation{
    
    //复用
    MKPinAnnotationView *annotationView =(MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"PIN"];
    
    //判断复用池中是否有可用的
    if(annotationView==nil) {
        annotationView =(MKPinAnnotationView *)[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"PIN"];
    }
    
    //添加左边的视图
    UIImageView *imageView =[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arraw"]];
    imageView.frame=CGRectMake(0,0,50,50);
    annotationView.leftCalloutAccessoryView=imageView;
    
    //显示
    annotationView.canShowCallout=YES;
    
    //设置是否显示动画
    annotationView.animatesDrop=YES;
    
    //设置右边视图
    UILabel *label =[[UILabel alloc] initWithFrame:CGRectMake(0,0,30,30)];
    label.text=@">>";
    annotationView.rightCalloutAccessoryView=label;
    
    //设置大头针的颜色
    annotationView.pinColor = MKPinAnnotationColorRed;
    return annotationView;
    
}

//覆盖物的回调方法

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id)overlay{
    
    //创建圆形覆盖物
    MKCircleRenderer *circleRender =[[MKCircleRenderer alloc] initWithCircle:overlay];
    
    //设置边缘颜色
    circleRender.strokeColor=[UIColor grayColor];
    
    return circleRender;
    
}

//解决手势冲突，可以同时使用多个手势

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)mapTypeChanged:(UISegmentedControl *)sender {
    self.mapView.mapType = sender.selectedSegmentIndex;
}

#pragma mark - getter setter
-(MKMapView *)mapView {
    if (nil == _mapView) {
        _mapView = [[MKMapView alloc] init];
        _mapView.delegate = self;
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [_mapView addGestureRecognizer:longPress];
    }
    return _mapView;
}

-(CLLocationManager *)locationManager {
    if (nil == _locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        //设置定位属性
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        //设置定位更行距离  米
        _locationManager.distanceFilter = 10.0;
        _locationManager.delegate = self;
    }
    return _locationManager;
}

-(UISegmentedControl *)segment {
    if (nil == _segment) {
        NSArray *array = @[@"标准", @"卫星", @"混合"];
        _segment = [[UISegmentedControl alloc] initWithItems:array];
        [_segment addTarget:self action:@selector(mapTypeChanged:) forControlEvents:UIControlEventValueChanged];
        _segment.selectedSegmentIndex = 0;
    }
    return _segment;
}

#pragma mark - CLLocationmanagerDelegate
//定位后的回调，返回结果
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = [locations firstObject];
    
    //火星坐标转地球坐标
    location=[location locationMarsFromEarth];
    //设置地图显示经纬度的位置
    MKCoordinateRegion region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(0.01, 0.01));
    [self.mapView setRegion:region animated:YES];
    
    //创建大头针
    MKPointAnnotation *pointAnnotation = [[MKPointAnnotation alloc] init];
    pointAnnotation.coordinate = location.coordinate;
    pointAnnotation.title = @"我在这里";
    pointAnnotation.subtitle = @"这是什么鬼";
    
    [self.mapView addAnnotation:pointAnnotation];
}

@end

//
//  XDBLE.h
//  BLEDemo
//
//  Created by apple on 2018/6/21.
//  Copyright © 2018年 孙晓东. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SERVICE @"FF00" //服务特征
#define WRITECHARACTER @"FF01" //写特征
#define READCHARACTER @"FF02"  //读特征

/**
 扫描结束后所有蓝牙集合
 @param devices 蓝牙名称集合
 */
typedef void(^DeviceNames)(NSArray *devices);

/**
 扫描到蓝牙的名称

 @param deviceName 蓝牙名称
 @param stop 是否停止扫描
 */
typedef void(^RealDevice)(NSString *deviceName,BOOL *stop);


/**
 蓝牙状态

 - XD_BLE_OPEN: 蓝牙打开
 - XD_BLE_CLOSE: 蓝牙关闭
 */
typedef NS_ENUM(NSInteger,XD_BLE_STATE) {
    XD_BLE_OPEN,
    XD_BLE_CLOSE
};


/**
 蓝牙状态回调

 @param xd_ble_state 蓝牙状态
 */
typedef void(^BleState)(XD_BLE_STATE xd_ble_state);


/**
 连接状态

 - UNKNOWN_DEVICE: 没有此蓝牙名称
 - CONNECT_SUCCESS: 连接成功
 - CONNECT_FAILED: 连接失败
 - DIS_CONNECT: 断开连接
 */
typedef NS_ENUM(NSInteger,CONNECT_STATE) {
    UNKNOWN_DEVICE,
    CONNECT_SUCCESS,
    CONNECT_FAILED,
    DIS_CONNECT
};

/**
 连接状态回调

 @param connectState 连接状态
 */
typedef void(^ConnectState)(CONNECT_STATE connectState);


typedef void(^NotifyValue)(NSData *value);

@interface XDBLE : NSObject
/**
 连接状态
 */
@property (nonatomic,assign)CONNECT_STATE innerConnectState;

/**
 单例

 @return 返回一个实例
 */
+ (XDBLE *)shareInstance;

/**
 扫描设备

 @param serviceUUID 过滤的UUID
 @param delayTime 扫描几秒停止
 @param bleState 蓝牙状态
 @param scanRealDevice 实时扫描的设备
 @param devices 扫描到的设备
 */
- (void)scanBleDeviceWithFilter:(NSString *)serviceUUID
                      delayTime:(NSInteger)delayTime
                       bleState:(BleState)bleState
                     scanDevice:(RealDevice)scanRealDevice
                scanDeviceNames:(DeviceNames)devices;

/**
 根据名字连接设备

 @param deviceName 设备名字
 */
- (void)connectDeviceWithName:(NSString *)deviceName connectState:(ConnectState)connectState;

/**
 取消连接，手动取消再次扫描有5-8s硬件不广播
 */
- (void)cancleConnectDevice;


/**
 发送数据

 @param data 需要发送的数据
 @param notifyValue 读取的数据
 */
- (void)writeData:(NSData *)data notifyValue:(NotifyValue)notifyValue;

@end

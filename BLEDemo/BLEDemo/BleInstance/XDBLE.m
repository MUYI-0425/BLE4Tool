//
//  XDBLE.m
//  BLEDemo
//
//  Created by apple on 2018/6/21.
//  Copyright © 2018年 孙晓东. All rights reserved.
//

#import "XDBLE.h"
#import <CoreBluetooth/CoreBluetooth.h>

typedef NS_ENUM(NSInteger,SCAN_STATE) {
    FREE = 0,
    SCANING
};

@interface XDBLE()<CBCentralManagerDelegate,CBPeripheralDelegate>
/**
 中心设备
 */
@property (nonatomic,strong)CBCentralManager *centralManager;

/**
 XDBLE持有外设
 */
@property (nonatomic,strong)CBPeripheral *peripheral;
/**
 蓝牙状态
 */
@property (nonatomic,assign)XD_BLE_STATE innerBleState;

/**
 扫描到蓝牙名字集合回调
 */
@property (nonatomic,copy)DeviceNames innerDeviceNames;

/**
 扫描到的蓝牙名回调
 */
@property (nonatomic,copy)RealDevice realDeviceSingleDevice;


/**
 蓝牙名和设备的集合
 */
@property (nonatomic,strong)NSMutableDictionary *devicesNameDIC;
/**
 扫描状态
 */
@property (nonatomic,assign)SCAN_STATE scanState;

@property (nonatomic,copy)ConnectState connectState;
/**
 是否需要停止扫描
 */
@property (nonatomic,assign)BOOL isScan;


/**
 写特征
 */
@property (nonatomic,strong)CBCharacteristic *writeC;


/**
 读到的特征值
 */
@property (nonatomic,copy)NotifyValue readValue;

@end
@implementation XDBLE

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBManagerStatePoweredOn:
            self.innerBleState = XD_BLE_OPEN;
            break;
        default:
            self.innerBleState = XD_BLE_CLOSE;
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSString *deviceName = advertisementData[@"kCBAdvDataLocalName"];
    
    if (deviceName) {
        
        NSArray *deviceNames = self.devicesNameDIC.allKeys;
        
        if (![deviceNames containsObject:deviceName]) {
            
            [self.devicesNameDIC setObject:peripheral forKey:deviceName];
            
            if (self.realDeviceSingleDevice) {
                
                self.realDeviceSingleDevice(deviceName, &_isScan);
            
                if (_isScan == YES) {
                    
                    [NSObject cancelPreviousPerformRequestsWithTarget:self];
                    
                    [self afterDelayTimeAction];
                    
                }
            }
            
        }
    }
    
}
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    self.innerConnectState = CONNECT_SUCCESS;
    self.peripheral.delegate = self;
    [self.peripheral discoverServices:nil];
}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    self.innerConnectState = CONNECT_FAILED;
    
}
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    self.innerConnectState = DIS_CONNECT;
    
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:SERVICE]]) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    for (CBCharacteristic *character in service.characteristics) {
        
        if ([character.UUID isEqual:[CBUUID UUIDWithString:READCHARACTER]]) {
            
            [peripheral setNotifyValue:YES forCharacteristic:character];
            
        }
        
        if ([character.UUID isEqual:[CBUUID UUIDWithString:WRITECHARACTER]]) {

            self.writeC = character;
            
        }
        
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    NSLog(@"==>%@",characteristic.value);
    
    if (self.readValue) {
        self.readValue(characteristic.value);
    }
    
}

#pragma mark - XX
+ (XDBLE *)shareInstance {
    static XDBLE *xdBle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        xdBle = [[XDBLE alloc] init];
    });
    return xdBle;
}

- (instancetype)init {
    if (self = [super init]) {
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue() options:@{CBCentralManagerOptionShowPowerAlertKey:@NO}];
        self.devicesNameDIC = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    return self;
}

/**
 扫描设备
 
 @param serviceUUID 过滤的UUID
 @param delayTime 扫描几秒停止
 @param bleState 蓝牙状态
 @param devices 扫描到的设备
 */
- (void)scanBleDeviceWithFilter:(NSString *)serviceUUID
                      delayTime:(NSInteger)delayTime
                       bleState:(BleState)bleState
                     scanDevice:(RealDevice)scanRealDevice
                scanDeviceNames:(DeviceNames)devices {
    if (self.innerBleState == XD_BLE_CLOSE) {
        bleState(XD_BLE_CLOSE);
        return;
    }
    
    [self.devicesNameDIC removeAllObjects];
    
    self.isScan = NO;
    
    self.realDeviceSingleDevice = scanRealDevice;
    
    self.innerDeviceNames = devices;
    
    NSMutableArray *services = nil;
    if (serviceUUID) {
        CBUUID *uuid = [CBUUID UUIDWithString:serviceUUID];
        services = [NSMutableArray arrayWithObject:uuid];
    }
    
    [self.centralManager scanForPeripheralsWithServices:services options:nil];
    
    self.scanState = SCANING;
    
    [self performSelector:@selector(afterDelayTimeAction) withObject:nil afterDelay:delayTime];
    
}

/**
 时间结束后的回调
 */
- (void)afterDelayTimeAction {
    [self.centralManager stopScan];
    self.scanState = FREE;
    if (self.innerDeviceNames) {
        self.innerDeviceNames(self.devicesNameDIC.allKeys);
    }
}


/**
 根据名字连接设备
 
 @param deviceName 设备名字
 */
- (void)connectDeviceWithName:(NSString *)deviceName connectState:(ConnectState)connectState; {
    CBPeripheral *peripheral = [self.devicesNameDIC objectForKey:deviceName];
    if (!peripheral) {
        connectState(UNKNOWN_DEVICE);
        return;
    }
    self.peripheral = peripheral;
    [self.centralManager connectPeripheral:peripheral options:nil];
}

/**
 取消连接，手动取消再次扫描有5-8s硬件不广播
 */
- (void)cancleConnectDevice {
    [self.centralManager cancelPeripheralConnection:self.peripheral];
}

- (void)writeData:(NSData *)data notifyValue:(NotifyValue)notifyValue {
    self.readValue = notifyValue;
    [self.peripheral writeValue:data forCharacteristic:self.writeC type:CBCharacteristicWriteWithoutResponse];
}

- (void)setInnerConnectState:(CONNECT_STATE)innerConnectState {
    _innerConnectState = innerConnectState;
    if (self.connectState) {
        self.connectState(_innerConnectState);
    }
}

@end

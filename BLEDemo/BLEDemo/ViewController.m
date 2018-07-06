//
//  ViewController.m
//  BLEDemo
//
//  Created by apple on 2018/6/21.
//  Copyright © 2018年 SXD. All rights reserved.
//

#import "ViewController.h"
#import "XDBLE.h"
@interface ViewController ()
@property (nonatomic,strong)XDBLE *xdBle;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.xdBle = [XDBLE shareInstance];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    __weak typeof(self) ws = self;
    [self.xdBle scanBleDeviceWithFilter:nil delayTime:5 bleState:^(XD_BLE_STATE xd_ble_state) {
        if(xd_ble_state == XD_BLE_OPEN) {
            NSLog(@"BLE_OPEN");
        }else {
            NSLog(@"BLE_CLOSE");
        }
    } scanDevice:^(NSString *deviceName, BOOL *stop) {
        //deviceName实时扫描到的蓝牙名，stop是否停止扫描
        if ([deviceName isEqualToString:@"000091"]) {
            *stop = YES;
            [ws.xdBle.service(@"FFE1").notifyCharacter(@"FFE2").writeCharacter(@"FFE3") connectDeviceWithName:deviceName connectState:^(CONNECT_STATE connectState) {
                if(connectState == CONNECT_SUCCESS) {
                    //发送数据
                    [ws.xdBle writeData:[ws convertHexStrToData:@"1234567890"] notifyValue:^(NSData *value) {
                        NSLog(@"读取到的数据:%@",value);
                    }];
                }
            }];
        }
    } scanDeviceNames:^(NSArray *devices) {
        //扫描结束所有的蓝牙设备
        NSLog(@"%@",devices);
        if (![devices containsObject:@"000091"]) {
            NSLog(@"未找到相应的设备");
        }
    }];
}

/**
 字符串转16进制

 @param str 需要转化的字符串
 @return 16进制数据
 */
- (NSData *)convertHexStrToData:(NSString *)str {
    if (!str || [str length] == 0) {
        return nil;
    }
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
    NSRange range;
    if ([str length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [str substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    return hexData;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

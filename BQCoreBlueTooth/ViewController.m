//
//  ViewController.m
//  BQCoreBlueTooth
//
//  Created by huangbq on 2017/3/27.
//  Copyright © 2017年 huangbq. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define BQXiaoMiSHUUID @"987CECFC-78F4-4BD3-A45D-8FD15052313C"

/**
 蓝牙通信 - 手机端作为中心设备
 
 1.创建CBCentralManager
 */

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;

@property (nonatomic, strong) CBPeripheral *discoveredPeripheral;

@property (nonatomic, strong) CBCharacteristic *characteristic;

@property (nonatomic, strong) UITextField *inputView;

@property (nonatomic, strong) UIButton *sendButton;

@property (nonatomic, strong) UITextView *textView;
@end

@implementation ViewController


#pragma mark - CBCentralManagerDelegate

/**
 检测中心设备状态

 @param central 中心设备
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBManagerStatePoweredOn) {
        [self LogWithString:@"蓝牙已关闭"];
    }
    else {
        [self LogWithString:@"开始扫描外围设备..."];
//        CBUUID *serviceUUID = [CBUUID UUIDWithString:BQXiaoMiSHUUID];
        [self.centralManager scanForPeripheralsWithServices:@[] options:nil];
    }
        
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"peripheral:%@", peripheral);
    if (!peripheral || !peripheral.name || [peripheral.name isEqualToString:@""]) {
        return;
    }
    
    if (!self.discoveredPeripheral || self.discoveredPeripheral.state == CBPeripheralStateDisconnected) {
        
        self.discoveredPeripheral = peripheral;
        self.discoveredPeripheral.delegate = self;
        [self LogWithString:@"连接外围设备..."];
        // 连接外围设备
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    if (!peripheral) {
        return;
    }
    // 停止扫描
    [self.centralManager stopScan];
    
    [self LogWithString:[NSString stringWithFormat:@"连接到外围设备 %@ ...", peripheral.name]];
    
    // 查找服务
    [self.discoveredPeripheral discoverServices:nil];
    
    
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (peripheral != self.discoveredPeripheral) {
        [self LogWithString:@"外围设备不对..."];
        return;
    }
    
    
    if (error) {
        [self LogWithString:[NSString stringWithFormat:@"错误：%@",error.description]];
        
        return;
    }
    
    NSArray *services = [self.discoveredPeripheral services];
    for (CBService *service in services) {
        [self LogWithString:[NSString stringWithFormat:@"查找到服务: %@",service.UUID]];
        
        // 查找每项服务的特征
        [self.discoveredPeripheral discoverCharacteristics:nil forService:service];
        
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (peripheral != self.discoveredPeripheral) {
        [self LogWithString:@"外围设备不对..."];
        return;
    }
    
    
    if (error) {
        [self LogWithString:[NSString stringWithFormat:@"错误：%@",error.description]];
        
        return;
    }
    
    self.characteristic = service.characteristics.firstObject;
    [self.discoveredPeripheral setNotifyValue:YES forCharacteristic:self.characteristic];
//    NSArray *characteristics = service.characteristics;
//    for (CBCharacteristic *characteristic in characteristics) {
//        [self LogWithString:[NSString stringWithFormat:@"查找到特征： %@", characteristic.UUID]];
//        
//        // 订阅特征
//        [self.discoveredPeripheral setNotifyValue:YES forCharacteristic:characteristic];
//        
//    }
}

// 订阅的特征有数据更新
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSData *data = characteristic.value;
    
    NSString *info = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self LogWithString:info];
}

#pragma mark - 懒加载

- (UIView *)inputView {
    if (_inputView == nil) {
        
        _inputView = [[UITextField alloc] initWithFrame:CGRectMake(10, 20, 200, 44)];
    }
    return _inputView;
}


- (UIButton *)sendButton {
    if (_sendButton == nil) {
        _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        _sendButton.frame = CGRectMake(screenSize.width - 10 -  44, 20, 44, 44);
        [_sendButton setTitle:@"发送" forState:UIControlStateNormal];
        [_sendButton addTarget:self action:@selector(sendData) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendButton;
}
-(UITextView *)textView
{
    if (_textView == nil) {
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        _textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 30, screenSize.width - 20, screenSize.height - 40)];
        
    }
    
    return _textView;
}

#pragma mark 私有方法

- (void) sendData {
    if ([self.inputView.text isEqualToString:@""]) {
        return;
    }
    NSData *data = [self.inputView.text dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.discoveredPeripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
}

- (void)LogWithString:(NSString *)log {
    NSLog(@"%@", log);
    self.textView.text = [NSString stringWithFormat:@"%@\r\n%@", self.textView.text, log];
    
}

#pragma mark - view 周期
- (void)viewDidLoad {
    [super viewDidLoad];
    
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    [self.view addSubview:self.inputView];
    [self.view addSubview:self.sendButton];
    [self.view addSubview:self.textView];
}




@end

//
//  HRMovementDataViewController.m
//  JWBleDemo
//
//  Created by wo-smart on 2025/2/18.
//  Copyright © 2025 wosmart. All rights reserved.
//

#import "HRMovementDataViewController.h"

@interface HRMovementDataViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic, strong) UITableView* LogTableView;

@property(nonatomic, strong) NSMutableArray* LogArr;
@property(nonatomic, strong) NSLock* LogLock;

@end

@implementation HRMovementDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self initTestUI];
    
}


-(UITableView *)LogTableView{
    if (!_LogTableView)
    {
        _LogTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _LogTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _LogTableView.delegate = self;
        _LogTableView.dataSource = self;
        _LogTableView.estimatedRowHeight = 70;
        _LogTableView.backgroundColor = [UIColor.grayColor colorWithAlphaComponent:0.4];
    }
    return _LogTableView;
}

-(NSMutableArray *)LogArr{
    if (!_LogArr)
    {
        _LogArr = [NSMutableArray array];
    }
    return _LogArr;
}

-(NSLock *)LogLock{
    if (!_LogLock)
    {
        _LogLock = [[NSLock alloc] init];
    }
    return _LogLock;
}

-(void)SaveLog:(NSString*)logStr{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.LogLock lock];
        [self.LogArr addObject:logStr];
        [self.LogLock unlock];
        [self.LogTableView reloadData];
    });
}

-(void)ClearAllLog{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.LogLock lock];
        [self.LogArr removeAllObjects];
        [self.LogLock unlock];
        [self.LogTableView reloadData];
    });
}

/// Step 1
/// 开启心率自动监测 Turn on automatic heart rate monitoring
-(void)setHrAutomaticDetectionAction{
    ///此处设定心率自动监测时间间隔为5分钟  Here, the heart rate automatic monitoring interval is set to 5 minutes
    [JWBleAction jwHrAutomaticDetectionAction:false open:true timeSpan:5 callBack:^(JWBleCommunicationStatus status, BOOL open, int timeSpan) {
            
    }];
}

/// Step 2
/// 经过一定周期后获取设备数据 Get device data after a certain period
- (void)hrMovementAction {
    JWBleManager.showLog = false;
    //1：Sync Data
    [JWBleDataAction jwSyncDataWithCallBack:^(JWBleCommunicationStatus status, JWBleSyncStateEnum syncStateEnum) {
        
    }];
    
    //2: listen callback
    __block int receiveCount = 0;
    JWBleManager.hrMovementDataCallBack= ^(int time, int hr, int tem, int label, int move) {
            receiveCount ++;
        NSLog(@"pull data receiving \t time:%d \t hr:%d \t tem:%d \t label:%d \t move:%d \t receiveCount:%d",time,hr,tem,label,move,receiveCount);
        NSDate* nowDate = [NSDate dateWithTimeIntervalSince1970:time];
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        NSString* logStr = [NSString stringWithFormat:@"time:%@ \n hr:%d \t tem:%d \t label:%d \n move:%d \t receiveCount:%d", [formatter stringFromDate:nowDate],hr,tem,label,move,receiveCount];
        [self SaveLog:logStr];
    };
}

/// other function
/// load SQLLite Data
-(void)LoadSQLData{
    NSDate* nowDate = [NSDate date];
    long oldTime =  (long)[nowDate timeIntervalSince1970]-24*60*60;
                          //2023-05-19 17:51:00  2023-05-21 16:17:53
    __weak typeof(self) weakSelf = self;
    [JWBleDataAction jwGetHrMovementDataByStartT:oldTime endT:[nowDate timeIntervalSince1970] callBack:^(NSArray *dataArr) {
        NSLog(@"db data length : %ld", dataArr.count);
        [weakSelf readDataForList:dataArr];
    }];
}

-(void)readDataForList:(NSArray*)dataArr{
//    @"time":@(model.time),
//    @"hr":@(model.hr),
//    @"tem":@(model.tem),
//    @"label":@(model.label),
//    @"move":@(model.move)
    NSInteger receiveCount = 0;
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    formatter.timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    for (NSDictionary* dataDic in dataArr)
    {
        NSInteger time = [[dataDic objectForKey:@"time"] integerValue];
        NSInteger hr = [[dataDic objectForKey:@"hr"] integerValue];
        NSInteger tem = [[dataDic objectForKey:@"tem"] integerValue];
        NSInteger label = [[dataDic objectForKey:@"label"] integerValue];
        NSInteger move = [[dataDic objectForKey:@"move"] integerValue];

        NSDate* nowDate = [NSDate dateWithTimeIntervalSince1970:time];
        
        receiveCount ++;
        NSString* logStr = [NSString stringWithFormat:@"time:%@ \n hr:%zd \t tem:%zd \t label:%zd \n move:%zd \t receiveCount:%zd", [formatter stringFromDate:nowDate],hr,tem,label,move,receiveCount];
        [self SaveLog:logStr];
    }
}



-(void)initTestUI{
    self.view.backgroundColor = UIColor.whiteColor;
    
    UIButton *testButton = [UIButton buttonWithType:UIButtonTypeCustom];
    testButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [testButton setTitle:@"开启心率监测（默认5分钟）" forState:UIControlStateNormal];
    [testButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [testButton setBackgroundColor:UIColor.systemBlueColor];
    [testButton sizeToFit];
    [testButton setTranslatesAutoresizingMaskIntoConstraints:NO]; // 禁用AutoresizingMask
    [testButton addTarget:self action:@selector(setHrAutomaticDetectionAction) forControlEvents:UIControlEventTouchUpInside];
    testButton.titleEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10); // 上、左、下、右内间距

    [self.view addSubview:testButton];

    // 使用NSLayoutAnchor来设置约束
    [testButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [testButton.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:100].active = YES;
    [testButton.widthAnchor constraintGreaterThanOrEqualToConstant:200].active = YES;
    
    
    UIButton *testErrorButton = [UIButton buttonWithType:UIButtonTypeCustom];
    testErrorButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [testErrorButton setTitle:@"获取心率体动监测数据" forState:UIControlStateNormal];
    [testErrorButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [testErrorButton setBackgroundColor:UIColor.systemBlueColor];
    [testErrorButton sizeToFit];
    [testErrorButton setTranslatesAutoresizingMaskIntoConstraints:NO]; // 禁用AutoresizingMask
    [testErrorButton addTarget:self action:@selector(hrMovementAction) forControlEvents:UIControlEventTouchUpInside];
    testErrorButton.titleEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10); // 上、左、下、右内间距

    [self.view addSubview:testErrorButton];

    // 使用NSLayoutAnchor来设置约束
    [testErrorButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [testErrorButton.topAnchor constraintEqualToAnchor:testButton.bottomAnchor constant:10].active = YES;
    [testErrorButton.widthAnchor constraintGreaterThanOrEqualToConstant:200].active = YES;
    
    UIButton *reloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    reloadButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [reloadButton setTitle:@"获取本地缓存数据" forState:UIControlStateNormal];
    [reloadButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [reloadButton setBackgroundColor:UIColor.systemBlueColor];
    [reloadButton sizeToFit];
    [reloadButton setTranslatesAutoresizingMaskIntoConstraints:NO]; // 禁用AutoresizingMask
    [reloadButton addTarget:self action:@selector(LoadSQLData) forControlEvents:UIControlEventTouchUpInside];
    reloadButton.titleEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10); // 上、左、下、右内间距

    [self.view addSubview:reloadButton];

    // 使用NSLayoutAnchor来设置约束
    [reloadButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [reloadButton.topAnchor constraintEqualToAnchor:testErrorButton.bottomAnchor constant:10].active = YES;
    [reloadButton.widthAnchor constraintGreaterThanOrEqualToConstant:200].active = YES;


    [self.LogTableView setTranslatesAutoresizingMaskIntoConstraints:NO]; // 禁用AutoresizingMask
    [self.view addSubview:self.LogTableView];

    // 使用NSLayoutAnchor来设置约束
    [self.LogTableView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [self.LogTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:30].active = YES;
    [self.LogTableView.topAnchor constraintEqualToAnchor:reloadButton.bottomAnchor constant:10].active = YES;
    [self.LogTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-100].active = YES;

    
    
    UIButton *delButton = [UIButton buttonWithType:UIButtonTypeCustom];
    delButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [delButton setTitle:@"清空日志" forState:UIControlStateNormal];
    [delButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [delButton setBackgroundColor:UIColor.systemBlueColor];
    [delButton sizeToFit];
    [delButton setTranslatesAutoresizingMaskIntoConstraints:NO]; // 禁用AutoresizingMask
    [delButton addTarget:self action:@selector(ClearAllLog) forControlEvents:UIControlEventTouchUpInside];
    delButton.titleEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10); // 上、左、下、右内间距

    [self.view addSubview:delButton];

    // 使用NSLayoutAnchor来设置约束
    [delButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [delButton.topAnchor constraintEqualToAnchor:self.LogTableView.bottomAnchor constant:10].active = YES;
    [delButton.widthAnchor constraintGreaterThanOrEqualToConstant:70].active = YES;
    
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.LogArr.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewAutomaticDimension;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cells"];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cells"];
    }
    cell.textLabel.text = [self.LogArr objectAtIndex:indexPath.row];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [UIFont systemFontOfSize:13];
    return cell;
}


-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return [[UIView alloc] init];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return [[UIView alloc] init];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

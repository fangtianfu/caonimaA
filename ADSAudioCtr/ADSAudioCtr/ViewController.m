//
//  ViewController.m
//  ADSAudioCtr
//
//  Created by ADSmart Tech on 15/10/29.
//  Copyright © 2015年 ADSmart Tech. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()
{
  
}
@end

@implementation ViewController
@synthesize MyBtn,MyAudioClass;

-(void)ClickBtn:(UIButton *) sender
{
    if (!(MyAudioClass))
    {
        MyAudioClass = [[ADSAudioClass alloc] init];
    }
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    UIButton *mybTn = [[UIButton alloc]initWithFrame:CGRectMake(0, 100, 200, 200)];
   // mybTn = [UIButton buttonWithType:UIButtonTypeContactAdd];
    self.view.backgroundColor = [UIColor whiteColor];
    mybTn.backgroundColor = [UIColor blackColor];
    [mybTn addTarget:self action:@selector(ClickBtn:) forControlEvents:UIControlEventTouchUpInside];
    MyBtn = mybTn;
    [self.view addSubview:MyBtn];
    self.view.backgroundColor = [UIColor clearColor];
    mybTn.backgroundColor = [UIColor blackColor];
    
    
//    
//    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
//                                                                               target:self action:@selector(clickAddButton:)];
    self.title = NSLocalizedStringFromTable(@"DeviceList",@"InfoPlist",nil);
    //self.navigationItem.leftBarButtonItem = addButton;
    self.view.bounds = [[UIScreen mainScreen] bounds];

    
    NSLog(@"sdrrrr %@",MyBtn);
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

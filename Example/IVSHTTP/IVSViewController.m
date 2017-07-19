//
//  IVSViewController.m
//  IVSHTTP
//
//  Created by netcanis on 07/19/2017.
//  Copyright (c) 2017 netcanis. All rights reserved.
//

#import "IVSViewController.h"
#import <IVSHTTP.h>

// Missing submodule 'IVSHTTP.IVSHTTP
@interface IVSViewController ()

@end

@implementation IVSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onSend:(id)sender
{
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"VtT0curfvpEhkBfgCy3Xlmg9BEU7hmO5UYio3ECCUlm-T71BAjOaMVyDHgf7nmTpgXzvSsE4tRUCERUORDqbiwziHkTDd30Ym5_BxDlH2jW0nuo2oDemN9CCS2h10ox_1xSncGQajx_ryfhECjZEnJ9GRkcRevgjTvo8Dc32iw_BLJPcPfRdVKhJT5HNzQuXEeN3QFwl2n0M6ZmO-h7C6eIqWsDnSrEd", @"user_content_key",
                                @"MwxUjRcLr2qLlnVOLh12wSNkqcO1Ikdrk", @"lib", nil];
    
    [IVSHTTP asyncSend:@"GET"
                   url:@"https://script.googleusercontent.com/macros/echo"
            parameters:parameters
               success:^(NSData *data) {
                   NSLog(@"\n--------------------------------\nasyncSend\n%@\n", [IVSHTTP data2Json:data]);
                   
                   NSMutableDictionary *dic = [IVSHTTP data2Cont:data];
                   NSString *dayofweekName = [dic objectForKey:@"dayofweekName"];
                   NSLog(@"%@", dayofweekName);
               }
               failure:^(NSError *error) {
                   NSLog(@"%@", error.description);
               }];
    
    
    
    NSData *data = [IVSHTTP syncSend:@"GET"
                                 url:@"https://app.dcgworld.com/api/version"
                          parameters:parameters];
    NSLog(@"\n--------------------------------\nsyncSend\n%@\n", [IVSHTTP data2Json:data]);
}

- (IBAction)onDownload:(id)sender
{
    [IVSHTTP asyncDownload:@"https://www.gstatic.com/webp/gallery3/1.sm.png"
                   success:^(NSData *data, NSDictionary* info) {
                       NSString *fileName = [info objectForKey:@"fileName"];
                       NSString *filePath = [info objectForKey:@"filePath"];
                       NSLog(@"\n--------------------------------\nasyncDownload\nfileName:\n%@\nfilePath:\n%@\n", fileName, filePath);
                       NSLog(@"");
                   }
                   failure:^(NSError *error) {
                       NSLog(@"%@", error.description);
                   }];
    
    
    
    NSDictionary *info = nil;
    [IVSHTTP syncDownload:@"https://www.gstatic.com/webp/gallery3/1.sm.png"
                                    info:&info];
    NSString *fileName = [info objectForKey:@"fileName"];
    NSString *filePath = [info objectForKey:@"filePath"];
    NSLog(@"\n--------------------------------\nsyncDownload\nfileName:\n%@\nfilePath:\n%@\n", fileName, filePath);
}

- (IBAction)onUpload:(id)sender
{
    /*
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"IVSHTTP", @"appId",
                                @"I", @"mobile_os",
                                @"EN", @"lang", nil];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    
    NSString *dateString1 = [dateFormatter stringFromDate:[NSDate date]];
    NSString *dateString2 = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *imageName1 = [NSString stringWithFormat:@"%@.jpg", dateString1];
    NSString *imageName2 = [NSString stringWithFormat:@"%@.jpg", dateString2];
    
    UIImage *image1 = [UIImage imageNamed:@"test1.png"];
    UIImage *image2 = [UIImage imageNamed:@"test2.png"];
    
    NSMutableDictionary *dataDic = [[NSMutableDictionary alloc] init];
    [dataDic setObject:image1 forKey:imageName1];
    [dataDic setObject:image2 forKey:imageName2];
    
    
    [IVSHTTP asyncUpload:@"https://api.MYDOMAIN.com/upload"
            inputTagName:@"uploadFile"
                  parameters:parameters
                   dataArray:dataDic
                     success:^(NSData *data) {
                         NSDictionary *dict = [IVSHTTP data2Cont:data];
                         NSLog(@"%@", dict);
                     } failure:^(NSError *error) {
                         NSLog(@"%@", error.description);
                     }];
     
    
    
    
   NSData *data = [IVSHTTP syncUpload:@"https://api.MYDOMAIN.com/upload"
                         inputTagName:@"uploadFile"
                           parameters:parameters
                            dataArray:dataDic];
    */
}


@end






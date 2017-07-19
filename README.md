# IVSHTTP

[![CI Status](http://img.shields.io/travis/netcanis/IVSHTTP.svg?style=flat)](https://travis-ci.org/netcanis/IVSHTTP)
[![Version](https://img.shields.io/cocoapods/v/IVSHTTP.svg?style=flat)](http://cocoapods.org/pods/IVSHTTP)
[![License](https://img.shields.io/cocoapods/l/IVSHTTP.svg?style=flat)](http://cocoapods.org/pods/IVSHTTP)
[![Platform](https://img.shields.io/cocoapods/p/IVSHTTP.svg?style=flat)](http://cocoapods.org/pods/IVSHTTP)


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.


### asyncSend
```objc
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
           }
           failure:^(NSError *error) {
                NSLog(@"%@", error.description);
           }];
```


### syncSend
```objc
NSData *data = [IVSHTTP syncSend:@"GET"
                             url:@"https://app.dcgworld.com/api/version"
                      parameters:parameters];
```


### asyncDownload
```objc
[IVSHTTP asyncDownload:@"https://www.gstatic.com/webp/gallery3/1.sm.png"
               success:^(NSData *data, NSDictionary* info) {
                   NSString *fileName = [info objectForKey:@"fileName"];
                   NSString *filePath = [info objectForKey:@"filePath"];
                   NSLog(@"\nasyncDownload\nfileName:\n%@\nfilePath:\n%@\n", fileName, filePath);
                   NSLog(@"");
               }
               failure:^(NSError *error) {
                   NSLog(@"%@", error.description);
               }];
```


### syncDownload
```objc
NSDictionary *info = nil;
NSData *data = [IVSHTTP syncDownload:@"https://www.gstatic.com/webp/gallery3/1.sm.png" info:&info];
NSString *fileName = [info objectForKey:@"fileName"];
NSString *filePath = [info objectForKey:@"filePath"];
```


### asyncUpload
```objc
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
```



## Requirements
- Base SDK: iOS 10
- Deployment Target: iOS 9.0 or greater
- Xcode 8.x


## Installation

IVSHTTP is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "IVSHTTP"
```

## Author

netcanis, netcanis@gmail.com

## License

IVSHTTP is available under the MIT license. See the LICENSE file for more info.

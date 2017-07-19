//
//  IVSHTTP.m
//  Pods
//
//  Created by netcanis on 19/07/2017.
//
//

#import "IVSHTTP.h"
#import <WebKit/WebKit.h>
#import "KeychainItemWrapper.h"


@implementation IVSHTTP


#pragma mark -
#pragma mark - HTTP Request and Responses (POST, GET, PUT, PATCH, DELETE)

+ (void)asyncSend:(NSString *)method
              url:(NSString *)url
       parameters:(NSDictionary *)parameters
          success:(void (^)(NSData *data))success
          failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setTimeoutInterval:10.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [request setHTTPMethod:method];
    
    if (nil != parameters) {
        if ([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"] || [method isEqualToString:@"PATCH"]) {
            [request setURL:[NSURL URLWithString:url]];
            NSError *error;
            NSData *postData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error];
            [request setHTTPBody:postData];
        } else {
            [request setURL:[IVSHTTP makeURL:url parameters:parameters]];
        }
    }
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                         if (nil != error) {
                                             NSLog(@"Error (%zd) : %@", [error code], [error userInfo]);
                                             failure(error);
                                         } else {
                                             success(data);
                                         }
                                     }] resume];
}

+ (NSData *)syncSend:(NSString *)method
                 url:(NSString *)url
          parameters:(NSDictionary *)parameters
{
    __block NSData *result = nil;
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    [IVSHTTP asyncSend:method
                       url:url
                parameters:parameters
                   success:^(NSData *data) {
                       result = data;
                       dispatch_semaphore_signal(sem);
                   }
                   failure:^(NSError *error) {
                       NSLog(@"%@", error.description);
                       dispatch_semaphore_signal(sem);
                   }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return result;
}


#pragma mark -
#pragma mark - Download

+ (void)asyncDownload:(NSString *)url
              success:(void (^)(NSData *data, NSDictionary* info))success
              failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setTimeoutInterval:10.0];
 
    [[[NSURLSession sharedSession] downloadTaskWithRequest:request
                                         completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                             if (nil != error) {
                                                 failure(error);
                                             } else {
                                                 NSString *fileName = [response suggestedFilename];
                                                 NSString *filePath = [IVSHTTP docPath:fileName];
                                                 NSURL *fileURL = [NSURL fileURLWithPath:filePath];
                                                 
                                                 NSError *err = nil;
                                                 [[NSFileManager defaultManager] moveItemAtURL:location
                                                                                         toURL:fileURL
                                                                                         error:&err];
                                                 if (nil != error) {
                                                     failure(err);
                                                     NSLog(@"failed to move: %@", [err userInfo]);
                                                 } else {
                                                     NSData *data = [[NSFileManager defaultManager] contentsAtPath:filePath];
                                                     NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
                                                     [info setObject:fileName forKey:@"fileName"];
                                                     [info setObject:filePath forKey:@"filePath"];
                                                     success(data, info);
                                                     //NSLog(@"File is saved to =%@", fileURL.absoluteString);
                                                 }
                                             }
                                         }] resume];

}

+ (NSData *)syncDownload:(NSString *)url
                    info:(NSDictionary **)ppInfo
{
    __block NSData *result = nil;
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    [IVSHTTP asyncDownload:url
                   success:^(NSData *data, NSDictionary* info) {
                       result = data;
                       if (nil != ppInfo) {
                           *ppInfo = info;
                       }
                       dispatch_semaphore_signal(sem);
                   }
                   failure:^(NSError *error) {
                       NSLog(@"%@", error.description);
                       dispatch_semaphore_signal(sem);
                   }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return result;
}


#pragma mark -
#pragma mark - Upload

+ (void)asyncUpload:(NSString *)url
       inputTagName:(NSString *)inputTagName
         parameters:(NSDictionary *)parameters
          dataArray:(NSDictionary *)dataArray
            success:(void (^)(NSData *data))success
            failure:(void (^)(NSError *error))failure
{
    if (nil == inputTagName || YES == [inputTagName isEqualToString:@""]) {
        NSAssert(0, @"Error : inputTagName is nil or empty.");
        return;
    }
    
    NSMutableURLRequest *request= [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]] ;
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = [IVSHTTP generateBoundaryString];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *postbody = [NSMutableData data];
    NSString *postData = [self httpBodyParamsByDic:parameters boundary:boundary];
    [postbody appendData:[postData dataUsingEncoding:NSUTF8StringEncoding]];
    
    [dataArray enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if(obj != nil) {
            [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filetype=\"image/jpg\"; filename=\"%@\"\r\n", inputTagName, key] dataUsingEncoding:NSUTF8StringEncoding]];
            [postbody appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [postbody appendData:UIImageJPEGRepresentation(obj, 1.0)];// [NSData dataWithData:obj]];
        }
    }];
    
    [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:postbody];
    
    
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                         if (nil != error) {
                                             NSLog(@"Error (%zd) : %@", [error code], [error userInfo]);
                                             failure(error);
                                         } else {
                                             success(data);
                                         }
                                     }] resume];
}

+ (NSData *)syncUpload:(NSString *)url
          inputTagName:(NSString *)inputTagName
            parameters:(NSDictionary *)parameters
             dataArray:(NSDictionary *)dataArray
{
    __block NSData *result = nil;
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    [IVSHTTP asyncUpload:url
            inputTagName:inputTagName
                  parameters:parameters
                   dataArray:dataArray
                     success:^(NSData *data) {
                         result = data;
                         dispatch_semaphore_signal(sem);
                     } failure:^(NSError *error) {
                         NSLog(@"%@", error.description);
                         dispatch_semaphore_signal(sem);
                     }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return result;
}


#pragma mark -
#pragma mark - Util

+ (NSString *)appName
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
}

+ (NSString*)deviceModel
{
    return [[UIDevice currentDevice] model];
}

+ (NSString*)bundleId
{
    return [[NSBundle mainBundle] bundleIdentifier];
}

+ (float)iosVersion
{
    return [[[UIDevice currentDevice] systemVersion] floatValue];
}

+ (NSString *)appVersion
{
    return (NSString *)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

+ (NSString *)appBuildCount
{
    return (NSString *)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

+ (NSString *)docDir
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

+ (NSString *)docPath:(NSString *)fileName
{
    return [[IVSHTTP docDir] stringByAppendingPathComponent:fileName];
}

+ (NSString *)generateBoundaryString
{
    return [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
}

+ (NSString *)httpBodyParamsByDic:(NSDictionary *)parameters boundary:(NSString *)boundary
{
    NSMutableString *tempVal = [[NSMutableString alloc] init];
    for(NSString *key in parameters) {
        [tempVal appendFormat:@"\r\n--%@\r\n", boundary];
        [tempVal appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@",key,[parameters objectForKey:key]];
    }
    return [tempVal description];
}

+ (NSURL*)makeURL:(NSString *)url parameters:(NSDictionary *)parameters
{
    NSURLComponents *components = [NSURLComponents componentsWithString:url];
    NSMutableArray *queryItems = [NSMutableArray array];
    for (NSString *key in parameters){
        [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:parameters[key]]];
    }
    components.queryItems = queryItems;
    return components.URL;
}

+ (NSMutableDictionary *)parseURL:(NSURL *)url
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:false];
    for (NSURLQueryItem *item in urlComponents.queryItems){
        if (nil != item.value) {
            [dict setObject:item.value forKey:item.name];
        }
    }
    return dict;
}

+ (id)data2Cont:(NSData *)data
{
    return [NSJSONSerialization JSONObjectWithData:data
                                           options:NSJSONReadingMutableContainers
                                             error:nil];
}

+ (NSData *)cont2Data:(id)container
{
    return [NSJSONSerialization dataWithJSONObject:container
                                           options:0
                                             error:nil];
}

+ (NSString *)data2Json:(NSData *)data
{
    return [[NSString alloc] initWithData:data
                                 encoding:NSUTF8StringEncoding];
}

+ (NSData *)json2Data:(NSString *)json
{
    return [json dataUsingEncoding:NSUTF8StringEncoding];
}

+ (void)removeWebChche
{
    //
    // WKWebView
    //
    NSSet *websiteDataTypes = [NSSet setWithArray:@[
                                                    WKWebsiteDataTypeDiskCache,
                                                    //WKWebsiteDataTypeOfflineWebApplicationCache,
                                                    WKWebsiteDataTypeMemoryCache,
                                                    //WKWebsiteDataTypeLocalStorage,
                                                    //WKWebsiteDataTypeCookies,
                                                    //WKWebsiteDataTypeSessionStorage,
                                                    //WKWebsiteDataTypeIndexedDBDatabases,
                                                    //WKWebsiteDataTypeWebSQLDatabases
                                                    ]];
    // All kinds of data
    //NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
    
    // Date from
    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    // Execute
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
        // Done
    }];
    
    
    //
    // UIWebView
    //
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

+ (NSString *)cutPath:(NSString *)urlString
{
    NSRange range = [urlString rangeOfString:@"/" options:NSBackwardsSearch];
    if (NSNotFound != range.location) {
        return [urlString substringToIndex:range.location];
    }
    return urlString;
}

+ (NSString *)cutFilename:(NSString *)urlString
{
    return [[urlString lastPathComponent] stringByDeletingPathExtension];
}

+ (NSString *)cutFileExt:(NSString *)urlString
{
    return [[urlString lastPathComponent] pathExtension];
}

+ (NSString *)contentTypeForImageData:(NSData *)data
{
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
        case 0x89:
            return @"image/png";
        case 0x47:
            return @"image/gif";
        case 0x49:
        case 0x4D:
            return @"image/tiff";
    }
    return nil;
}

+ (BOOL)checkingURLExists:(NSString *)url
{
    __block BOOL result = YES;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                                         timeoutInterval:30.0f];
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                         if (nil != error) {
                                             NSLog(@"Error (%zd) : %@", [error code], [error userInfo]);
                                             result = NO;
                                         } else {
                                             NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
                                             if([resp statusCode] == 404) {
                                                 result = NO;
                                             } else {
                                                 result = YES;
                                             }
                                         }
                                         dispatch_semaphore_signal(sem);
                                     }] resume];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return result;
}

+ (void)shareData:(id)vc title:(NSString *)strTitle param:(NSMutableArray *)items
{
    @try {
        if (nil == vc) {
            vc = [[UIApplication sharedApplication] delegate].window.rootViewController;
        }
        
        [items insertObject:strTitle atIndex:0];
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
        [vc presentViewController:activityViewController animated:YES completion:nil];
    } @catch (NSException *e) {
        NSLog(@"exceptionName %@, reason %@", [e name], [e reason]);
    } @finally {
        NSLog(@"shareAction");
    }
}

+ (void)saveImagesToAlbum:(NSMutableArray *)images
{
    for (UIImage *image in images) {
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void*)image);
    }
}

+ (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (nil == image) {
        return;
    }
    
    NSString *imgUrl = (__bridge NSString *)(contextInfo);
    if (nil != error) {
        NSLog(@"failed download %@", imgUrl);
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), contextInfo);
    }
}

+ (BOOL)externalAppRequiredToOpenURL:(NSURL *)URL
{
    NSSet *validSchemes = [NSSet setWithArray:@[@"http", @"https"]];
    return ![validSchemes containsObject:URL.scheme];
}


+ (void)writeToFile:(NSString *)fullPath with:(NSData *)data
{
    NSString *path = [IVSHTTP cutPath:fullPath];
    if (NO == [[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *attr = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                         forKey:NSFileProtectionKey];
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:attr
                                                        error:&error];
        if (error) {
            NSLog(@"Error creating directory path: %@", [error localizedDescription]);
            return;
        }
    }
    
    [data writeToFile:fullPath atomically:NO];
}

+ (NSData *)readFromFile:(NSString *)path
{
    return [NSData dataWithContentsOfFile:path];
}

+ (NSString*)urlEncode:(NSString*)str
{
    return [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

+ (NSString*)urlDecode:(NSString*)str
{
    return [str stringByRemovingPercentEncoding];
}

+ (NSString*)utf8toNString:(NSString*)str
{
    NSString* strT= [str stringByReplacingOccurrencesOfString:@"\\U" withString:@"\\u"];
    CFStringRef transform = CFSTR("Any-Hex/Java");
    CFStringTransform((__bridge CFMutableStringRef)strT, NULL, transform, YES);
    return strT;
}

@end

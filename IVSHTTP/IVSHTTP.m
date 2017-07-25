//
//  IVSHTTP.m
//  Pods
//
//  Created by netcanis on 19/07/2017.
//
//

#import "IVSHTTP.h"
#import <WebKit/WebKit.h>


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

+ (NSURL *)makeURL:(NSString *)url parameters:(NSDictionary *)parameters
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

+ (NSString *)docPath:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    return [docDir stringByAppendingPathComponent:fileName];
}

+ (id)data2Cont:(NSData *)data
{
    return [NSJSONSerialization JSONObjectWithData:data
                                           options:NSJSONReadingMutableContainers
                                             error:nil];
}

+ (void)removeWebChche
{
    // WKWebView
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
    
    
    // UIWebView
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

+ (NSURL *)utf8URL:(NSString *)urlString
{
    NSCharacterSet *allowedCharacterSet = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSURL *URL = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet]];
    return URL;
}

+ (NSString *)utf8toNString:(NSString *)utf8String
{
    NSString* strT= [utf8String stringByReplacingOccurrencesOfString:@"\\U" withString:@"\\u"];
    CFStringRef transform = CFSTR("Any-Hex/Java");
    CFStringTransform((__bridge CFMutableStringRef)strT, NULL, transform, YES);
    return strT;
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

+ (NSString *)urlEncode:(NSString *)str
{
    return [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

+ (NSString *)urlDecode:(NSString *)str
{
    return [str stringByRemovingPercentEncoding];
}



@end

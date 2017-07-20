//
//  IVSHTTP.h
//  Pods
//
//  Created by netcanis on 19/07/2017.
//
//

#import <Foundation/Foundation.h>

@interface IVSHTTP : NSObject

// HTTP Request and Responses (POST, GET, PUT, PATCH, DELETE)
+ (void)asyncSend:(NSString *)method
              url:(NSString *)url
       parameters:(NSDictionary *)parameters
          success:(void (^)(NSData *data))success
          failure:(void (^)(NSError *error))failure;

+ (NSData *)syncSend:(NSString *)method
                 url:(NSString *)url
          parameters:(NSDictionary *)parameters;


// Download
+ (void)asyncDownload:(NSString *)url
              success:(void (^)(NSData *data, NSDictionary* info))success
              failure:(void (^)(NSError *error))failure;

+ (NSData *)syncDownload:(NSString *)url
                    info:(NSDictionary **)ppInfo;


// Upload
+ (void)asyncUpload:(NSString *)url
       inputTagName:(NSString *)inputTagName
         parameters:(NSDictionary *)parameters
          dataArray:(NSDictionary *)dataArray
            success:(void (^)(NSData *data))success
            failure:(void (^)(NSError *error))failure;

+ (NSData *)syncUpload:(NSString *)url
          inputTagName:(NSString *)inputTagName
            parameters:(NSDictionary *)parameters
             dataArray:(NSDictionary *)dataArray;


// Util
+ (NSString *)appName;
+ (NSString*)deviceModel;
+ (NSString*)bundleId;
+ (float)iosVersion;
+ (NSString *)appVersion;
+ (NSString *)appBuildCount;
+ (NSString*)appUniqueId;
+ (NSString *)docDir;
+ (NSString *)docPath:(NSString *)fileName;
+ (NSString *)generateBoundaryString;
+ (NSString *)httpBodyParamsByDic:(NSDictionary *)parameters boundary:(NSString *)boundary;
+ (NSURL*)makeURL:(NSString *)url parameters:(NSDictionary *)parameters;
+ (NSMutableDictionary *)parseURL:(NSURL *)url;
+ (id)data2Cont:(NSData *)data;
+ (NSData *)cont2Data:(id)container;
+ (NSString *)data2Json:(NSData *)data;
+ (NSData *)json2Data:(NSString *)json;
+ (void)removeWebChche;
+ (NSString *)cutPath:(NSString *)urlString;
+ (NSString *)cutFilename:(NSString *)urlString;
+ (NSString *)cutFileExt:(NSString *)urlString;
+ (NSString *)contentTypeForImageData:(NSData *)data;
+ (BOOL)checkingURLExists:(NSString *)url;
+ (void)shareData:(id)vc title:(NSString *)strTitle param:(NSMutableArray *)items;
+ (void)saveImagesToAlbum:(NSMutableArray *)images;
+ (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
+ (BOOL)externalAppRequiredToOpenURL:(NSURL *)URL;
+ (void)writeToFile:(NSString *)fullPath with:(NSData *)data;
+ (NSData *)readFromFile:(NSString *)path;
+ (NSString*)urlEncode:(NSString*)str;
+ (NSString*)urlDecode:(NSString*)str;
+ (NSString*)utf8toNString:(NSString*)str;

@end

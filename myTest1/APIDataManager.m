//
//  DataManedger.m
//  myTest1
//
//  Created by Andrii Ivanchenko on 09.12.16.
//  Copyright © 2016 Andrii Ivanchenko. All rights reserved.
//

#import "APIDataManager.h"
#import <ObjectiveFlickr/ObjectiveFlickr.h>


@interface APIDataManager()<OFFlickrAPIRequestDelegate>

@property (nonatomic, copy) void (^onDataFailed)(NSError* error);
@property (nonatomic, copy) void (^onDataCompleted)();

@property (nonatomic,copy) id getData;
@property (strong ,nonatomic) NSString *pathInfoAPI;

@property (nonatomic) OFFlickrAPIContext *flickrContext;
@property (nonatomic) OFFlickrAPIRequest *flickrRequest;


@end

@implementation APIDataManager

static APIDataManager *sharedSingleton_ = nil;

+(instancetype) sharedInstance {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[super alloc] initUniqueInstance];
    });
    return shared;
}

-(instancetype) initUniqueInstance {
    self.flickrContext = [[OFFlickrAPIContext alloc] initWithAPIKey:@"e10c9a601c393e035dca2908afedd217" sharedSecret:@"5ec1639c45be2f56"];
    
    return [super init];
}

/* установка токенна для авторизации*/
-(void) setAPItoken{
    
    [self.flickrContext setAuthToken:@"72157676755332252-ca52ca4e6ed57d74"];
    
}

/*получение данных по API*/
-(void) getAPImethod:(NSString* ) method
        didArguments:(NSDictionary *)argument
            fromPath:(NSString *)path
          onComplete:(void (^)(id arrayData)) completionBlock
             onError:(void (^)(NSError* errorData)) errorBlock
{
    _pathInfoAPI = path;
    self.onDataCompleted = completionBlock;
    self.onDataFailed = errorBlock;
    
    self.flickrRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:self.flickrContext];
    self.flickrRequest.delegate = self;
    
    
    if (![self.flickrRequest isRunning])
        [self.flickrRequest callAPIMethodWithGET:method arguments: argument];

}

/*Возврта результата сервером*/
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response
{
    _getData = [response valueForKeyPath:_pathInfoAPI];
    
    self.flickrRequest = nil;
    [self dataCompleted];
}
/*возврат урла фотографии*/
-(NSURL *) photoSourceURLFromDictionary:(NSDictionary *)photoDic
{
    NSURL *photoURL = [self.flickrContext photoSourceURLFromDictionary:photoDic size:OFFlickrMediumSize];
    return photoURL;
}
/*возврта ошибки сервера API*/
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didFailWithError:(NSError *)error
{
    [self dataFailedWithError:error];
    NSLog(@"Error loading API data", nil);
}

/*Выполнение блока при получении данных*/
-(void) dataCompleted
{
    if(self.onDataCompleted)
        self.onDataCompleted(_getData);
    //self.onDataCompleted = nil;
}

/*Выполнение блока при получении ошибки*/
-(void) dataFailedWithError:(NSError*) error
{   
    if(self.onDataFailed)
        self.onDataFailed(error);
    //self.onDataFailed = nil;
    
}

@end

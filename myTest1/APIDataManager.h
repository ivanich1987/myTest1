//
//  DataManedger.h
//  myTest1
//
//  Created by Andrii Ivanchenko on 09.12.16.
//  Copyright © 2016 Andrii Ivanchenko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APIDataManager : NSObject

+(instancetype) sharedInstance;

+(instancetype) alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));
-(instancetype) init __attribute__((unavailable("init not available, call sharedInstance instead")));
+(instancetype) new __attribute__((unavailable("new not available, call sharedInstance instead")));

-(NSURL *) photoSourceURLFromDictionary:(NSDictionary *)photoDic;

-(void) getAPImethod:(NSString* ) method
        didArguments:(NSDictionary *)argument
            fromPath:(NSString *) path
          onComplete:(void (^)(id arrayData)) completionBlock
             onError:(void (^)(NSError* errorData)) errorBlock;

-(void) setAPItoken;

@end

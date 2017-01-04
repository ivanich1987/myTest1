//
//  AIDataManager.h
//  myTest1
//
//  Created by Andrii Ivanchenko on 18.12.16.
//  Copyright © 2016 Andrii Ivanchenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface AIDataManager : NSObject

@property (readonly, strong) NSPersistentContainer *persistentContainer;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (void)saveContext;

+ (AIDataManager*) sharedManager;

-(void) saveComments:(NSArray*) arr forPhotoID:(NSInteger) key;
-(void) savePhotoInfo:(id) dic forPhotoID:(NSInteger) key;
-(void) saveFavorites:(id) dic forPhotoID:(NSInteger)key;

-(id) getElementTable:(NSString *) table forPredicate:(NSString *) predicateString;
-(id) getArrayTable:(NSString *) table
       forPredicate:(NSString *) predicateString
             toSort:(NSArray *) sort
            toLimit:(NSInteger) limit;

@end

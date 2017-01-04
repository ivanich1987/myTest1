//
//  AIDataManager.m
//  myTest1
//
//  Created by Andrii Ivanchenko on 18.12.16.
//  Copyright © 2016 Andrii Ivanchenko. All rights reserved.
//

#import "AIDataManager.h"
#import "Comments+CoreDataClass.h"
#import "PhotoInfo+CoreDataClass.h"

@implementation AIDataManager


+ (AIDataManager*) sharedManager {
    
    static AIDataManager* manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[AIDataManager alloc] init];
    });
    
    return manager;
}


- (id)init
{
    self = [super init];
    if (self) {
        _managedObjectContext =  [self persistentContainer].viewContext;
    }
    return self;
}

/*Получение данных с таблиц по критериям*/
-(id) getArrayTable:(NSString *) table
       forPredicate:(NSString *) predicateString
             toSort:(NSArray *) sort
            toLimit:(NSInteger) limit
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [request setEntity:[NSEntityDescription entityForName:table inManagedObjectContext:_managedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
    [request setPredicate:predicate];
    
    if(sort)
       [request setSortDescriptors:sort];
    
    if(limit>0)
       [request setFetchLimit:limit];
    
    NSError *error = nil;
    NSArray *results = [_managedObjectContext executeFetchRequest:request error:&error];
    
    return results;
}

/*Получение одной записи с таблицы*/
-(id) getElementTable:(NSString *) table forPredicate:(NSString *) predicateString{
    
    NSArray *results = [self getArrayTable:table
                              forPredicate: predicateString
                                    toSort:nil
                                   toLimit:1];
    
    if (results.count > 0)
    {
        return [results objectAtIndex:0];
    }
    
    return nil;
}

#pragma mark - Comments

/*Сохранить комментарии*/
-(void) saveComments:(NSArray*) arr forPhotoID:(NSInteger) key{
    
    for (NSDictionary *object in arr)
    {
        [self saveOnCoreData:object forPhotoID:key];
    }
}

/*Сохранить комментарий*/
-(void) saveOnCoreData:(NSDictionary *) dic forPhotoID:(NSInteger)key{
    
    
    NSString* strPredicate = [NSString stringWithFormat:@"id_comment like '%@'",[dic objectForKey:@"id"]];
    
    Comments* com = [self getElementTable:@"Comments" forPredicate:strPredicate];
    
    if(!com)
        com = [NSEntityDescription insertNewObjectForEntityForName:@"Comments"
                                            inManagedObjectContext:[AIDataManager sharedManager].persistentContainer.viewContext];
    com.text = [dic objectForKey:@"_text"];
    com.photo_id = key;
    com.permalink = [dic objectForKey:@"permalink"];
    com.id_comment = [dic objectForKey:@"id"];
    com.datecreate = [NSDate dateWithTimeIntervalSince1970:[[dic objectForKey:@"datecreate"] doubleValue]];
    com.authorname = [dic objectForKey:@"authorname"];
    com.author = [dic objectForKey:@"author"];
    com.realname = [dic objectForKey:@"realname"];
    com.iconfarm = [dic objectForKey:@"iconfarm"];
    com.iconserver = [dic objectForKey:@"iconserver"];
    com.author_is_deleted = [[dic objectForKey:@"author_is_deleted"] boolValue];
    
    NSError* error = nil;
    
    if (![_managedObjectContext save:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    
}

#pragma mark - PhotoInfo

/*Сохранить информацию фотографии*/
-(void) savePhotoInfo:(id) dic forPhotoID:(NSInteger)key{
    
    NSString* strPredicate = [NSString stringWithFormat:@"photo_id = %ld",(long)key];
    
    PhotoInfo* lv = [self getElementTable:@"PhotoInfo" forPredicate:strPredicate];
    
    if(!lv)
        lv = [NSEntityDescription insertNewObjectForEntityForName:@"PhotoInfo"
                                            inManagedObjectContext:_managedObjectContext];
    lv.photo_id = key;
    lv.title = [dic valueForKeyPath:@"title._text"] ;
    lv.desc = [dic valueForKeyPath:@"description._text"];
    lv.comment = [[dic valueForKeyPath:@"comments._text"] integerValue];
    lv.views = [[dic objectForKey:@"views"] integerValue];
    
    NSError* error = nil;
    
    if (![_managedObjectContext save:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    }
}

/*Сохранить информацию фотографии (количество избранных)*/
-(void) saveFavorites:(id) dic forPhotoID:(NSInteger)key{
    
    NSString* strPredicate = [NSString stringWithFormat:@"photo_id = %ld",(long)key];
    
    PhotoInfo* lv = [self getElementTable:@"PhotoInfo" forPredicate:strPredicate];
    
    if(!lv)
        lv = [NSEntityDescription insertNewObjectForEntityForName:@"PhotoInfo"
                                           inManagedObjectContext:_managedObjectContext];
    lv.photo_id = key;
    lv.likes = [[dic valueForKeyPath:@"total"] integerValue];
    
    NSError* error = nil;
    
    if (![_managedObjectContext save:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    
}




#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"myTest1"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}


@end

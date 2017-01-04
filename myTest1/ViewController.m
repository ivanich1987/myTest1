//
//  ViewController.m
//  myFlickr
//
//  Created by Andrii Ivanchenko on 08.12.16.
//  Copyright © 2016 Andrii Ivanchenko. All rights reserved.
//

#import "ViewController.h"
#import "APIDataManager.h"
#import "AIDataManager.h"
#import "Comments+CoreDataClass.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "PhotoInfo+CoreDataClass.h"
#import "DetailViewController.h"

@interface ViewController ()

@property (strong, nonatomic) NSMutableArray *photoArray;
@property (assign, atomic) BOOL isStated;
@property (assign, atomic) NSInteger indexComment;
@property (atomic, retain) NSTimer *myTimer;

@property (strong, nonatomic) NSFetchedResultsController<Comments *> *fetchedResultsController;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
   _tableView.rowHeight = UITableViewAutomaticDimension;
   _tableView.estimatedRowHeight = 85.0;

}

-(void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentSizeCategoryChanged:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIContentSizeCategoryDidChangeNotification
                                                  object:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    
    _isStated = false;
    
}

- (void)contentSizeCategoryChanged:(NSNotification *)notification
{
    [_tableView reloadData];
}



-(void) startComment{
    _isStated=true;
    _indexComment=0;
    [self nextLoadComments];
    
}


#pragma mark-
#pragma mark searchbar
/*Поиск фотографий по тегу*/
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [_tableView resignFirstResponder];
    //[self.view endEditing:YES];
    NSString *searchText = searchBar.text;
    _isStated=false;
    
    NSString *method = @"flickr.photos.search";
    
    NSDictionary *argument =@{@"tags": searchText,@"extras": @"description, perm_comment, owner_name, o_dims, views, url_m, comments, stats" };

    [[APIDataManager sharedInstance] getAPImethod: method
                                   didArguments: argument
                                       fromPath: @"photos.photo"
                                         onComplete:^(id response){
                                             _photoArray = response;
                                             [_tableView reloadData];
                                             [self startComment];
                                             [self.view endEditing:YES];
                                         }
                                            onError:^(NSError *error){
                                                _photoArray = [[NSMutableArray alloc] init];
                                                [_tableView reloadData];
                                            }];
}


/*Следующая итерация выгрузки комментария*/
-(void) nextLoadComments{
    
    if(_indexComment>([_photoArray count]-1))
        _isStated=false;
        
    if(_isStated==false)
        return;
    
    
    NSDictionary *dic = [_photoArray objectAtIndex:_indexComment];
    
    NSString *method = @"flickr.photos.comments.getList";
    NSInteger idPhoto = [[dic objectForKey:@"id"] integerValue];
    NSDictionary *argument =@{@"photo_id": [NSString stringWithFormat:@"%ld", (long)idPhoto]};
    
    [[APIDataManager sharedInstance] getAPImethod: method
                                     didArguments: argument
                                         fromPath: @"comments.comment"
                                       onComplete: ^(NSMutableArray * arrayData){
                                        
                                         [[AIDataManager sharedManager] saveComments:arrayData forPhotoID:idPhoto];
                                         
                                         [self nextLoadPhotoInfoForID:idPhoto];
                                         _indexComment++;
                                    }
                                        onError:^(NSError *error){
                                            
    }];
    
}
/*Выгрузка количество коментариев и просмотров*/
-(void) nextLoadPhotoInfoForID:(NSInteger) idPhoto{
    
    NSString *method = @"flickr.photos.getInfo";
    
    NSDictionary *argument =@{@"photo_id": [NSString stringWithFormat:@"%ld", (long)idPhoto]};
    
    [[APIDataManager sharedInstance] getAPImethod: method
                                     didArguments: argument
                                         fromPath: @"photo"
                                       onComplete:^(id arrayData){
                                           
                                           [[AIDataManager sharedManager] savePhotoInfo:arrayData forPhotoID:idPhoto];
                                           
                                           [self nextLoadFavoritesForID:idPhoto];
                                       }
                                          onError:^(NSError *error){
                                              
                                          }];
    
}
/*Выгрузка количество лайков*/
-(void) nextLoadFavoritesForID:(NSInteger) idPhoto{
    
    NSString *method = @"flickr.photos.getFavorites";
    
    NSDictionary *argument =@{@"photo_id": [NSString stringWithFormat:@"%ld", (long)idPhoto],
                              @"per_page": @"1"};
    
    [[APIDataManager sharedInstance] getAPImethod: method
                                     didArguments: argument
                                         fromPath: @"photo"
                                       onComplete:^(id arrayData){
                                           
                                           [[AIDataManager sharedManager] saveFavorites:arrayData forPhotoID:idPhoto];
                                           
                                           [self nextLoadComments];
                                       }
                                          onError:^(NSError *error){
                                              
                                          }];

}


-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    _searchBar.text=@"";
    [_tableView reloadData];
    [_tableView resignFirstResponder];
    [self.view endEditing:YES];
}

#pragma mark-
#pragma mark table data source and delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_photoArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableDictionary *photoDic = [_photoArray objectAtIndex:section];
    NSString *predicateString = [NSString stringWithFormat:@"photo_id like '%@'",[photoDic objectForKey:@"id"]];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"datecreate" ascending:YES];
    
    NSArray *arr = [[AIDataManager sharedManager] getArrayTable:@"Comments" forPredicate:predicateString toSort:[NSArray arrayWithObjects:sort, nil] toLimit:3];
    
    [photoDic setObject:arr forKey:@"com"];
    
    [_photoArray setObject:photoDic atIndexedSubscript:section];
    
    return [arr count];
}

/*Вычисоение высоты фотографии*/
-(float ) searchHeight:(NSInteger ) sec{
    
    NSDictionary *photoDic = [_photoArray objectAtIndex:sec];
    
    
    float w = [[photoDic objectForKey:@"width_m"] floatValue];
    float h = [[photoDic objectForKey:@"height_m"] floatValue];
    
    float rage = w/h;
    
    return _tableView.frame.size.width/rage;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return [self searchHeight:section];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSDictionary *photoDic = [_photoArray objectAtIndex:section];
    
    NSURL *urlPhoto = [[APIDataManager sharedInstance] photoSourceURLFromDictionary:photoDic];
    
    float hieght = [self searchHeight:section];
    
    CGRect rect = CGRectMake(0, 0, tableView.frame.size.width, hieght);
    UIView *view = [[UIView alloc] initWithFrame:rect];
    /* Create custom view to display section header... */
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:rect];
    [imgView sd_setImageWithURL:urlPhoto];
    [view addSubview:imgView];
    
    /*Описание*/
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, hieght-42, tableView.frame.size.width, 18)];
    [label setFont:[UIFont boldSystemFontOfSize:12]];
    [label setTextColor:[UIColor whiteColor]];
    [label setText:[photoDic valueForKeyPath:@"title"]];
    [view addSubview:label];
   
    /*Автор*/
    UILabel *label_a = [[UILabel alloc] initWithFrame:CGRectMake(10, hieght-25, tableView.frame.size.width, 18)];
    [label_a setFont:[UIFont boldSystemFontOfSize:12]];
    [label_a setTextColor:[UIColor whiteColor]];
    [label_a setText:[photoDic objectForKey:@"ownername"]];
    [view addSubview:label_a];
    
    NSString* strPredicate = [NSString stringWithFormat:@"photo_id like '%@'",[photoDic objectForKey:@"id"]];
    
    PhotoInfo* info = [[AIDataManager sharedManager] getElementTable:@"PhotoInfo" forPredicate:strPredicate];

    if(info)
    {
        /*Коментарии*/
        UILabel *label_c = [[UILabel alloc] initWithFrame:CGRectMake(tableView.frame.size.width-20, hieght-25, tableView.frame.size.width, 18)];
        [label_c setFont:[UIFont boldSystemFontOfSize:12]];
        [label_c setTextColor:[UIColor whiteColor]];
        NSString* comm = [NSString stringWithFormat:@"%lld", info.comment];
        if(info.comment>99)
            comm = @"99+";
        [label_c setText:comm];
        [view addSubview:label_c];
        
        UIImageView* img_c = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"comm"]];
        [img_c setFrame:CGRectMake(tableView.frame.size.width-38, hieght-25, 18, 18)];
        [view addSubview:img_c];
        
        /*Лайки*/
        UILabel *label_l = [[UILabel alloc] initWithFrame:CGRectMake(tableView.frame.size.width-60, hieght-25, tableView.frame.size.width, 18)];
        [label_l setFont:[UIFont boldSystemFontOfSize:12]];
        [label_l setTextColor:[UIColor whiteColor]];
        NSString* like = [NSString stringWithFormat:@"%lld", info.likes];
        if(info.likes>99)
            like = @"99+";
        [label_l setText:like];
        [view addSubview:label_l];
        
        UIImageView* img_l = [[UIImageView alloc] initWithFrame:CGRectMake(tableView.frame.size.width-78, hieght-25, 18, 18)];
        [img_l setImage:[UIImage imageNamed:@"fav"]];
        [view addSubview:img_l];

    }
    
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    [singleTapRecognizer setDelegate:self];
    singleTapRecognizer.numberOfTouchesRequired = 1;
    singleTapRecognizer.numberOfTapsRequired = 1;
    [view addGestureRecognizer:singleTapRecognizer];
    [view setTag:section];
    [view setBackgroundColor:[UIColor colorWithRed:166/255.0 green:177/255.0 blue:186/255.0 alpha:1.0]]; //your background color...
    return view;
}

-(void) handleGesture:(UITapGestureRecognizer *) gestureRecognizer{
    
    NSDictionary *photoDic = [_photoArray objectAtIndex:gestureRecognizer.view.tag];

    [self performSegueWithIdentifier:@"DetailPhoto" sender:photoDic];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"DetailPhoto"])
    {
        if([sender isKindOfClass:[UITableViewCell class]])
        {
            NSIndexPath *indexpath = [_tableView indexPathForSelectedRow];
            if(indexpath)
            {
                NSDictionary *sendDetail = [_photoArray objectAtIndex:indexpath.section];
                [segue.destinationViewController setDetail:sendDetail];
            }
        }
        else
            [segue.destinationViewController setDetail:sender];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"commentCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *photoDic = [_photoArray objectAtIndex:indexPath.section];
    NSArray *comments = [photoDic objectForKey:@"com"];
    
    Comments *com = [comments objectAtIndex:indexPath.row];
    
    UILabel *autorLabel = [cell.contentView viewWithTag:2002];
    autorLabel.text = [NSString stringWithFormat:@"%@",com.authorname];
    
    NSString *com_str = [NSString stringWithFormat:@"%@<br><br>",com.text];
    
    NSAttributedString *atr = [[NSAttributedString alloc] initWithData:[com_str dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding]} documentAttributes:nil error:nil];

    UILabel *comLabel = [cell.contentView viewWithTag:2003];
    [comLabel setAttributedText:atr];
    
    NSURL *urlIcon = [NSURL URLWithString:[NSString stringWithFormat:@"https://farm%@.staticflickr.com/%@/buddyicons/%@.jpg",com.iconfarm, com.iconserver, com.author ]];
    
    UIImageView *imageView = [cell.contentView viewWithTag:2001];
    
    [imageView sd_setImageWithURL:urlIcon placeholderImage:[UIImage imageNamed:@"comm"]];
    imageView.layer.cornerRadius = 35;
    imageView.layer.masksToBounds = YES;
    
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell withEvent:(Comments *)event {
    cell.textLabel.text = event.authorname;
}


@end

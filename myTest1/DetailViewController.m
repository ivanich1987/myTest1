//
//  DetailViewController.m
//  myTest1
//
//  Created by Andrii Ivanchenko on 29.12.16.
//  Copyright © 2016 Andrii Ivanchenko. All rights reserved.
//

#import "DetailViewController.h"
#import "APIDataManager.h"
#import "AIDataManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "PhotoInfo+CoreDataClass.h"
#import "Comments+CoreDataClass.h"

@interface DetailViewController () <UITextFieldDelegate>

@property (nonatomic, strong) NSDictionary *infoDic;
@property (nonatomic, strong) NSArray *comArray;

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UILabel *viewsLabel;
@property (weak, nonatomic) IBOutlet UILabel *favesLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentsLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableViewCom;
@property (weak, nonatomic) IBOutlet UITextField *messTextField;
@property (retain, nonatomic) UITextField *myTextField;


@end

@implementation DetailViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableViewCom.rowHeight = UITableViewAutomaticDimension;
    _tableViewCom.estimatedRowHeight = 320;
    
    [self setTitle:[_infoDic objectForKey:@"title"]];
    
    [self loadPhoto];
    
    [self loadInfo];
    
    [self loadComments];
    
    [self loadAPIAll];
    
    _messTextField.delegate = self;
    
    _myTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width-80, 30)];
    [_myTextField setBackgroundColor:[UIColor whiteColor]];
    UIBarButtonItem *textFieldItem = [[UIBarButtonItem alloc] initWithCustomView:_myTextField];
    
    UIBarButtonItem *btnItem = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStylePlain target:nil action:@selector(sendMess)];
    
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
    numberToolbar.items = [NSArray arrayWithObjects:
                           textFieldItem,
                           btnItem,
                           nil];
    [numberToolbar sizeToFit];
    _messTextField.inputAccessoryView = numberToolbar;
}

/*Старт обновления данных с API*/
-(void) loadAPIAll{
    [self loadAPIFavesForID];
}

/*Отправка комментария на сервер */
-(void) sendMess{
    [self.view endEditing:TRUE];
    
    NSString *method = @"flickr.photos.comments.addComment";
    
    NSDictionary *argument =@{@"photo_id": [NSString stringWithFormat:@"%@", [_infoDic objectForKey:@"id"]],
                              @"comment_text": _myTextField.text };
    
    [[APIDataManager sharedInstance] getAPImethod: method
                                     didArguments: argument
                                         fromPath: @"comment"
                                       onComplete:^(id arrayData){
                                           [self loadComments];
                                       }
                                          onError:^(NSError *error){
                                              
                                          }];
 
    [self textFieldShouldReturn:_messTextField];
    NSLog(@"SendMESS ");
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

/*загрузить комментарии*/
-(void) loadComments{
    
    NSString *predicateString = [NSString stringWithFormat:@"photo_id like '%@'",[_infoDic objectForKey:@"id"]];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"datecreate" ascending:YES];
    
    _comArray = [[AIDataManager sharedManager] getArrayTable:@"Comments" forPredicate:predicateString toSort:[NSArray arrayWithObjects:sort, nil] toLimit:0];
    
    
    NSString *method = @"flickr.photos.comments.getList";
    NSInteger idPhoto = [[_infoDic objectForKey:@"id"] integerValue];
    NSDictionary *argument =@{@"photo_id": [NSString stringWithFormat:@"%ld", (long)idPhoto]};
    
    [[APIDataManager sharedInstance] getAPImethod: method
                                     didArguments: argument
                                         fromPath: @"comments.comment"
                                       onComplete: ^(id arrayData){
                                           
                                           [[AIDataManager sharedManager] saveComments:arrayData forPhotoID:idPhoto];
                                           
                                           NSString *predicateString = [NSString stringWithFormat:@"photo_id like '%@'",[_infoDic objectForKey:@"id"]];
                                           
                                           NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"datecreate" ascending:YES];
                                           
                                           _comArray = [[AIDataManager sharedManager] getArrayTable:@"Comments" forPredicate:predicateString toSort:[NSArray arrayWithObjects:sort, nil] toLimit:0];

                                           [_tableViewCom reloadData];
                                       }
                                          onError:^(NSError *error){
                                              
                                          }];
}

/*загрузить информацию фотографии с базы данных*/
-(void) loadInfo{
    
    NSInteger idPhoto = [[_infoDic objectForKey:@"id"] integerValue];
    
    NSString* strPredicate = [NSString stringWithFormat:@"photo_id like '%ld'",(long)idPhoto];
    
    PhotoInfo* info = [[AIDataManager sharedManager] getElementTable:@"PhotoInfo" forPredicate:strPredicate];

    if(info)
    {
        [_descLabel setText:info.desc];
        [self setNewFrameFromDesc:info.desc];
        [_viewsLabel setText:[NSString stringWithFormat:@"%lld", info.views]];
        [_commentsLabel setText:[NSString stringWithFormat:@"%lld", info.comment]];
        [_favesLabel setText:[NSString stringWithFormat:@"%lld", info.likes]];
    }
    
}

/*Загрузить информацию фотографии(описание, просмотры, комметарии) с сервера*/
-(void) loadAPIDescViewsCommForID
{
    NSInteger idPhoto = [[_infoDic objectForKey:@"id"] integerValue];
    
    NSString *method = @"flickr.photos.getInfo";
    
    NSDictionary *argument =@{@"photo_id": [NSString stringWithFormat:@"%ld", (long)idPhoto]};

    [[APIDataManager sharedInstance] getAPImethod: method
                                     didArguments: argument
                                         fromPath: @"photo"
                                       onComplete:^(id arrayData){
                                           
                                           [[AIDataManager sharedManager] savePhotoInfo:arrayData forPhotoID:idPhoto];
                                           
                                            NSAttributedString *atr = [[NSAttributedString alloc] initWithData:[[arrayData valueForKeyPath:@"description._text"] dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding]} documentAttributes:nil error:nil];
                                           
                                           [_descLabel setText:[arrayData valueForKeyPath:@"description._text"]];
                                           [_descLabel setAttributedText:atr];
                                           [self setNewFrameFromDesc:[arrayData valueForKeyPath:@"description._text"]];
                                           [_viewsLabel setText:[NSString stringWithFormat:@"%ld", [[arrayData objectForKey:@"views"] integerValue]]];
                                           [_commentsLabel setText:[NSString stringWithFormat:@"%ld", [[arrayData valueForKeyPath:@"comments._text"] integerValue]]];
                                           
                                           
                                       }
                                          onError:^(NSError *error){
                                              
                                          }];

}


/*Загрузить информацию фотографии(избранное) с сервера*/
-(void) loadAPIFavesForID
{
    NSInteger idPhoto = [[_infoDic objectForKey:@"id"] integerValue];
    
    NSString *method = @"flickr.photos.getFavorites";
    
    NSDictionary *argument =@{@"photo_id": [NSString stringWithFormat:@"%ld", (long)idPhoto],
                              @"per_page": @"1"};
    
    [[APIDataManager sharedInstance] getAPImethod: method
                                     didArguments: argument
                                         fromPath: @"photo"
                                       onComplete:^(id arrayData){
                                           
                                           [[AIDataManager sharedManager] saveFavorites:arrayData forPhotoID:idPhoto];
                                           [_favesLabel setText:[NSString stringWithFormat:@"%ld", [[arrayData valueForKeyPath:@"total"] integerValue]]];
                                          
                                           [self loadAPIDescViewsCommForID];
                                       }
                                          onError:^(NSError *error){
                                              
                                          }];

}

/*Определение высоты строки описания*/
-(void) setNewFrameFromDesc:(NSString*) descStr{
    CGSize maximumLabelSize = CGSizeMake(296, FLT_MAX);
    
    CGSize expectedLabelSize = [descStr sizeWithFont:_descLabel.font constrainedToSize:maximumLabelSize lineBreakMode:_descLabel.lineBreakMode];
    CGRect newFrame = _descLabel.frame;
    newFrame.size.height = expectedLabelSize.height;
    _descLabel.frame = newFrame;
    
}


/*загрузка фотографии*/
-(void) loadPhoto{
    
    float w = [[_infoDic objectForKey:@"width_m"] floatValue];
    float h = [[_infoDic objectForKey:@"height_m"] floatValue];
    
    float rage = w/h;
    
    NSURL *urlPhoto = [[APIDataManager sharedInstance] photoSourceURLFromDictionary:_infoDic];
    
    [_imgView setFrame:CGRectMake(0, 0, _imgView.frame.size.width, _imgView.frame.size.width/rage)];
    [_imgView sd_setImageWithURL:urlPhoto];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) setDetail:(NSDictionary *)dic{
    _infoDic = dic;
}

#pragma mark-
#pragma mark table data source and delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_comArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"commentCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Comments *com = [_comArray objectAtIndex:indexPath.row];
    
    UILabel *autorLabel = [cell.contentView viewWithTag:2002];
    autorLabel.text = [NSString stringWithFormat:@"%@",com.authorname];
    
    NSString *com_str = [NSString stringWithFormat:@"%@ <br><br>",com.text];
    
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


@end

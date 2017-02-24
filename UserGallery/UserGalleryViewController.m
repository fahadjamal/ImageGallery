//
//  ViewController.m
//  UserGallery
//
//  Created by Fahad Jamal on 13/10/2015.
//  Copyright © 2015 ifahja. All rights reserved.
//

#import "UserGalleryViewController.h"
#import "GalleryCollectionViewCell.h"
#import "AddPhotoCollectionCell.h"

#import <Social/Social.h>
#import "MWPhotoBrowser.h"

#import "UIImageView+UIActivityIndicatorForSDWebImage.h"
#import "messageui/MessageUI.h"

#import "JGActionSheet.h"

#import "NZAlertView.h"
#import "NZAlertViewDelegate.h"
#import "KVNProgress.h"
#import "UIScrollView+BottomRefreshControl.h"

#import <RestKit.h>
#import "UserGalleryPaginationItems.h"
#import "UserGalleryItems.h"
#import "ServerResponse.h"

#define iPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define NUMBER_OF_CELLS 10

@interface UserGalleryViewController () <UIActionSheetDelegate, UIAlertViewDelegate, JGActionSheetDelegate,
MWPhotoBrowserDelegate, NZAlertViewDelegate, MFMailComposeViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) NSMutableArray *galleryItemsArray;
@property (nonatomic, strong) NSMutableArray *selectedCellIndexesArray;

@property (nonatomic, strong) UserGalleryPaginationItems *galleryListItems;

@property (nonatomic, assign) BOOL deleteEnabled;

@property (nonatomic, strong) UIBarButtonItem *shareBarButton;

@property (nonatomic, strong) KVNProgressConfiguration *basicConfiguration;

@property (nonatomic, assign) NSInteger galleryCurrentPage;
@property (nonatomic, assign) NSInteger galleryLastIndex;
@property (nonatomic, assign) NSInteger galleryTotalPages;

@property (nonatomic, strong) IBOutlet UICollectionView *mainCollectionView;

@end

@implementation UserGalleryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    [self.navigationItem setTitle:@"User Gallery"];
    _galleryItemsArray = [[NSMutableArray alloc] initWithCapacity:0];
    
    // Initialize recipe image array
    self.basicConfiguration = [KVNProgressConfiguration defaultConfiguration];
    
//    NSAttributedString *bottomRefreshString = [[NSAttributedString alloc] initWithString:@"Loading"
//                                                                              attributes:@{NSFontAttributeName:
//                                                                                               [UIFont boldSystemFontOfSize:20.0f],
//                                                                                           NSForegroundColorAttributeName:[UIColor blackColor],}];
//    UIRefreshControl *bottomRefreshControl = [UIRefreshControl new];
//    bottomRefreshControl.triggerVerticalOffset = 60;
//    [bottomRefreshControl setTintColor:[UIColor whiteColor]];
//    [bottomRefreshControl setAttributedTitle:bottomRefreshString];
//    [bottomRefreshControl addTarget:self action:@selector(bottomRefreshPhotoGallery:) forControlEvents:
//     UIControlEventValueChanged];
//    self.mainCollectionView.bottomRefreshControl = bottomRefreshControl;
    
    self.galleryLastIndex = 0;
    
    //if ([[DataManager sharedInstance] isNetworkReachable]) {
    
    [KVNProgress showWithStatus:@"Loading..."];
    [self loadUserGalleryList:@"http://www.demo.com" withPathPattern:@"/demo/brand/user_images.php" uploadImage:nil
                                                                                                      withName:@""];
//    }
//    else {
//        [self galleryNetworkNotReachable];
//    }
}

#pragma mark - InterfaceOrientation Method -

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

-(void)willRotateToInterfaceOrientation: (UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
    [self.mainCollectionView.collectionViewLayout invalidateLayout];
}

#pragma mark - UICollectionViewDataSource Method -

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger itemsCount = [_galleryItemsArray count];
    return itemsCount = itemsCount + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.item == 0) {
        AddPhotoCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AddPhotoCollectionCell"
                                                                                 forIndexPath:indexPath];
        cell.addImageView.image = [UIImage imageNamed:@"addphoto-bg"];
        return cell;
    }
    else {
        GalleryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GalleryCollectionViewCell"
                                                                                    forIndexPath:indexPath];
        [cell.galleryImageView setContentMode:UIViewContentModeScaleAspectFill];
        [cell.galleryImageView.layer setMasksToBounds:YES];
        
        NSDictionary *galleryItemDict = [_galleryItemsArray objectAtIndex:indexPath.row - 1];
        NSString *photoURLString = [NSString stringWithFormat:@"%@", [galleryItemDict valueForKey:@"ImageUrl"]];
        [cell.galleryImageView setImageWithURL:[NSURL URLWithString:photoURLString]
                   usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        return cell;
    }
}

#pragma mark - UICollectionViewDelegate Method -

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.item == 0) {
        JGActionSheetSection *section = [JGActionSheetSection sectionWithTitle:@"Gallery Menu" message:@"Select an option for importing Photo." buttonTitles:@[@"Take Photo", @"Choose From PhotoAlbum"]
                                                                   buttonStyle:JGActionSheetButtonStyleDefault];
        [section setButtonStyle:JGActionSheetButtonStyleGreen forButtonAtIndex:0];
        [section setButtonStyle:JGActionSheetButtonStyleBlue forButtonAtIndex:1];
        
        NSArray *sections = @[section, [JGActionSheetSection sectionWithTitle:nil message:nil buttonTitles:@[@"Cancel"] buttonStyle:JGActionSheetButtonStyleCancel]];
        
        JGActionSheet *sheet = [[JGActionSheet alloc] initWithSections:sections];
        sheet.delegate = self;
        [sheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
            if (indexPath.row == 0 && indexPath.section == 0) {
                [self loadPhotoFromCamera];
            }
            else if (indexPath.row == 1 && indexPath.section == 0) {
                [self loadFromPhotoAlbum];
            }
            [sheet dismissAnimated:YES];
        }];
        
        if (iPad) {
            [sheet setOutsidePressBlock:^(JGActionSheet *sheet) {
                [sheet dismissAnimated:YES];
            }];
            [sheet showInView:self.navigationController.view animated:YES];
        }
        else {
            [sheet showInView:self.navigationController.view animated:YES];
        }
    }
    else {
        MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
        browser.displayActionButton = YES;
        [browser setCurrentPhotoIndex:indexPath.row - 1];
        [self.navigationController pushViewController:browser animated:YES];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    GalleryCollectionViewCell *cell = (GalleryCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    //set color with animation
    [UIView animateWithDuration:0.1
                          delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         [cell setBackgroundColor:[UIColor colorWithRed:232/255.0f green:232/255.0f blue:232/255.0f alpha:1]];
                     }
                     completion:nil];
}

- (void)collectionView:(UICollectionView *)collectionView  didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    GalleryCollectionViewCell *cell = (GalleryCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    //set color with animation
    [UIView animateWithDuration:0.1
                          delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         [cell setBackgroundColor:[UIColor clearColor]];
                     }
                     completion:nil ];
}

#pragma mark - UICollectionViewDelegateFlowLayout Method -

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (iPad) {
        return CGSizeMake((self.mainCollectionView.bounds.size.width/4)-1, 150);
    }
    else {
        return CGSizeMake((self.mainCollectionView.bounds.size.width/3)-1, 120);
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 1.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 1.0;
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0); // top, left, bottom, right
}

#pragma mark - MWPhotoBrowserDelegate Method -

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _galleryItemsArray.count;
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _galleryItemsArray.count) {
        NSDictionary *photoDic = [_galleryItemsArray objectAtIndex:index];
        NSString *selectedFilePath = [NSString stringWithFormat:@"%@", [photoDic valueForKey:@"ImageUrl"]];
        NSString *selectedFileName = [NSString stringWithFormat:@"%@", [selectedFilePath lastPathComponent]];
        MWPhoto *photo = [MWPhoto photoWithURL:[NSURL URLWithString:selectedFilePath]];
        photo.caption = selectedFileName;
        return photo;
    }
    return nil;
}

- (void)bottomRefreshPhotoGallery:(id)sender {
//    if (self.galleryCurrentPage < self.galleryTotalPages) {
//        self.galleryLastIndex = [self.galleryImagesArray count];
//        
//        double delayInSeconds = 0.5;
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//            if ([[DataManager sharedInstance] isNetworkReachable]) {
//                [KVNProgress showWithStatus:@"Loading..."];
//                [self loadImageGalleryData];
//                [self.mainCollectionView.bottomRefreshControl endRefreshing];
//            }
//            else {
//                [self galleryNetworkNotReachable];
//            }
//        });
//    }
//    else {
//        self.mainCollectionView.bottomRefreshControl = nil;
//    }
}

-(void)loadImageGalleryData {
//    NSString *lastIndexString = [NSString stringWithFormat:@"%ld", (long)self.galleryLastIndex];
//    NSString *totalCellString = [NSString stringWithFormat:@"%d", NUMBER_OF_IMAGES_CELLS];
//    
//    NSArray *objectsArray = [[NSArray alloc] initWithObjects:lastIndexString, totalCellString, nil];
//    NSArray *keysArray = [[NSArray alloc] initWithObjects:@"idx_last_element", @"block_size_paging", nil];
//    NSDictionary *albumDataDic = [[NSDictionary alloc] initWithObjects:objectsArray forKeys:keysArray];
//    
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    [manager.requestSerializer setTimeoutInterval:30];
//    manager.requestSerializer  = [AFHTTPRequestSerializer serializer];
//    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
//    [manager POST:IMAGES_GALLERY parameters:albumDataDic success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSError *error = nil;
//        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:responseObject
//                                                                 options:NSJSONReadingAllowFragments error:&error];
//        self.galleryTotalPages = [[jsonDict objectForKey:@"total_pages"] integerValue];
//        self.galleryCurrentPage = [[jsonDict objectForKey:@"current_page"] integerValue];
//        
//        for (id objectDictionary in [jsonDict objectForKey:@"objects"]) {
//            if (![self.galleryImagesArray containsObject:objectDictionary]) {
//                [self.galleryImagesArray addObject:objectDictionary];
//            }
//        }
//        
//        [self.mainCollectionView reloadData];
//        
//        if (self.galleryCurrentPage ==  self.galleryTotalPages) {
//            self.mainCollectionView.bottomRefreshControl = nil;
//        }
//        
//        [KVNProgress showSuccessWithStatus:@"Success"];
//        
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"operation=%@",operation);
//        NSLog(@"Error: %@", error);
//        
//        [KVNProgress showErrorWithStatus:@"Loading Failed"];
//    }];
}

-(void)galleryNetworkNotReachable {
    [KVNProgress showErrorWithStatus:@"Network connection error.Unable to connect to internet."];
}

#pragma mark - UIImagePickerControllerDelegate Method -

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *originalImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    [[self navigationController] dismissViewControllerAnimated:NO completion:^{
        [self loadUserGalleryList:@"http://www.weions.com" withPathPattern:@"/demo/brand/user_images.php" uploadImage:originalImage withName:@"test_Pic"];
    }];
}

#pragma mark - Class Instance Method -

-(void)loadUserGalleryList:(NSString *)urlString withPathPattern:(NSString *)pathPattern uploadImage:(UIImage *)uploadImage withName:(NSString *)nameString {
    
    NSString *totalCellString = [NSString stringWithFormat:@"%d", NUMBER_OF_CELLS];
    NSString *lastIndexString = [NSString stringWithFormat:@"%ld", (long)_galleryLastIndex];
    
    NSArray *objectsArray = [NSArray arrayWithObjects:nameString, @"8", lastIndexString, totalCellString,  nil];
    NSArray *keysArray = [NSArray arrayWithObjects:@"user_image", @"user_id", @"idx_last_element", @"block_size_paging",nil];
    
    NSDictionary *parametersDict = [[NSDictionary alloc] initWithObjects:objectsArray forKeys:keysArray];
    NSURL *baseURL = [NSURL URLWithString:urlString];
    
    if (uploadImage != nil) {
        AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:baseURL]; //Init by url
        RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:client];
        [RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:RKMIMETypeJSON];
        
        RKObjectMapping *userGalleryMapping = [RKObjectMapping mappingForClass:[ServerResponse class]];
        [userGalleryMapping addAttributeMappingsFromDictionary:@{@"message": @"message", @"idx_last_element": @"idx_last_element", @"total_page": @"total_page", @"current_page": @"current_page", @"objects": @"objects"}];
        RKResponseDescriptor* responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userGalleryMapping
                                                                                                method:RKRequestMethodAny
                                                                                           pathPattern:nil keyPath:nil
                                                                                           statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
        [objectManager addResponseDescriptor:responseDescriptor];
        
        NSMutableURLRequest *request = [objectManager multipartFormRequestWithObject:userGalleryMapping method:RKRequestMethodPOST path:@"/demo/brand/user_images.php" parameters:parametersDict constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:UIImagePNGRepresentation(uploadImage)
                                        name:@"photo"
                                    fileName:@"photo.png"
                                    mimeType:@"image/png"];
        }];
        
        RKObjectRequestOperation *operation = [objectManager objectRequestOperationWithRequest:request success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
            ServerResponse *serverResponse = (ServerResponse *)[mappingResult.array firstObject];
            [self requestFinished:serverResponse];
        } failure:^(RKObjectRequestOperation *operation, NSError *error) {
            [KVNProgress showErrorWithStatus:@"Server Error"];
        }];
        [objectManager enqueueObjectRequestOperation:operation];
    }
    else {
        AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:baseURL]; //Init by url
        //set up restkit
        RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:client];
        [RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:RKMIMETypeJSON];
        
        RKObjectMapping *userGalleryMapping = [RKObjectMapping mappingForClass:[ServerResponse class]];
        [userGalleryMapping addAttributeMappingsFromDictionary:@{@"message": @"message", @"idx_last_element": @"idx_last_element", @"total_page": @"total_page", @"current_page": @"current_page", @"objects": @"objects"}];
        RKResponseDescriptor* responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userGalleryMapping
                                                                                                method:RKRequestMethodAny
                                                                                           pathPattern:nil keyPath:nil
                                                                                           statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
        [objectManager addResponseDescriptor:responseDescriptor];
        [objectManager getObjectsAtPath:@"/demo/brand/user_images.php"
                             parameters:parametersDict
                                success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                    NSLog(@"mappingResult.array is %@", mappingResult.array);
                                    ServerResponse *serverResponse = (ServerResponse *)[mappingResult.array firstObject];
                                    [self requestFinished:serverResponse];
                                }
                                failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                    [KVNProgress showErrorWithStatus:@"Server Error"];
                                }];
    }
}

-(void) requestFinished:(ServerResponse *)responseFromServer {
    _galleryCurrentPage = [responseFromServer.current_page integerValue];
    _galleryLastIndex  = [responseFromServer.idx_last_element integerValue];
    _galleryTotalPages = [responseFromServer.current_page integerValue];
    
    NSLog(@"%@", responseFromServer.objects.allObjects);
    
    for (NSString *galleryItemURL in responseFromServer.objects.allObjects) {
        if (![_galleryItemsArray containsObject:galleryItemURL]) {
            [_galleryItemsArray addObject:galleryItemURL];
        }
    }
    
    [_mainCollectionView reloadData];
    [KVNProgress showSuccessWithStatus:@"Gallery Loaded"];
}

//    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:baseURL]; // init by url
//    //set up restkit
//    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:client];
//    [RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:@"text/html"];
//    
//    NSArray *userGalleryKeysArray = [NSArray arrayWithObjects:@"title", @"shortdesc", nil];
//    RKObjectMapping *catListMapping = [RKObjectMapping mappingForClass:[UserGalleryItems class]];
//    [catListMapping addAttributeMappingsFromArray:userGalleryKeysArray];
//    
//    RKObjectMapping *catPaginationMapping = [RKObjectMapping mappingForClass:[UserGalleryPaginationItems class]];
//    [catPaginationMapping addAttributeMappingsFromDictionary:@{@"current_page" : @"current_page",
//                                                               @"idx_last_element" : @"idx_last_element",
//                                                               @"total_pages" : @"total_pages"}];
//    
//    [catPaginationMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"objects" toKeyPath:@"objects" withMapping:catListMapping]];
//    
//    // register mappings with the provider using a response descriptor
//    RKResponseDescriptor *pagResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:catPaginationMapping
//                                                                                               method:RKRequestMethodGET
//                                                                                          pathPattern:nil
//                                                                                              keyPath:nil
//                                                                                          statusCodes:[NSIndexSet indexSetWithIndex:200]];
//    [objectManager addResponseDescriptor:pagResponseDescriptor];
//    [objectManager getObjectsAtPath:pathPattern
//                         parameters:parametersDict
//                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
//                                _galleryListItems = (UserGalleryPaginationItems *)mappingResult.firstObject;
//                                _galleryCurrentPage = [_galleryListItems.current_page integerValue];
//                                _galleryLastIndex  = [_galleryListItems.idx_last_element integerValue];
//                                _galleryTotalPages = [_galleryListItems.total_pages integerValue];
//                                
//                                for (UserGalleryItems *galleryItem in _galleryListItems.objects.allObjects) {
//                                    if (![_galleryItemsArray containsObject:galleryItem]) {
//                                        [_galleryItemsArray addObject:galleryItem];
//                                    }
//                                }
//                                
//                                [_mainCollectionView reloadData];
//                                [KVNProgress showWithStatus:@"Items Loaded"];
//                            }
//                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
//                                [KVNProgress showErrorWithStatus:@"Server Error"];
//                                NSLog(@"What do you mean by 'there is no coffee?': %@", error);
//                            }];

-(void) loadPhotoFromCamera {
    NSLog(@"loadPhotoFromCamera");
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        [imagePicker setEditing:YES];
        [imagePicker setDelegate:self];
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}

-(void) loadFromPhotoAlbum {
    NSLog(@"loadFromPhotoAlbum");
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    [imagePickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [imagePickerController setDelegate:self];
    [imagePickerController setAllowsEditing:YES];
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

#pragma mark - Default De-Init Method -

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc {
    _galleryItemsArray = nil;
    _selectedCellIndexesArray = nil;
    
    _shareBarButton = nil;
    _basicConfiguration = nil;
    
    _mainCollectionView = nil;
}

@end

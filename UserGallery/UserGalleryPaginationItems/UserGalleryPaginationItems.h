//
//  RSSItems.h
//  PakPakistan
//
//  Created by Fahad Jamal on 15/09/2015.
//  Copyright (c) 2015 ifahja. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserGalleryPaginationItems : NSObject

@property (nonatomic, strong) NSString *current_page;
@property (nonatomic, strong) NSString *idx_last_element;
@property (nonatomic, strong) NSString *total_pages;

@property (nonatomic, strong) NSSet *objects;

@end
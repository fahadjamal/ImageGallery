//
//  ServerResponse.h
//  Brand
//
//  Created by Fahad Jamal on 01/10/2015.
//  Copyright © 2015 ifahja. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ServerResponse : NSObject

@property(nonatomic, strong) NSString *message;
@property(nonatomic, strong) NSString *idx_last_element;
@property(nonatomic, strong) NSString *total_page;
@property(nonatomic, strong) NSString *current_page;

@property(nonatomic, strong) NSSet *objects;

@end

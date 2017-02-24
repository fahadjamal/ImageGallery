//
//  GalleryCollectionViewCell.h
//  CollectionViewDemo
//
//  Created by Simon on 9/1/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KVNBoundedImageView.h"

@interface GalleryCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet KVNBoundedImageView *galleryImageView;

@end

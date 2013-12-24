//
//  PopoverBackgroundView.m
//  Guide
//
//  Created by Jim Ramlall on 2013-05-27.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//

#import "PopoverBackgroundView.h"
#import <QuartzCore/QuartzCore.h>

#define kArrowBase 30.0f
#define kArrowHeight 20.0f
#define kBorderInset 0.0f

@implementation PopoverBackgroundView
// Required setters for subclassing 
@synthesize arrowDirection  = _arrowDirection;
@synthesize arrowOffset     = _arrowOffset;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

+ (CGFloat)arrowBase
{
    return kArrowBase;
}
+ (CGFloat)arrowHeight
{
    return kArrowHeight;
}

+ (UIEdgeInsets)contentViewInsets
{
    return UIEdgeInsetsMake(kBorderInset, kBorderInset, kBorderInset, kBorderInset);
}

+ (BOOL)wantsDefaultContentAppearance
{
    return NO;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end

//
//  DefinitionViewController.m
//  Guide
//
//  Created by Jim Ramlall on 2013-05-27.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "DefinitionViewController.h"

@implementation DefinitionViewController
@synthesize definition, typeName, nameColour, textHeight, infoButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    nameLabel.text = typeName;
    
    // Set darker colour for text
    float h, s, b, a;
    if([nameColour getHue:&h saturation:&s brightness:&b alpha:&a])
        [nameLabel setTextColor:[UIColor colorWithHue:h saturation:s brightness:b*0.9 alpha:a]];
        
    CGRect newFrame = definitionText.frame;
    newFrame.size.height = textHeight + 10;
    definitionText.frame = newFrame;
    definitionText.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    definitionText.text = definition;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillDisappear:(BOOL)animated{
    // Animate plus button on close
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.fromValue = [NSNumber numberWithFloat:M_PI/4];
    rotationAnimation.toValue = [NSNumber numberWithFloat:0];
    rotationAnimation.duration = 0.2;
    rotationAnimation.cumulative = NO;
    rotationAnimation.fillMode = kCAFillModeForwards;
    rotationAnimation.removedOnCompletion = NO;
    [infoButton.layer setAnchorPoint:CGPointMake(0.5, 0.5)];    
    [infoButton.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

@end

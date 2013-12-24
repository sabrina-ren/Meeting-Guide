//
//  DefinitionViewController.h
//  Guide
//
//  Created by Jim Ramlall on 2013-05-27.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//

// Content view controller for info popovers

#import <UIKit/UIKit.h>

@interface DefinitionViewController : UIViewController {
    __weak IBOutlet UITextView *definitionText;
    __weak IBOutlet UILabel *nameLabel;
}

@property (nonatomic) NSMutableString *definition;
@property (nonatomic) CGFloat textHeight;
@property (weak, nonatomic) NSString* typeName;
@property (weak, nonatomic) UIButton* infoButton;
@property (nonatomic) UIColor* nameColour;

@end

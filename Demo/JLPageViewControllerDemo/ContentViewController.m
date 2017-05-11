//
//  ContentViewController.m
//  JLPageViewControllerDemo
//
//  Created by Studio on 2016. 7. 3..
//  Copyright © 2016년 jangsy7883. All rights reserved.
//

#import "ContentViewController.h"

@implementation ContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];    
    self.contentLabel.text = [@(_contentIndex) stringValue];
}

@end

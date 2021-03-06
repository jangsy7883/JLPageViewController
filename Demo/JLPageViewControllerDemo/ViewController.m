//
//  ViewController.m
//  JLPageViewControllerDemo
//
//  Created by Studio on 2016. 7. 3..
//  Copyright © 2016년 jangsy7883. All rights reserved.
//

#import "ViewController.h"
#import "ContentViewController.h"
#import "JLPageViewController.h"

@interface ViewController ()<JLPageViewControllerDataSource,JLPageViewControllerDelegate>

@property (nonatomic, weak) JLPageViewController * pageViewController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];    
    self.title = @"JLPageViewController";
}

#pragma mark - ContentView

- (ContentViewController*)contentViewControllerForIndex:(NSInteger)index {
    ContentViewController *contentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ContentViewController"];
    contentViewController.contentIndex = index;

    return contentViewController;
}

#pragma mark - EVENT

- (IBAction)preseedPrevButton:(id)sender {
    NSInteger index = self.pageViewController.currentIndex - 1;
    [self.pageViewController setCurrentIndex:index animated:YES];
}

- (IBAction)preseedNextButton:(id)sender {
    NSInteger index = self.pageViewController.currentIndex + 1;
    [self.pageViewController setCurrentIndex:index animated:YES];
}

#pragma mark - JLPageViewControllerDataSource

- (UIViewController*)pageViewController:(JLPageViewController *)pageViewController viewControllerForIndex:(NSInteger)index {
    return [self contentViewControllerForIndex:index];
}

- (NSInteger)defaultPageIndexForPageViewController:(JLPageViewController *)pageViewController {
    return 10;
}

#pragma mark - JLPageViewControllerDelegate

- (void)pageViewController:(JLPageViewController*)viewController didScrollToCurrentPosition:(CGFloat)currentPosition {
//    NSLog(@"_%f",currentPosition);
}

- (void)pageViewController:(JLPageViewController *)pageViewController didChangeToCurrentIndex:(NSInteger)index fromIndex:(NSUInteger)fromIndex {
//    NSLog(@"%lu -> %ld(%zd)",(unsigned long)fromIndex,(long)index,[pageViewController indexPathForPageContainingViewController:pageViewController.currentViewController]);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[JLPageViewController class]] && self.pageViewController == nil) {
        self.pageViewController = segue.destinationViewController;
        self.pageViewController.delegate = self;
        self.pageViewController.dataSource = self;
    }
}

@end

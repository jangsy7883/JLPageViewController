//
//  JLPageViewController.h
//  JLPageViewControllerDemo
//
//  Created by Studio on 2016. 7. 3..
//  Copyright © 2016년 jangsy7883. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (JLPageViewController)

@property (nonatomic, assign) NSUInteger pageIndex;

@end

@class JLPageViewController;

@protocol JLPageViewControllerDelegate <NSObject>

- (void)pageViewController:(JLPageViewController*)viewController didScrollToCurrentPosition:(CGFloat)currentPosition;
- (void)pageViewController:(JLPageViewController *)pageViewController didChangeToCurrentIndex:(NSInteger)index fromIndex:(NSUInteger)fromIndex;

@end

@protocol JLPageViewControllerDataSource <NSObject>

- (UIViewController *)pageViewController:(JLPageViewController *)pageViewController viewControllerForIndex:(NSInteger)index;

@end

@interface JLPageViewController : UIViewController

@property (nonatomic, assign) NSUInteger currentIndex;
@property (nonatomic, weak) id<JLPageViewControllerDataSource> dataSource;
@property (nonatomic, weak) id<JLPageViewControllerDelegate> delegate;

@end

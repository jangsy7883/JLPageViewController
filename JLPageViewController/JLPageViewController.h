//
//  JLPageViewController.h
//  JLPageViewControllerDemo
//
//  Created by Studio on 2016. 7. 3..
//  Copyright © 2016년 jangsy7883. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JLPageViewController;

@protocol JLPageViewControllerDelegate <NSObject>

@optional
- (void)pageViewController:(JLPageViewController *)pageViewController didScrollToCurrentPosition:(CGFloat)currentPosition;
- (void)pageViewController:(JLPageViewController *)pageViewController didChangeToCurrentIndex:(NSInteger)index fromIndex:(NSUInteger)fromIndex;

@end

@protocol JLPageViewControllerDataSource <NSObject>

@required
- (UIViewController *)pageViewController:(JLPageViewController *)pageViewController viewControllerForIndex:(NSInteger)index;

@optional
- (NSInteger)defaultPageIndexForPageViewController:(JLPageViewController *)pageViewController;

@end

@interface JLPageViewController : UIViewController

@property (nonatomic, readonly) UIScrollView *scrollView;

@property (nonatomic, assign) NSUInteger currentIndex;
@property (nonatomic, readonly) UIViewController* currentViewController;

@property (nonatomic, weak) id<JLPageViewControllerDataSource> dataSource;
@property (nonatomic, weak) id<JLPageViewControllerDelegate> delegate;

- (void)setCurrentIndex:(NSUInteger)currentIndex animated:(BOOL)animated;
- (void)reloadData;

@end

@interface UIViewController (JLPageViewController)
@property (nonatomic, readonly) NSUInteger pageIndex;
@end

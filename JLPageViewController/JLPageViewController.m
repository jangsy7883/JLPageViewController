//
//  JLPageViewController.m
//  JLPageViewControllerDemo
//
//  Created by Studio on 2016. 7. 3..
//  Copyright © 2016년 jangsy7883. All rights reserved.
//

#import "JLPageViewController.h"
#import <objc/runtime.h>

static void * PageIndexPropertyKey = &PageIndexPropertyKey;

@implementation UIViewController (JLPageViewController)


- (NSUInteger)pageIndex
{
    id obj = objc_getAssociatedObject(self, PageIndexPropertyKey);
    
    if ([obj isKindOfClass:[NSNumber class]])
    {
        return [obj unsignedIntegerValue];
    }
    return NSNotFound;
}

- (void)setPageIndex:(NSUInteger)pageIndex
{
    NSNumber *num = @(pageIndex);
    
    objc_setAssociatedObject(self, PageIndexPropertyKey, num, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface JLPageViewController ()<UIPageViewControllerDataSource,UIPageViewControllerDelegate,UIScrollViewDelegate>

@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic, weak) UIScrollView *scrollView;

@property (nonatomic, assign) BOOL transitionInProgress;
@property (nonatomic, assign) NSUInteger nextIndex;

@end

@implementation JLPageViewController

#pragma mark - init

- (void)baseInit
{
    _transitionInProgress = NO;
    _currentIndex = NSNotFound;
    _nextIndex = NSNotFound;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self baseInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self baseInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self baseInit];
    }
    return self;
}

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:nil];
    
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    
    if (self.currentIndex != NSNotFound)
    {
        NSInteger index = _currentIndex;
        _currentIndex = NSNotFound;
        self.currentIndex = index;
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.pageViewController.view.frame = self.view.bounds;
}

#pragma mark - pageviewcontrolelr data source

- (UIViewController*)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSInteger index = (viewController.pageIndex == NSNotFound) ? 0 : viewController.pageIndex+1;
    UIViewController *afterViewController = nil;
    
    if (index >= 0)
    {
        if ([self.dataSource respondsToSelector:@selector(pageViewController:viewControllerForIndex:)])
        {
            afterViewController = [self.dataSource pageViewController:self viewControllerForIndex:index];
            afterViewController.pageIndex = index;
        }
    }
    
    return afterViewController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSInteger index = (viewController.pageIndex == NSNotFound) ? 0 : viewController.pageIndex-1;
    UIViewController *beforeViewController = nil;
    
    if (index >= 0)
    {
        if ([self.dataSource respondsToSelector:@selector(pageViewController:viewControllerForIndex:)])
        {
            beforeViewController = [self.dataSource pageViewController:self viewControllerForIndex:index];
            beforeViewController.pageIndex = index;
        }
    }
    
    return beforeViewController;
}

#pragma  mark - pageviewcontroller delegate

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    _transitionInProgress = YES;
    
    UIViewController *viewController = pendingViewControllers.firstObject;
    
    _nextIndex = viewController.pageIndex;
}

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers
       transitionCompleted:(BOOL)completed
{
    if (completed)
    {
        NSUInteger fromIndex = _currentIndex;
     
        _currentIndex = [self indexForViewController:pageViewController.viewControllers.firstObject];
        
        if (_currentIndex != NSNotFound)
        {
            if ([self.delegate respondsToSelector:@selector(pageViewController:didChangeToCurrentIndex:fromIndex:)])
            {
                [self.delegate pageViewController:self didChangeToCurrentIndex:self.currentIndex fromIndex:fromIndex];
            }
        }
    }
    
    _transitionInProgress = NO;
}

#pragma mark - scrollview delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(pageViewController:didScrollToCurrentPosition:)] )
    {
        NSUInteger nextIndex = _nextIndex;
        NSUInteger index = (_currentIndex == NSNotFound) ? 0 : _currentIndex;
        CGFloat offsetX = scrollView.contentOffset.x;
        CGFloat width = scrollView.frame.size.width;
        CGFloat position = 0;
        CGFloat percent = fabs(offsetX - width)/width;
        
        if (index < nextIndex)
        {
            position = ((nextIndex - index) * percent) + index;
        }
        else if (index > nextIndex)
        {
            position = ((index - nextIndex) * (1-percent)) + nextIndex;
        }
        else
        {
            position = index;
        }
        
        [self.delegate pageViewController:self didScrollToCurrentPosition:position];
    }
}

#pragma mark - view controller

- (NSInteger)indexForViewController:(UIViewController*)viewController
{
    return viewController.pageIndex;
}
//
- (UIViewController*)viewControllerForIndex:(NSInteger)index
{
    UIViewController *viewController = nil;
    
    if ([self.dataSource respondsToSelector:@selector(pageViewController:viewControllerForIndex:)])
    {
        viewController = [self.dataSource pageViewController:self viewControllerForIndex:index];
    }
    
    viewController.pageIndex = index;
    
    return viewController;
}

#pragma mark - SETTERS

- (void)setCurrentIndex:(NSUInteger)currentIndex
{
    [self setCurrentIndex:currentIndex animated:NO];
}

- (void)setCurrentIndex:(NSUInteger)currentIndex animated:(BOOL)animated
{
    if (_currentIndex != currentIndex && _transitionInProgress == NO)
    {
        if (self.pageViewController == nil)
        {
            _currentIndex = currentIndex;
        }
        else
        {
            UIViewController *viewController = [self viewControllerForIndex:currentIndex];
            
            if (viewController && [self.pageViewController.viewControllers.firstObject isEqual:viewController] == NO)
            {
                _nextIndex = currentIndex;
                
                __weak JLPageViewController *blocksafeSelf = self;
                UIPageViewControllerNavigationDirection direction = currentIndex > self.currentIndex ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
                NSArray *viewControllers = self.pageViewController.viewControllers;
                
                [self.pageViewController setViewControllers:@[viewController]
                                                  direction:direction
                                                   animated:animated
                                                 completion:^(BOOL finished)
                 {
                     if (finished)
                     {
                         [blocksafeSelf pageViewController:blocksafeSelf.pageViewController
                                        didFinishAnimating:animated
                                   previousViewControllers:viewControllers
                                       transitionCompleted:YES];
                         
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [blocksafeSelf.pageViewController setViewControllers:@[viewController]
                                                                        direction:direction
                                                                         animated:NO
                                                                       completion:nil];
                         });
                     }
                 }];
            }
        }
    }
}

#pragma mark - GETTERS

- (UIScrollView *)scrollView
{
    if (!_scrollView)
    {
        for (UIView *subview in self.pageViewController.view.subviews)
        {
            if ([subview isKindOfClass:[UIScrollView class]]) {
                _scrollView = (UIScrollView *)subview;
                break;
            }
        }
    }
    return _scrollView;
}

@end
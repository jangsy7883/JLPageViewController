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

@interface UIViewController (JLPageViewController)

@property (nonatomic, readonly) NSUInteger jl_pageIndex;

@end

@implementation UIViewController (JLPageViewController)

- (NSUInteger)jl_pageIndex {    id obj = objc_getAssociatedObject(self, PageIndexPropertyKey);
    
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj unsignedIntegerValue];
    }
    return NSNotFound;
}

- (void)setJl_pageIndex:(NSUInteger)pageIndex {
    NSNumber *num = @(pageIndex);
    objc_setAssociatedObject(self, PageIndexPropertyKey, num, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@interface JLCustomPageViewController : UIPageViewController

@end

@implementation JLCustomPageViewController

- (void)setViewControllers:(NSArray*)viewControllers
                 direction:(UIPageViewControllerNavigationDirection)direction
                  animated:(BOOL)animated
                completion:(void (^)(BOOL))completion {
    if (animated) {
        [super setViewControllers:viewControllers direction:direction animated:YES completion:^(BOOL finished) {
            if (finished) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [super setViewControllers:viewControllers direction:direction animated:NO completion:completion];
                });
            }
            else {
                if (completion != NULL) {
                    completion(finished);
                }
            }
        }];
    }
    else {
        [super setViewControllers:viewControllers direction:direction animated:NO completion:completion];
    }
}

@end

@interface JLPageViewController ()<UIPageViewControllerDataSource,UIPageViewControllerDelegate,UIScrollViewDelegate>

@property (nonatomic, strong) JLCustomPageViewController *pageViewController;

@property (nonatomic, assign) BOOL transitionInProgress;
@property (nonatomic, assign) NSUInteger nextIndex;

@end

@implementation JLPageViewController

#pragma mark - dealloc

- (void)dealloc {
    [self removeObservers];
}

#pragma mark - init

- (void)baseInit {
    _transitionInProgress = NO;
    _currentIndex = NSNotFound;
    _nextIndex = NSNotFound;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self baseInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self baseInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self baseInit];
    }
    return self;
}

#pragma mark - view lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //PAGE VIEW CONTROLLER
    self.pageViewController = [[JLCustomPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                    navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                  options:nil];
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    
    //SCROLL VIEW
    self.scrollView.scrollsToTop = NO;
    [self addObservers];
    
    //RELOAD DATA
    [self reloadData];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.pageViewController.view.frame = self.view.bounds;
}

#pragma mark - RELOAD

- (void)reloadData {
    NSUInteger index = _currentIndex;
    
    if (_currentIndex == NSNotFound) {
        if ([self.dataSource respondsToSelector:@selector(defaultPageIndexForPageViewController:)]) {
            index = [self.dataSource defaultPageIndexForPageViewController:self];
        }
        else {
            index = 0;
        }
    }
    
    _currentIndex = NSNotFound;
    self.currentIndex = index;
}

#pragma mark - observer

- (void)addObservers {
    @try {
        [self.scrollView addObserver:self
                          forKeyPath:NSStringFromSelector(@selector(contentOffset))
                             options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
                             context:nil];
    }
    @catch (NSException *exception) {};
}

- (void)removeObservers {
    @try {
        [self.scrollView removeObserver:self
                             forKeyPath:NSStringFromSelector(@selector(contentOffset))
                                context:nil];
    }
    @catch (NSException *exception) {};
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[UIScrollView class]]
        && [keyPath isEqualToString:NSStringFromSelector(@selector(contentOffset))]) {
        CGPoint new = [change[NSKeyValueChangeNewKey] CGPointValue];
        CGPoint old = [change[NSKeyValueChangeOldKey] CGPointValue];
        
        if (CGPointEqualToPoint(new, old) == NO) {
            [self scrollViewDidScroll:object];
        }
    }
}

#pragma mark - PageViewController DataSource

- (UIViewController*)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSInteger index = (viewController.jl_pageIndex == NSNotFound) ? 0 : viewController.jl_pageIndex+1;
    UIViewController *afterViewController = nil;
    
    if (index >= 0) {
        afterViewController = [self viewControllerForIndex:index];
    }
    
    return afterViewController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSInteger index = (viewController.jl_pageIndex == NSNotFound) ? 0 : viewController.jl_pageIndex-1;
    UIViewController *beforeViewController = nil;
    
    if (index >= 0) {
        beforeViewController = [self viewControllerForIndex:index];
    }
    
    return beforeViewController;
}

#pragma  mark - PageViewController Delegate

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    _transitionInProgress = YES;
    
    UIViewController *viewController = pendingViewControllers.firstObject;
    _nextIndex = viewController.jl_pageIndex;
}

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers
       transitionCompleted:(BOOL)completed {
    if (completed) {
        [self didFinishTransition];
    }
    
    _nextIndex = _currentIndex;
    _transitionInProgress = NO;
}

- (void)didFinishTransition {
    NSUInteger fromIndex = _currentIndex;

    _currentIndex = [self indexPathForPageContainingViewController:self.pageViewController.viewControllers.firstObject];
    
    for (UIViewController *viewController in self.pageViewController.childViewControllers) {
        UIScrollView *scrollView = [self scrollViewForContainingViewController:viewController];
        
        if (scrollView) {
            scrollView.scrollsToTop = (_currentIndex == viewController.jl_pageIndex);
        }
    }
    
    if (_currentIndex != NSNotFound
        && [self.delegate respondsToSelector:@selector(pageViewController:didChangeToCurrentIndex:fromIndex:)]) {
        [self.delegate pageViewController:self didChangeToCurrentIndex:self.currentIndex fromIndex:fromIndex];
    }

    _transitionInProgress = NO;
}

#pragma mark - ScrollView

- (UIScrollView*)scrollViewForContainingViewController:(UIViewController*)viewController {
    if ([viewController.view isKindOfClass:[UIScrollView class]]) {
        return (UIScrollView*)viewController.view;
    }
    
    for (UIScrollView* scrollView in viewController.view.subviews) {
        if ([scrollView isKindOfClass:[UIScrollView class]]) {
            return scrollView;
        }
    }
    return nil;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(pageViewController:didScrollToCurrentPosition:)] ) {
        NSUInteger nextIndex = _nextIndex;
        NSUInteger index = (_currentIndex == NSNotFound) ? 0 : _currentIndex;
        CGFloat offsetX = scrollView.contentOffset.x;
        CGFloat width = scrollView.frame.size.width;
        CGFloat position = 0;
        CGFloat percent = fabs(offsetX - width)/width;
        
        if (percent == 0)
        {
            position = _transitionInProgress ? index : nextIndex;
        }
        else if (index < nextIndex)
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

#pragma mark - VIEWCONTROLLER

- (NSUInteger)indexPathForPageContainingViewController:(UIViewController*)viewController {
    return viewController.jl_pageIndex;
}

- (UIViewController*)viewControllerForIndex:(NSInteger)index {
    UIViewController *viewController = nil;
    if ([self.dataSource respondsToSelector:@selector(pageViewController:viewControllerForIndex:)]) {
        viewController = [self.dataSource pageViewController:self viewControllerForIndex:index];
    }
    
    viewController.jl_pageIndex = index;
    
    return viewController;
}

#pragma mark - SETTERS

- (void)setCurrentIndex:(NSUInteger)currentIndex {
    [self setCurrentIndex:currentIndex animated:NO];
}

- (void)setCurrentIndex:(NSUInteger)currentIndex animated:(BOOL)animated {
    if (_currentIndex != currentIndex && _transitionInProgress == NO) {
        if (self.pageViewController == nil) {
            _currentIndex = currentIndex;
        }
        else {
            UIViewController *viewController = [self viewControllerForIndex:currentIndex];
            
            if (viewController) {// && [self.pageViewController.viewControllers.firstObject isEqual:viewController] == NO)
                _nextIndex = currentIndex;
                
                __weak JLPageViewController *blocksafeSelf = self;
                UIPageViewControllerNavigationDirection direction = currentIndex > _currentIndex ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
                
                [self.pageViewController setViewControllers:@[viewController]
                                                  direction:direction
                                                   animated:animated
                                                 completion:^(BOOL finished) {
                                                     if (finished) {
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             [blocksafeSelf didFinishTransition];
                                                         });                                                         
                                                     }
                                                 }];
                /*
                [self.pageViewController setViewControllers:@[viewController]
                                                  direction:direction
                                                   animated:animated
                                                 completion:^(BOOL finished)
                 {
                     if (finished)
                     {
                         [blocksafeSelf didFinishTransition];
                         
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [blocksafeSelf.pageViewController setViewControllers:@[viewController]
                                                                        direction:direction
                                                                         animated:NO
                                                                       completion:nil];
                         });
                     }
                 }];
                 */
            }
        }
    }
}

#pragma mark - GETTERS

- (NSArray<UIViewController*>*)viewControllers {
    return self.pageViewController.childViewControllers;
}

- (UIViewController*)currentViewController {
    for (UIViewController*viewController in self.pageViewController.childViewControllers) {
        if (viewController.jl_pageIndex == _currentIndex) {
            return viewController;
        }
    }
    return nil;
}

- (UIScrollView *)scrollView {
    for (UIView *subview in self.pageViewController.view.subviews) {
        if ([subview isKindOfClass:[UIScrollView class]]){
            return (UIScrollView *)subview;
        }
    }
    return nil;
}

@end

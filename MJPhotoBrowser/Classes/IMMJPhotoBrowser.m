//
//  IMMJPhotoBrowser.m
//
//  Created by mj on 13-3-4.
//  Copyright (c) 2013年 itcast. All rights reserved.

#import "IMMJPhotoBrowser.h"

#import "IMMJPhotoToolbar.h"
#import "IMMJPhotoView.h"

#define kPadding 10
#define kPhotoViewTagOffset 1000
#define kPhotoViewIndex(photoView) ([photoView tag] - kPhotoViewTagOffset)

@interface IMMJPhotoBrowser () <IMMJPhotoViewDelegate>

@property (strong, nonatomic) UIView *view;
@property (strong, nonatomic) UIScrollView *photoScrollView;
@property (strong, nonatomic) NSMutableSet *visiblePhotoViews, *reusablePhotoViews;
@property (strong, nonatomic) IMMJPhotoToolbar *toolbar;

@end

@implementation IMMJPhotoBrowser


#pragma mark - init M
- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}


#pragma mark - get M
- (UIView *)view {
    if (!_view) {
        CGRect rect = [UIApplication sharedApplication].keyWindow.bounds;
        _view = [[UIView alloc] initWithFrame:CGRectMake(0.0, rect.size.height, rect.size.width, rect.size.height)];
        _view.backgroundColor = [UIColor blackColor];
    }
    return _view;
}

- (UIScrollView *)photoScrollView {
    if (!_photoScrollView) {
        CGRect frame = self.view.bounds;
        frame.origin.x -= kPadding;
        frame.size.width += (2 * kPadding);
        _photoScrollView = [[UIScrollView alloc] initWithFrame:frame];
        _photoScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _photoScrollView.pagingEnabled = YES;
        _photoScrollView.delegate = self;
        _photoScrollView.showsHorizontalScrollIndicator = NO;
        _photoScrollView.showsVerticalScrollIndicator = NO;
        _photoScrollView.backgroundColor = [UIColor clearColor];
    }
    return _photoScrollView;
}

- (IMMJPhotoToolbar *)toolbar {
    if (!_toolbar) {
        CGFloat barHeight = 49;
        CGFloat barY = self.view.frame.size.height - barHeight;
        _toolbar = [[IMMJPhotoToolbar alloc] init];
        _toolbar.frame = CGRectMake(0, barY, self.view.frame.size.width, barHeight);
        _toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    }
    return _toolbar;
}

- (void)show {
    [[UIApplication sharedApplication].keyWindow endEditing:YES];

    // 初始化数据
    {
        if (!_visiblePhotoViews) {
            _visiblePhotoViews = [NSMutableSet set];
        }
        if (!_reusablePhotoViews) {
            _reusablePhotoViews = [NSMutableSet set];
        }
        self.toolbar.photos = self.photos;


        CGRect frame = self.view.bounds;
        frame.origin.x -= kPadding;
        frame.size.width += (2 * kPadding);
        self.photoScrollView.contentSize = CGSizeMake(frame.size.width * self.photos.count, 0);
        self.photoScrollView.contentOffset = CGPointMake(self.currentPhotoIndex * frame.size.width, 0);

        [self.view addSubview:self.photoScrollView];
        [self.view addSubview:self.toolbar];
        [self updateTollbarState];
        [self showPhotos];
    }

    [[UIApplication sharedApplication].keyWindow addSubview:self.view];
    [UIView animateWithDuration:0.3f
        animations:^{
            CGRect frame = self.view.frame;
            frame.origin.y = 0.f;
            [self.view setFrame:frame];
        }
        completion:^(BOOL finished) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        }];
}


#pragma mark - set M
- (void)setPhotos:(NSArray *)photos {
    _photos = photos;
    if (_photos.count <= 0) {
        return;
    }
    for (int i = 0; i < _photos.count; i++) {
        IMMJPhoto *photo = _photos[i];
        photo.index = i;
    }
}

- (void)setCurrentPhotoIndex:(NSUInteger)currentPhotoIndex {
    _currentPhotoIndex = currentPhotoIndex;

    if (_photoScrollView) {
        _photoScrollView.contentOffset = CGPointMake(_currentPhotoIndex * _photoScrollView.frame.size.width, 0);

        // 显示所有的相片
        [self showPhotos];
    }
}


#pragma mark - Show Photos
- (void)showPhotos {
    CGRect visibleBounds = _photoScrollView.bounds;
    int firstIndex = (int)floorf((CGRectGetMinX(visibleBounds) + kPadding * 2) / CGRectGetWidth(visibleBounds));
    int lastIndex = (int)floorf((CGRectGetMaxX(visibleBounds) - kPadding * 2 - 1) / CGRectGetWidth(visibleBounds));
    if (firstIndex < 0) firstIndex = 0;
    if (firstIndex >= _photos.count) firstIndex = (int)_photos.count - 1;
    if (lastIndex < 0) lastIndex = 0;
    if (lastIndex >= _photos.count) lastIndex = (int)_photos.count - 1;

    // 回收不再显示的ImageView
    NSInteger photoViewIndex;
    for (IMMJPhotoView *photoView in _visiblePhotoViews) {
        photoViewIndex = kPhotoViewIndex(photoView);
        if (photoViewIndex < firstIndex || photoViewIndex > lastIndex) {
            [_reusablePhotoViews addObject:photoView];
            [photoView removeFromSuperview];
        }
    }

    [_visiblePhotoViews minusSet:_reusablePhotoViews];
    while (_reusablePhotoViews.count > 2) {
        [_reusablePhotoViews removeObject:[_reusablePhotoViews anyObject]];
    }

    for (NSUInteger index = firstIndex; index <= lastIndex; index++) {
        if (![self isShowingPhotoViewAtIndex:index]) {
            [self showPhotoViewAtIndex:(int)index];
        }
    }
}

/**
 *  显示一个图片view
 *
 *  @param index <#index description#>
 */
- (void)showPhotoViewAtIndex:(int)index {
    IMMJPhotoView *photoView = [self dequeueReusablePhotoView];
    if (!photoView) {
        // 添加新的图片view
        photoView = [[IMMJPhotoView alloc] init];
        photoView.photoViewDelegate = self;
    }

    // 调整当前页的frame
    CGRect bounds = _photoScrollView.bounds;
    CGRect photoViewFrame = bounds;
    photoViewFrame.size.width -= (2 * kPadding);
    photoViewFrame.origin.x = (bounds.size.width * index) + kPadding;
    photoView.tag = kPhotoViewTagOffset + index;

    IMMJPhoto *photo = _photos[index];
    photoView.frame = photoViewFrame;
    photoView.photo = photo;

    [_visiblePhotoViews addObject:photoView];
    [_photoScrollView addSubview:photoView];
}

/**
 *  index这页是否正在显示
 *
 *  @param index <#index description#>
 *
 *  @return <#return value description#>
 */
- (BOOL)isShowingPhotoViewAtIndex:(NSUInteger)index {
    for (IMMJPhotoView *photoView in _visiblePhotoViews) {
        if (kPhotoViewIndex(photoView) == index) {
            return YES;
        }
    }
    return NO;
}

/**
 *  重用页面
 *
 *  @return <#return value description#>
 */
- (IMMJPhotoView *)dequeueReusablePhotoView {
    IMMJPhotoView *photoView = [_reusablePhotoViews anyObject];
    if (photoView) {
        [_reusablePhotoViews removeObject:photoView];
    }
    return photoView;
}


#pragma mark - updateTollbarState
- (void)updateTollbarState {
    _currentPhotoIndex = _photoScrollView.contentOffset.x / _photoScrollView.frame.size.width;
    _toolbar.currentPhotoIndex = _currentPhotoIndex;
}


#pragma mark - MJPhotoViewDelegate
- (void)photoViewSingleTap:(IMMJPhotoView *)photoView {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    // 移除工具条
    [self.toolbar removeFromSuperview];

    [UIView animateWithDuration:0.3f
        animations:^{
            CGRect frame = self.view.frame;
            frame.origin.y = self.view.frame.size.height;
            [self.view setFrame:frame];
        }
        completion:^(BOOL finished) {
            [self.view removeFromSuperview];

            if (self.dismiss) {
                self.dismiss();
            }
        }];
}

- (void)photoViewImageFinishLoad:(IMMJPhotoView *)photoView {
    [self updateTollbarState];
}


#pragma mark - UIScrollView Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self showPhotos];
    [self updateTollbarState];
}

@end
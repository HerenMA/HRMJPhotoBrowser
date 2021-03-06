//
//  MJPhotoLoadingView.m
//
//  Created by mj on 13-3-4.
//  Copyright (c) 2013年 itcast. All rights reserved.
//

#import "MJPhotoLoadingView.h"

#import "MJPhotoBrowser.h"
#import <QuartzCore/QuartzCore.h>

@interface MJPhotoLoadingView ()
{
    UIActivityIndicatorView *_progressView;
}

@end

@implementation MJPhotoLoadingView

- (void)setFrame:(CGRect)frame {
    [super setFrame:[UIScreen mainScreen].bounds];
}

- (void)showFailure {
    [_progressView stopAnimating];
}

- (void)showLoading {
    if (_progressView == nil) {
        _progressView = [[UIActivityIndicatorView alloc] init];
        _progressView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        _progressView.bounds = CGRectMake(0.0, 0.0, 60.0, 60.0);
        _progressView.center = self.center;
    }
    [self addSubview:_progressView];
    
    [_progressView startAnimating];
}

@end

//
//  IntroView.m
//  DrawPad
//
//  Created by Adam Cooper on 2/4/15.
//  Copyright (c) 2015 Adam Cooper. All rights reserved.
//

#import "ABCIntroView.h"


@interface ABCIntroView () <UIScrollViewDelegate>
@property (strong, nonatomic)  UIScrollView *scrollView;
@property (strong, nonatomic)  UIPageControl *pageControl;
@property UIView *holeView;
@property UIView *circleView;
@property UIButton *doneButton;

@end

@implementation ABCIntroView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:self.frame];
        self.scrollView.pagingEnabled = YES;
        [self addSubview:self.scrollView];
        
        self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, self.frame.size.height*.9, self.frame.size.width, 20)];
        self.pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:207.0f/255.0f green:76.0f/255.0f blue:40.0f/255.0f alpha:1.000];
        [self addSubview:self.pageControl];
    
        [self createViewOne];
        [self createViewTwo];
        [self createViewThree];
        [self createViewFour];
        
        
        
            
        
        self.pageControl.numberOfPages = 4;
        self.scrollView.contentSize = CGSizeMake(self.frame.size.width*4, self.scrollView.frame.size.height);
        
        //This is the starting point of the ScrollView
        CGPoint scrollPoint = CGPointMake(0, 0);
        [self.scrollView setContentOffset:scrollPoint animated:YES];
    }
    return self;
}

-(NSString*)GetImageName:(NSString*)ScreenNumber{
    
    if(isiPhone)
    {
        if (isiPhone4)
            return [NSString stringWithFormat:@"4i%@.png",ScreenNumber];
        else if (isiPhone5)
            return [NSString stringWithFormat:@"5i%@.png",ScreenNumber];
        else if (isiPhone6)
            return [NSString stringWithFormat:@"6i%@.png",ScreenNumber];
        else if (isiPhone6Plus)
            return [NSString stringWithFormat:@"6+i%@.png",ScreenNumber];
    }
    else
    {
        //[ipad]
        return [NSString stringWithFormat:@"6+i%@.png",ScreenNumber];
    }
    
    return @"";
}

- (void)onFinishedIntroButtonPressed:(id)sender {
    [self.delegate onDoneButtonPressed];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat pageWidth = CGRectGetWidth(self.bounds);
    CGFloat pageFraction = self.scrollView.contentOffset.x / pageWidth;
    self.pageControl.currentPage = roundf(pageFraction);
    
}

-(UIImageView*)GetImageView{
return [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    //return [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width*.07, self.frame.size.height*.07, self.frame.size.width*.85, self.frame.size.height*.8)];
}

-(void)createViewOne{
    
    UIView *view = [[UIView alloc] initWithFrame:self.frame];
    
    
    UIImageView *imageview = [self GetImageView];
    imageview.contentMode = UIViewContentModeScaleAspectFit;
    imageview.image = [UIImage imageNamed:[self GetImageName:@"1"]];
    [view addSubview:imageview];
    
    self.scrollView.delegate = self;
    [self.scrollView addSubview:view];
    
}


-(void)createViewTwo{
    
    CGFloat originWidth = self.frame.size.width;
    CGFloat originHeight = self.frame.size.height;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(originWidth, 0, originWidth, originHeight)];
    
   
    
     UIImageView *imageview = [self GetImageView];
    imageview.contentMode = UIViewContentModeScaleAspectFit;
    imageview.image = [UIImage imageNamed:[self GetImageName:@"2"]];
    [view addSubview:imageview];
    
    self.scrollView.delegate = self;
    [self.scrollView addSubview:view];
    
}

-(void)createViewThree{
    
    CGFloat originWidth = self.frame.size.width;
    CGFloat originHeight = self.frame.size.height;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(originWidth*2, 0, originWidth, originHeight)];
    
    UIImageView *imageview = [self GetImageView];
  
    imageview.contentMode = UIViewContentModeScaleAspectFit;
    imageview.image = [UIImage imageNamed:[self GetImageName:@"3"]];
    [view addSubview:imageview];
    
    self.scrollView.delegate = self;
    [self.scrollView addSubview:view];
    
}


-(void)createViewFour{
    
    CGFloat originWidth = self.frame.size.width;
    CGFloat originHeight = self.frame.size.height;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(originWidth*3, 0, originWidth, originHeight)];
    
    
     UIImageView *imageview = [self GetImageView];
    
    imageview.contentMode = UIViewContentModeScaleAspectFit;
    imageview.image = [UIImage imageNamed:[self GetImageName:@"4"]];
    [view addSubview:imageview];
    
    //Done Button
    
    self.doneButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width*.65, self.frame.size.height*.84, 100, 40)];
    [self.doneButton setTintColor:[UIColor whiteColor]];
    [self.doneButton setTitle:@"Let's Go!" forState:UIControlStateNormal];
    [self.doneButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:16.0]];
    self.doneButton.backgroundColor = [UIColor colorWithRed:0.811 green:0.298 blue:0.156 alpha:1.000];
    self.doneButton.layer.borderColor = [UIColor colorWithRed:0.811 green:0.298 blue:0.156 alpha:1.000].CGColor;
    [self.doneButton addTarget:self action:@selector(onFinishedIntroButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.doneButton.layer.borderWidth =.5;
    self.doneButton.layer.cornerRadius = 5;
    [view addSubview:self.doneButton];
    
    self.scrollView.delegate = self;
    [self.scrollView addSubview:view];
    
}

@end
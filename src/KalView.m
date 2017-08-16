/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalView.h"
#import "KalGridView.h"
#import "KalLogic.h"
#import "KalPrivate.h"
#import "KalDate.h"
#import "UtilityMethods.h"

static const CGFloat kHeaderHeight = 44.f;
//static const CGFloat kMonthLabelHeight = 17.f;

@interface KalView()
@property (nonatomic,strong) NSCalendar *calendar;
@end

@implementation KalView

- (void)finalizeInit
{
    BOOL isTablet = isIpadDevice();

    if (!_calendar)
        _calendar = [NSCalendar autoupdatingCurrentCalendar];

	[[KalLogic sharedLogic] addObserver:self forKeyPath:@"selectedMonthNameAndYear" options:NSKeyValueObservingOptionNew context:NULL];
	self.autoresizesSubviews = YES;

    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    CGRect containerRect = (isTablet) ? CGRectMake(0, 0, 322, 309) : self.bounds;
    CGRect headerRect = CGRectZero;
    CGRect contentRect = CGRectZero;
    CGRectDivide(containerRect, &headerRect, &contentRect, kHeaderHeight, CGRectMinYEdge);

    UIView *headerView = [[UIView alloc] initWithFrame:headerRect];
    headerView.backgroundColor = [UIColor grayColor];

    UIView *contentView = [[UIView alloc] initWithFrame:contentRect];

    if (!isTablet)
    {
        headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }

    [self addSubviewsToHeaderView:headerView];
    [self addSubview:headerView];

    [self addSubviewsToContentView:contentView];
    [self addSubview:contentView];
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	if (!_delegate)
    {
		NSLog(@"KalView doesn't have a delegate!");
	}
	[self finalizeInit];
}	

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<KalViewDelegate>)theDelegate calendar:(NSCalendar *)calendar
{
    self = [super initWithFrame:frame];
	if (self)
    {
        _calendar = calendar;
		_delegate = theDelegate;
		[self finalizeInit];
	}
	
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	[NSException raise:@"Incomplete initializer" format:@"KalView must be initialized with a delegate. Use the initWithFrame:delegate method."];
	return self;
}

- (void)redrawEntireMonth
{
    [self jumpToSelectedMonth];
}

- (void)slideDown
{
    [_gridView slideDown];
}

- (void)slideUp
{
    [_gridView slideUp];
}

- (void)showPreviousMonth
{
	if (!_gridView.isTransitioning)
    {
        id<KalViewDelegate> delegate = self.delegate;
		if (delegate && [delegate respondsToSelector:@selector(showPreviousMonth)])
        {
			[delegate performSelector:@selector(showPreviousMonth)];
        }
	}
}

- (void)showFollowingMonth
{
	if (!_gridView.isTransitioning)
    {
        id<KalViewDelegate> delegate = self.delegate;
		if (delegate && [delegate respondsToSelector:@selector(showFollowingMonth)])
        {
			[delegate performSelector:@selector(showFollowingMonth)];
        }
    }
}

- (void)addSubviewsToHeaderView:(UIView *)theHeader
{
    UITraitCollection *traits = self.traitCollection;
    NSString *kalBundlePath = [[NSBundle mainBundle] pathForResource:@"Kal" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:kalBundlePath];
    NSAssert1(bundle != NULL, @"Must have a Kal.bundle of image assets.  No bundle found at: %@", kalBundlePath);

    CGRect headerBounds = theHeader.bounds;
	
	// Header background gradient
    UIImage *background = [UIImage imageNamed:@"kal_grid_background" inBundle:bundle compatibleWithTraitCollection:traits];
	UIImageView *backgroundView = [[UIImageView alloc] initWithImage:background];
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	backgroundView.frame = headerBounds;
	[theHeader addSubview:backgroundView];

	UIButton *previous = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *leftArrow = [UIImage imageNamed:@"kal_left_arrow" inBundle:bundle compatibleWithTraitCollection:traits];
	[previous setImage:leftArrow forState:UIControlStateNormal];
	previous.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	previous.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    previous.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
	[previous addTarget:self action:@selector(showPreviousMonth) forControlEvents:UIControlEventTouchUpInside];

    CGSize arrowSize = CGSizeMake(44, 30);
    CGRect leftButtonRect = CGRectMake(0, 3, arrowSize.width, arrowSize.height);
    previous.frame = leftButtonRect;
	[theHeader addSubview:previous];

    UIButton *next = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *rightArrow = [UIImage imageNamed:@"kal_right_arrow" inBundle:bundle compatibleWithTraitCollection:traits];
    [next setImage:rightArrow forState:UIControlStateNormal];
    next.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    next.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    next.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [next addTarget:self action:@selector(showFollowingMonth) forControlEvents:UIControlEventTouchUpInside];

    CGFloat offsetX = ceil(CGRectGetMaxX(headerBounds) - arrowSize.width);
    CGRect rightButtonRect = CGRectMake(offsetX, 3, arrowSize.width, arrowSize.height);
    next.frame = rightButtonRect;
    [theHeader addSubview:next];

    CGFloat labelWidth = floor(CGRectGetWidth(headerBounds) - (2.f * CGRectGetMaxX(leftButtonRect)));

	// Draw the selected month name centered and at the top of the view
    //UIFont *titleFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline compatibleWithTraitCollection:self.traitCollection];
    UIFont *titleFont = [UIFont boldSystemFontOfSize:18];
    CGFloat titleHeight = ceil(titleFont.lineHeight);

    CGFloat headerMidX = CGRectGetMidX(headerBounds);
    CGFloat headerMidY = CGRectGetMidY(headerBounds);
    CGRect labelRect = CGRectMake(headerMidX - floor(labelWidth/2.f),
                                  (headerMidY - floor(titleHeight/2.f)) - 3,
                                  labelWidth,
                                  titleHeight);
	//CGRect labelRect = CGRectMake(CGRectGetMaxX(leftButtonRect), 3, labelWidth, titleHeight);
	_headerTitleLabel = [[UILabel alloc] initWithFrame:labelRect];
    _headerTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_headerTitleLabel.backgroundColor = [UIColor clearColor];
	_headerTitleLabel.font = titleFont;
	_headerTitleLabel.textAlignment = NSTextAlignmentCenter;
//    _headerTitleLabel.center = theHeader.center;
 //   labelRect = CGRectIntegral(_headerTitleLabel.frame);
    _headerTitleLabel.frame = labelRect;

    UIImage *headerFill = [UIImage imageNamed:@"kal_header_text_fill" inBundle:bundle compatibleWithTraitCollection:traits];
    UIColor *headerTextColor = (headerFill) ? [UIColor colorWithPatternImage:headerFill] : [UIColor lightTextColor];
    _headerTitleLabel.textColor = headerTextColor;
    _headerTitleLabel.text = [[KalLogic sharedLogic] selectedMonthNameAndYear];
	[theHeader addSubview:_headerTitleLabel];

    NSCalendar *calendar = self.calendar;

    NSArray *weekdayNames = calendar.shortWeekdaySymbols;
    NSUInteger weekdayCount = weekdayNames.count;
	NSUInteger firstWeekday = [calendar firstWeekday];
	UInt8 i = (UInt8)firstWeekday - 1;
    UIFont *bold10 = [UIFont boldSystemFontOfSize:10.f];
    UIColor *textColor = [UIColor colorWithWhite:0.3f alpha:1.f];

    CGFloat yOffset = titleHeight + 3;
    CGFloat weekdayWidth = floor(CGRectGetWidth(headerBounds) / weekdayCount);
    CGRect weekdayFrame = CGRectMake(0, yOffset, weekdayWidth, ceil(kHeaderHeight - titleHeight));
    //CGRect oldFrame = CGRectMake(xOffset, 30.f, 46.f, kHeaderHeight - 29.f);

    for (SInt16 xOffset = 0.f; xOffset < CGRectGetWidth(headerBounds); xOffset += weekdayWidth, i = (i+1) % weekdayCount)
    {
        weekdayFrame.origin.x = xOffset;
		UILabel *dayLabel = [[UILabel alloc] initWithFrame:weekdayFrame];
		dayLabel.backgroundColor = [UIColor clearColor];
		dayLabel.font = bold10;
		dayLabel.textAlignment = NSTextAlignmentCenter;
        dayLabel.lineBreakMode = NSLineBreakByTruncatingTail;
		dayLabel.textColor = textColor;
		dayLabel.text = weekdayNames[i];
		[theHeader addSubview:dayLabel];
	}
}

- (void)addSubviewsToContentView:(UIView *)contentView
{
	// Both the tile grid and the list of events will automatically lay themselves
	// out to fit the # of weeks in the currently displayed month.
	// So the only part of the frame that we need to specify is the width.
	CGRect fullWidthFrame = CGRectZero;
    fullWidthFrame.size.width = CGRectGetWidth(contentView.bounds);

	// The tile grid (the calendar body)
	_gridView = [[KalGridView alloc] initWithFrame:fullWidthFrame delegate:self.delegate calendar:self.calendar];
    if (_gridView)
    {
        _gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        //[_gridView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
        [contentView addSubview:_gridView];
    }

	// The list of events for the selected day
	if (!self.tableView)
    {
		_tableView = [[UITableView alloc] initWithFrame:fullWidthFrame style:UITableViewStylePlain];
		_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[contentView addSubview:_tableView];
	}

	// Trigger the initial KVO update to finish the contentView layout
	[_gridView sizeToFit];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    if (!isIpadDevice())
    {
        KalGridView *gridView = self.gridView;
        UITableView *tableView = self.tableView;
        CGFloat gridBottom = gridView.top + gridView.height;
        CGRect frame = tableView.frame;
        frame.origin.y = gridBottom;
        frame.size.height = tableView.superview.height - gridBottom;
        tableView.frame = frame;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == self.gridView && [keyPath isEqualToString:@"frame"])
    {
		/* Animate tableView filling the remaining space after the
		 * gridView expanded or contracted to fit the # of weeks
		 * for the month that is being displayed.
		 *
		 * This observer method will be called when gridView's height
		 * changes, which we know to occur inside a Core Animation
		 * transaction. Hence, when I set the "frame" property on
		 * tableView here, I do not need to wrap it in a
		 * [UIView beginAnimations:context:].
		 */
		if (!isIpadDevice())
        {
			CGFloat gridBottom = _gridView.top + _gridView.height;
			CGRect frame = self.tableView.frame;
			frame.origin.y = gridBottom;
			frame.size.height = _tableView.superview.height - gridBottom;
			_tableView.frame = frame;
		}
	}
    else if ([keyPath isEqualToString:@"selectedMonthNameAndYear"])
    {
        NSString *text = [change objectForKey:NSKeyValueChangeNewKey];
        if (!text || ![text isKindOfClass:[NSString class]])
            text = @"";
        self.headerTitleLabel.text = text;
		//[self setHeaderTitleText:text];
		
	} else
    {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)jumpToSelectedMonth
{
    [self.gridView jumpToSelectedMonth];
}

- (void)selectDate:(KalDate *)date
{
    [self.gridView selectDate:date];
}

- (BOOL)isSliding
{
    return self.gridView.isTransitioning;
}

- (void)markTilesForDates:(NSArray<KalDate *> *)dates
{
    [self.gridView markTilesForDates:dates];
}

- (KalDate *)selectedDate
{
    return self.gridView.selectedDate;
}

- (void)dealloc
{
	[[KalLogic sharedLogic] removeObserver:self forKeyPath:@"selectedMonthNameAndYear"];
//    KalGridView *gridView = self.gridView;
//    if (gridView)
//        [gridView removeObserver:self forKeyPath:@"frame"];
}

@end

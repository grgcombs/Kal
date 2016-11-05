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
static const CGFloat kMonthLabelHeight = 17.f;

@implementation KalView

- (void)finalizeInit
{
	[[KalLogic sharedLogic] addObserver:self forKeyPath:@"selectedMonthNameAndYear" options:NSKeyValueObservingOptionNew context:NULL];
	self.autoresizesSubviews = YES;
    
	CGFloat frameWidth = 0.f;
	CGFloat frameHeight = 0.f;
	if (isIpadDevice()) {
		frameWidth = 322.f;
		frameHeight = 309.f;
	}
	else
    {
		frameWidth = self.frame.size.width;
		frameHeight = self.frame.size.height - kHeaderHeight;
		self.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	}
	UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, frameWidth, kHeaderHeight)];
	headerView.backgroundColor = [UIColor grayColor];
	[self addSubviewsToHeaderView:headerView];
	[self addSubview:headerView];
	
	UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0.f, kHeaderHeight, frameWidth, frameHeight)];
    if (![UtilityMethods isIPadDevice])
    {
        contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    }
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

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<KalViewDelegate>)theDelegate
{
	if ((self = [super initWithFrame:frame]))
    {
		_delegate = theDelegate;
		[self finalizeInit];
	}
	
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
	_delegate = nil;
	[NSException raise:@"Incomplete initializer" format:@"KalView must be initialized with a delegate. Use the initWithFrame:delegate method."];
	return nil;
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
	if (!_gridView.transitioning)
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
	if (!_gridView.transitioning)
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
	const CGFloat kChangeMonthButtonWidth = 46.0f;
	const CGFloat kChangeMonthButtonHeight = 30.0f;
	const CGFloat kMonthLabelWidth = 200.0f;
	const CGFloat kHeaderVerticalAdjust = 3.f;
	
	// Header background gradient
	UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Kal.bundle/kal_grid_background.png"]];
	CGRect imageFrame = theHeader.frame;
	imageFrame.origin = CGPointZero;
	backgroundView.frame = imageFrame;
	[theHeader addSubview:backgroundView];
	
	// Create the previous month button on the left side of the view
	CGRect previousMonthButtonFrame = CGRectMake(theHeader.left,
												 kHeaderVerticalAdjust,
												 kChangeMonthButtonWidth,
												 kChangeMonthButtonHeight);
	UIButton *previousMonthButton = [[UIButton alloc] initWithFrame:previousMonthButtonFrame];
	[previousMonthButton setImage:[UIImage imageNamed:@"Kal.bundle/kal_left_arrow.png"] forState:UIControlStateNormal];
	previousMonthButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	previousMonthButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	[previousMonthButton addTarget:self action:@selector(showPreviousMonth) forControlEvents:UIControlEventTouchUpInside];
	[theHeader addSubview:previousMonthButton];
	
	// Draw the selected month name centered and at the top of the view
	CGRect monthLabelFrame = CGRectMake((theHeader.width/2.0f) - (kMonthLabelWidth/2.0f),
										kHeaderVerticalAdjust,
										kMonthLabelWidth,
										kMonthLabelHeight);
	_headerTitleLabel = [[UILabel alloc] initWithFrame:monthLabelFrame];
	_headerTitleLabel.backgroundColor = [UIColor clearColor];
	_headerTitleLabel.font = [UIFont boldSystemFontOfSize:22.f];
	_headerTitleLabel.textAlignment = NSTextAlignmentCenter;
	_headerTitleLabel.textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Kal.bundle/kal_header_text_fill.png"]];

	[self setHeaderTitleText:[[KalLogic sharedLogic] selectedMonthNameAndYear]];
	[theHeader addSubview:_headerTitleLabel];
	
	// Create the next month button on the right side of the view
	CGRect nextMonthButtonFrame = CGRectMake(theHeader.width - kChangeMonthButtonWidth,
											 kHeaderVerticalAdjust,
											 kChangeMonthButtonWidth,
											 kChangeMonthButtonHeight);
	UIButton *nextMonthButton = [[UIButton alloc] initWithFrame:nextMonthButtonFrame];
	[nextMonthButton setImage:[UIImage imageNamed:@"Kal.bundle/kal_right_arrow.png"] forState:UIControlStateNormal];
	nextMonthButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	nextMonthButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	[nextMonthButton addTarget:self action:@selector(showFollowingMonth) forControlEvents:UIControlEventTouchUpInside];
	[theHeader addSubview:nextMonthButton];
	
	// Add column labels for each weekday (adjusting based on the current locale's first weekday)
	NSArray *weekdayNames = [[[NSDateFormatter alloc] init] shortWeekdaySymbols];
	NSUInteger firstWeekday = [[NSCalendar currentCalendar] firstWeekday];
	NSUInteger i = firstWeekday - 1;
	for (CGFloat xOffset = 0.f; xOffset < theHeader.width; xOffset += 46.f, i = (i+1)%7)
    {
		CGRect weekdayFrame = CGRectMake(xOffset, 30.f, 46.f, kHeaderHeight - 29.f);
		UILabel *weekdayLabel = [[UILabel alloc] initWithFrame:weekdayFrame];
		weekdayLabel.backgroundColor = [UIColor clearColor];
		weekdayLabel.font = [UIFont boldSystemFontOfSize:10.f];
		weekdayLabel.textAlignment = NSTextAlignmentCenter;
		weekdayLabel.textColor = [UIColor colorWithRed:0.3f green:0.3f blue:0.3f alpha:1.f];
		weekdayLabel.text = [weekdayNames objectAtIndex:i];
		[theHeader addSubview:weekdayLabel];
	}
}

- (void)addSubviewsToContentView:(UIView *)contentView
{
	// Both the tile grid and the list of events will automatically lay themselves
	// out to fit the # of weeks in the currently displayed month.
	// So the only part of the frame that we need to specify is the width.
	CGRect fullWidthAutomaticLayoutFrame = CGRectMake(0.f, 0.f, 322, 0.f);
	
	// The tile grid (the calendar body)
	_gridView = [[KalGridView alloc] initWithFrame:fullWidthAutomaticLayoutFrame delegate:_delegate];
	[_gridView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
	[contentView addSubview:_gridView];
	
	// The list of events for the selected day
	if (!self.tableView)
    {
		_tableView = [[UITableView alloc] initWithFrame:fullWidthAutomaticLayoutFrame style:UITableViewStylePlain];
		_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[contentView addSubview:_tableView];
	}

	// Trigger the initial KVO update to finish the contentView layout
	[_gridView sizeToFit];
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
		[self setHeaderTitleText:[change objectForKey:NSKeyValueChangeNewKey]];
		
	} else
    {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)setHeaderTitleText:(NSString *)text
{
	[self.headerTitleLabel setText:text];
	if (!isIpadDevice())
    {
		[self.headerTitleLabel sizeToFit];
		self.headerTitleLabel.left = floorf(self.width/2.f - self.headerTitleLabel.width/2.f);
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
    return self.gridView.transitioning;
}

- (void)markTilesForDates:(NSArray *)dates
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
	[self.gridView removeObserver:self forKeyPath:@"frame"];
}

@end

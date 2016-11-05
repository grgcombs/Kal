/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <CoreGraphics/CoreGraphics.h>

#import "KalGridView.h"
#import "KalView.h"
#import "KalMonthView.h"
#import "KalTileView.h"
#import "KalLogic.h"
#import "KalDate.h"
#import "KalPrivate.h"

#define SLIDE_NONE 0
#define SLIDE_UP 1
#define SLIDE_DOWN 2

const CGSize kTileSize = { 46.f, 44.f };

static NSString *kSlideAnimationId = @"KalSwitchMonths";

@interface KalGridView ()
@property (nonatomic, strong) KalTileView *selectedTile;
@property (nonatomic, strong) KalTileView *highlightedTile;
@property (nonatomic, strong) KalMonthView *frontMonthView;
@property (nonatomic, strong) KalMonthView *backMonthView;
@end

@implementation KalGridView

- (id)initWithFrame:(CGRect)frame delegate:(id<KalViewDelegate>)theDelegate
{
    // MobileCal uses 46px wide tiles, with a 2px inner stroke
    // along the top and right edges. Since there are 7 columns,
    // the width needs to be 46*7 (322px). But the iPhone's screen
    // is only 320px wide, so we need to make the
    // frame extend just beyond the right edge of the screen
    // to accomodate all 7 columns. The 7th day's 2px inner stroke
    // will be clipped off the screen, but that's fine because
    // MobileCal does the same thing.
    frame.size.width = 7 * kTileSize.width;

    if (self = [super initWithFrame:frame]) {
        self.clipsToBounds = YES;
        _delegate = theDelegate;

        CGRect monthRect = CGRectMake(0.f, 0.f, frame.size.width, frame.size.height);
        _frontMonthView = [[KalMonthView alloc] initWithFrame:monthRect];
        _backMonthView = [[KalMonthView alloc] initWithFrame:monthRect];
        _backMonthView.hidden = YES;
        [self addSubview:_backMonthView];
        [self addSubview:_frontMonthView];

        [self jumpToSelectedMonth];
    }
    return self;
}

- (id<KalViewDelegate>)delegate
{
    id<KalViewDelegate> delegate = _delegate;
	if (!delegate || ![delegate conformsToProtocol:@protocol(KalViewDelegate)])
    {
		if (self.superview && [self.superview isKindOfClass:[KalView class]])
        {
			delegate = [self.superview performSelector:@selector(delegate)];
		}
	}
	return delegate;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [[UIImage imageNamed:@"Kal.bundle/kal_grid_background.png"] drawInRect:rect];
    [[UIColor colorWithRed:0.63f green:0.65f blue:0.68f alpha:1.f] setFill];
    CGRect line;
    line.origin = CGPointMake(0.f, self.height - 1.f);
    line.size = CGSizeMake(self.width, 1.f);
    CGContextFillRect(UIGraphicsGetCurrentContext(), line);
}

- (void)sizeToFit
{
    self.height = _frontMonthView.height;
}

#pragma mark -
#pragma mark Touches

- (void)setHighlightedTile:(KalTileView *)tile
{
    if (_highlightedTile != tile) {
        _highlightedTile.highlighted = NO;
        _highlightedTile = tile;
        tile.highlighted = YES;
        [tile setNeedsDisplay];
    }
}

- (void)setSelectedTile:(KalTileView *)tile
{
	if (_selectedTile != tile)
    {
		_selectedTile.selected = NO;
		_selectedTile = tile;
		tile.selected = YES;

        id<KalViewDelegate> delegate = self.delegate;

		if (delegate && [delegate respondsToSelector:@selector(didSelectDate:)])
			[delegate performSelector:@selector(didSelectDate:) withObject:tile.date];
	}
}

- (void)receivedTouches:(NSSet *)touches withEvent:event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    UIView *hitView = [self hitTest:location withEvent:event];

    if (!hitView)
        return;

    if ([hitView isKindOfClass:[KalTileView class]]) {
        KalTileView *tile = (KalTileView*)hitView;
        if (tile.belongsToAdjacentMonth) {
            self.highlightedTile = tile;
        } else {
            self.highlightedTile = nil;
            self.selectedTile = tile;
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self receivedTouches:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self receivedTouches:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    UIView *hitView = [self hitTest:location withEvent:event];

    if ([hitView isKindOfClass:[KalTileView class]]
        ) {
        KalTileView *tile = (KalTileView*)hitView;
        if (tile.belongsToAdjacentMonth)
        {
            id<KalViewDelegate> delegate = self.delegate;

            if ([tile.date.NSDate compare:[KalLogic sharedLogic].baseDate] == NSOrderedDescending) {
                if (delegate && [delegate respondsToSelector:@selector(showFollowingMonth)])
                    [delegate performSelector:@selector(showFollowingMonth)];
            } else {
                if (delegate && [delegate respondsToSelector:@selector(showPreviousMonth)])
                    [delegate performSelector:@selector(showPreviousMonth)];
            }
            self.selectedTile = [self.frontMonthView tileForDate:tile.date];
        } else {
            self.selectedTile = tile;
        }
    }
    self.highlightedTile = nil;
}

#pragma mark -
#pragma mark Slide Animation

- (void)swapMonthsAndSlide:(int)direction keepOneRow:(BOOL)keepOneRow
{
    _backMonthView.hidden = NO;

    // set initial positions before the slide
    if (direction == SLIDE_UP) {
        _backMonthView.top = keepOneRow
        ? _frontMonthView.bottom - kTileSize.height
        : _frontMonthView.bottom;
    } else if (direction == SLIDE_DOWN) {
        NSUInteger numWeeksToKeep = keepOneRow ? 1 : 0;
        NSInteger numWeeksToSlide = [_backMonthView numWeeks] - numWeeksToKeep;
        _backMonthView.top = -numWeeksToSlide * kTileSize.height;
    } else {
        _backMonthView.top = 0.f;
    }

    // trigger the slide animation
    [UIView beginAnimations:kSlideAnimationId context:NULL]; {
        [UIView setAnimationsEnabled:direction!=SLIDE_NONE];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];

        _frontMonthView.top = -_backMonthView.top;
        _backMonthView.top = 0.f;

        _frontMonthView.alpha = 0.f;
        _backMonthView.alpha = 1.f;

        self.height = _backMonthView.height;

        [self swapMonthViews];
    } [UIView commitAnimations];
    [UIView setAnimationsEnabled:YES];
}

- (void)slide:(int)direction
{
    _transitioning = YES;
	KalLogic *theLogic = [KalLogic sharedLogic];
    [_backMonthView showDates:theLogic.daysInSelectedMonth
        leadingAdjacentDates:theLogic.daysInFinalWeekOfPreviousMonth
       trailingAdjacentDates:theLogic.daysInFirstWeekOfFollowingMonth];

    // At this point, the calendar logic has already been advanced or retreated to the
    // following/previous month, so in order to determine whether there are
    // any cells to keep, we need to check for a partial week in the month
    // that is sliding offscreen.

    BOOL keepOneRow = (direction == SLIDE_UP && [theLogic.daysInFinalWeekOfPreviousMonth count] > 0)
    || (direction == SLIDE_DOWN && [theLogic.daysInFirstWeekOfFollowingMonth count] > 0);

    [self swapMonthsAndSlide:direction keepOneRow:keepOneRow];

    self.selectedTile = [_frontMonthView firstTileOfMonth];
}

- (void)slideUp { [self slide:SLIDE_UP]; }
- (void)slideDown { [self slide:SLIDE_DOWN]; }

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    _transitioning = NO;
    _backMonthView.hidden = YES;
}

#pragma mark -

- (void)selectDate:(KalDate *)date
{
    self.selectedTile = [_frontMonthView tileForDate:date];
}

- (void)swapMonthViews
{
    KalMonthView *tmp = _backMonthView;
    _backMonthView = _frontMonthView;
    _frontMonthView = tmp;
    [self exchangeSubviewAtIndex:[self.subviews indexOfObject:_frontMonthView] withSubviewAtIndex:[self.subviews indexOfObject:_backMonthView]];
}

- (void)jumpToSelectedMonth
{
    [self slide:SLIDE_NONE];
}

- (void)markTilesForDates:(NSArray *)dates
{
    [_frontMonthView markTilesForDates:dates];
}

- (KalDate *)selectedDate {
    return self.selectedTile.date;
}

@end

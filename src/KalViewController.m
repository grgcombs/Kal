/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalViewController.h"
#import "KalLogic.h"
#import "KalDataSource.h"
#import "KalDate.h"
#import "KalPrivate.h"

#define PROFILER 0
#if PROFILER
#include <mach/mach_time.h>
#include <time.h>
#include <math.h>

void mach_absolute_difference(uint64_t end, uint64_t start, struct timespec *tp)
{
    uint64_t difference = end - start;
    static mach_timebase_info_data_t info = {0,0};
	
    if (info.denom == 0)
        mach_timebase_info(&info);
    
    uint64_t elapsednano = difference * (info.numer / info.denom);
    tp->tv_sec = elapsednano * 1e-9;
    tp->tv_nsec = elapsednano - (tp->tv_sec * 1e9);
}
#endif

NSString *const KalDataSourceChangedNotification = @"KalDataSourceChangedNotification";

@implementation KalViewController

- (void)awakeFromNib
{
	[super awakeFromNib];
	if (!_initialSelectedDate)
		_initialSelectedDate = [NSDate date];
}

- (id)initWithSelectedDate:(NSDate *)selectedDate
{
	if ((self = [super init]))
    {
        if (!selectedDate)
            selectedDate = [NSDate date];
		_initialSelectedDate = selectedDate;
		[[KalLogic sharedLogic] moveToMonthForDate:selectedDate];
	}
	return self;
}

- (id)init
{
	return [self initWithSelectedDate:[NSDate date]];
}

- (KalView*)calendarView
{
    KalView *calendarView = _calendarView;
	if (!calendarView)
    {
		if (self.view && [self.view isKindOfClass:[KalView class]])
        {
			calendarView = (KalView *)self.view;
            _calendarView = calendarView;
		}
	}
	return calendarView;
}

- (KalLogic*)logic
{
	return [KalLogic sharedLogic];
}

- (void)setDataSource:(id<KalDataSource>)aDataSource
{
	if (_dataSource != aDataSource) {
		_dataSource = aDataSource;
		_tableView.dataSource = _dataSource;
	}
}

- (void)setDelegate:(id<UITableViewDelegate>)delegate
{
    if (_delegate != delegate) {
		_delegate = delegate;
		_tableView.delegate = delegate;
	}
}

- (void)clearTable
{
	[_dataSource removeAllItems];
	[_tableView reloadData];
}

- (void)reloadData
{
	KalLogic *theLogic = [KalLogic sharedLogic];
	[_dataSource presentingDatesFrom:theLogic.fromDate to:theLogic.toDate delegate:self];
}

- (void)significantTimeChangeOccurred
{
	[self.calendarView jumpToSelectedMonth];
	[self reloadData];
}

// -----------------------------------------
#pragma mark KalViewDelegate protocol

- (void)didSelectDate:(KalDate *)date
{
	NSDate *selDate = [date NSDate];
	NSDate *from = [selDate cc_dateByMovingToBeginningOfDay];
	NSDate *to = [selDate cc_dateByMovingToEndOfDay];
	[self clearTable];
	[_dataSource loadItemsFromDate:from toDate:to];
	[_tableView reloadData];
	[_tableView flashScrollIndicators];
}

- (void)showPreviousMonth
{
	[self clearTable];
	[[KalLogic sharedLogic] retreatToPreviousMonth];
	[self.calendarView slideDown];
	[self reloadData];
}

- (void)showFollowingMonth
{
	[self clearTable];
	[[KalLogic sharedLogic] advanceToFollowingMonth];
	[self.calendarView slideUp];
	[self reloadData];
}

// -----------------------------------------
#pragma mark KalDataSourceCallbacks protocol

- (void)loadedDataSource:(id<KalDataSource>)theDataSource;
{
	KalLogic *theLogic = [KalLogic sharedLogic];
	NSArray *markedDates = [theDataSource markedDatesFrom:theLogic.fromDate to:theLogic.toDate];
	NSMutableArray *dates = [markedDates mutableCopy];


	for (int i=0; i<[markedDates count]; i++)
    {
        NSDate *date = dates[i];
        dates[i] = [KalDate dateFromNSDate:date];
    }
	
	[self.calendarView markTilesForDates:dates];
	[self didSelectDate:self.calendarView.selectedDate];
}

// ---------------------------------------
#pragma mark -

- (void)showAndSelectDate:(NSDate *)date
{
	if ([self.calendarView isSliding])
		return;
	
	[[KalLogic sharedLogic] moveToMonthForDate:date];
	
#if PROFILER
	uint64_t start, end;
	struct timespec tp;
	start = mach_absolute_time();
#endif
	
	[self.calendarView jumpToSelectedMonth];
	
#if PROFILER
	end = mach_absolute_time();
	mach_absolute_difference(end, start, &tp);
	printf("[[self calendarView] jumpToSelectedMonth]: %.1f ms\n", tp.tv_nsec / 1e6);
#endif
	
	[self.calendarView selectDate:[KalDate dateFromNSDate:date]];
	[self reloadData];
}

- (NSDate *)selectedDate
{
	return [self.calendarView.selectedDate NSDate];
}


// -----------------------------------------------------------------------------------
#pragma mark UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(significantTimeChangeOccurred) name:UIApplicationSignificantTimeChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:KalDataSourceChangedNotification object:nil];
	
	if (!self.title && isIpadDevice())
		self.title = NSLocalizedString(@"Calendar", @"");
	
	if (!_tableView && self.calendarView.tableView)
    {
		_tableView = self.calendarView.tableView;
	}
	if (_tableView) {
		_tableView.dataSource = _dataSource;
		_tableView.delegate = _delegate;
	}
	[self.calendarView selectDate:[KalDate dateFromNSDate:self.initialSelectedDate]];
	[self reloadData];
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationSignificantTimeChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:KalDataSourceChangedNotification object:nil];
	
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.tableView flashScrollIndicators];
}

#pragma mark -

- (void)dealloc
{
	self.calendarView = nil;	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationSignificantTimeChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:KalDataSourceChangedNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation { 	
	return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
}

@end

/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <UIKit/UIKit.h>

@class KalTileView, KalMonthView, KalDate;
@protocol KalViewDelegate;

/*
 *    KalGridView
 *    ------------------
 *
 *    Private interface
 *
 *  As a client of the Kal system you should not need to use this class directly
 *  (it is managed by KalView).
 *
 */
@interface KalGridView : UIView


@property (nonatomic, assign, getter=isTransitioning, readonly) BOOL transitioning;
@property (nonatomic, readonly) KalDate *selectedDate;
@property (nonatomic, weak) id<KalViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame delegate:(id<KalViewDelegate>)delegate calendar:(NSCalendar *)calendar;
- (void)selectDate:(KalDate *)date;
- (void)markTilesForDates:(NSArray<KalDate *> *)dates;

// These 3 methods should be called *after* the KalLogic
// has moved to the previous or following month.
- (void)slideUp;
- (void)slideDown;
- (void)jumpToSelectedMonth;    // see comment on KalView

@end

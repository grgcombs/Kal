/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <UIKit/UIKit.h>

@class KalTileView, KalDate;

@interface KalMonthView : UIView

@property (nonatomic, assign, readonly) UInt8 numWeeks;

- (instancetype)initWithFrame:(CGRect)rect calendar:(NSCalendar *)calendar; // NS_DESIGNATED_INITIALIZER;
- (void)showDates:(NSArray<KalDate *> *)mainDates leadingAdjacentDates:(NSArray<KalDate *> *)leadingAdjacentDates trailingAdjacentDates:(NSArray<KalDate *> *)trailingAdjacentDates;
- (KalTileView *)firstTileOfMonth;
- (KalTileView *)tileForDate:(KalDate *)date;
- (void)markTilesForDates:(NSArray<KalDate *> *)dates;

@end

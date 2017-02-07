/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <CoreGraphics/CoreGraphics.h>
#import "KalMonthView.h"
#import "KalTileView.h"
#import "KalView.h"
#import "KalDate.h"
#import "KalPrivate.h"

extern const CGSize kTileSize;

@interface KalMonthView ()
@property (nonatomic,strong) NSArray<KalTileView *> *tiles;
@property (nonatomic,strong) NSCalendar *calendar;
@property (nonatomic,assign) UInt8 numWeeks;
@end

@implementation KalMonthView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [self initWithFrame:frame calendar:nil];
    return  self;
}

- (instancetype)initWithFrame:(CGRect)frame calendar:(NSCalendar *)calendar
{
    if (!calendar)
        calendar = [NSCalendar autoupdatingCurrentCalendar];
    if ((self = [super initWithFrame:frame]))
    {
        _calendar = calendar;
        self.opaque = NO;
        self.clipsToBounds = YES;
        UInt16 tileIndex = 0;
        NSMutableArray *tiles = [[NSMutableArray alloc] init];
        UInt8 weekdayCount = calendar.weekdaySymbols.count;
        for (int i=0; i<6; i++)
        {
            for (UInt8 j=0; j < weekdayCount; j++)
            //for (int j=0; j<7; j++)
            {
                CGRect r = CGRectMake(j*kTileSize.width, i*kTileSize.height, kTileSize.width, kTileSize.height);
                KalTileView *tileView = [[KalTileView alloc] initWithFrame:r];
                tileView.tileIndex = tileIndex;
                [tiles addObject:tileView];
                [self addSubview:tileView];
                tileIndex++;
            }
        }
        _tiles = tiles;
    }
    return self;
}

- (KalTileView *)tileForIndex:(UInt16)index
{
    if (self.tiles.count > index)
    {
        KalTileView *tile = self.tiles[index];
        if (tile.tileIndex != index)
        {
            NSLog(@"Unexpected tile index: %d", index);
        }
        return tile;
    }
    return nil;
}

- (void)showDates:(NSArray<KalDate *> *)mainDates leadingAdjacentDates:(NSArray<KalDate *> *)leadingAdjacentDates trailingAdjacentDates:(NSArray<KalDate *> *)trailingAdjacentDates
{
    UInt16 tileNum = 0;
    if (!leadingAdjacentDates)
        leadingAdjacentDates = @[];
    if (!mainDates)
        mainDates = @[];
    if (!trailingAdjacentDates)
        trailingAdjacentDates = @[];

    NSCalendar *calendar = self.calendar;
    NSAssert(calendar != NULL, @"Must be instantiated with a valid calendar");

    NSArray *dateGroups = @[leadingAdjacentDates, mainDates, trailingAdjacentDates];
    for (UInt8 groupIndex = 0; groupIndex < dateGroups.count; groupIndex++)
    {
        NSArray<KalDate *> *dateGroup = dateGroups[groupIndex];
        BOOL isMainGroup = (groupIndex == 1);

        for (KalDate *date in dateGroup)
        {
            KalTileView *tile = [self tileForIndex:tileNum];
            [tile resetState];
            tile.date = date;
            NSDate *realDate = date.NSDate;
            NSAssert(realDate != NULL, @"Must be able to derive an NSDate from a KalDate");
            
            if (!isMainGroup)
                tile.type = KalTileTypeAdjacent;
            else if ([calendar isDateInToday:realDate])
                tile.type = KalTileTypeToday;
            else
                tile.type = KalTileTypeRegular;

            tileNum++;
        }
    }

    UInt8 weekdayCount = calendar.weekdaySymbols.count;
    NSAssert1(weekdayCount > 0, @"Broken calendar.  Can't determine number of weekdays. Calendar = %@", calendar);
    _numWeeks = ceilf(tileNum / weekdayCount);
    [self sizeToFit];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    NSString *kalBundlePath = [[NSBundle mainBundle] pathForResource:@"Kal" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:kalBundlePath];
    UIImage *image = [UIImage imageNamed:@"kal_tile" inBundle:bundle compatibleWithTraitCollection:self.traitCollection];
    if (image)
        CGContextDrawTiledImage(ctx, (CGRect){CGPointZero,kTileSize}, [image CGImage]);
}

- (KalTileView *)firstTileOfMonth
{
    KalTileView *tile = nil;
    for (KalTileView *t in self.tiles)
    {
        if (!t.belongsToAdjacentMonth)
        {
            tile = t;
            break;
        }
    }

    return tile;
}

- (KalTileView *)tileForDate:(KalDate *)kalDate
{
    if (!kalDate || !self.tiles.count)
        return nil;
    NSDate *dateToFind = [kalDate NSDate];
    if (!dateToFind)
        return nil;

    KalTileView *tile = nil;
    NSCalendar *calendar = self.calendar;

    for (KalTileView *t in self.tiles)
    {
        NSDate *tileDate = [t.date NSDate];
        if (!tileDate)
            continue;
        if ([calendar isDate:tileDate inSameDayAsDate:dateToFind])
        {
            tile = t;
            break;
        }
    }

    if (!tile)
        NSLog(@"Failed to find corresponding tile for date %@", dateToFind);

    return tile;
}

- (void)sizeToFit
{
    self.height = 1.f + kTileSize.height * self.numWeeks;
}

- (void)markTilesForDates:(NSArray<KalDate *> *)dates
{
    NSCalendar *calendar = self.calendar;
    NSMutableOrderedSet<NSDate *> *datesToMark = [[NSMutableOrderedSet alloc] init];
    for (KalDate *kalDate in dates)
    {
        NSDate *realDate = kalDate.NSDate;
        if (!realDate)
            continue;
        NSDate *startOfDay = [calendar startOfDayForDate:realDate];
        if (!startOfDay)
            continue;
        [datesToMark addObject:startOfDay];
    }

    for (KalTileView *tile in self.tiles)
    {
        NSDate *tileDate = tile.date.NSDate;
        if (!tileDate)
            continue;
        NSDate *startOfDay = [calendar startOfDayForDate:tileDate];
        if (!startOfDay)
            continue;
        tile.marked = [datesToMark containsObject:tileDate];
    }
}

@end

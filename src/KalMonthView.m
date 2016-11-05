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
@property (nonatomic,strong) NSArray *tiles;
@end

@implementation KalMonthView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.opaque = NO;
        self.clipsToBounds = YES;
        UInt16 tileIndex = 0;
        NSMutableArray *tiles = [[NSMutableArray alloc] init];
        for (int i=0; i<6; i++)
        {
            for (int j=0; j<7; j++)
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

- (void)showDates:(NSArray *)mainDates leadingAdjacentDates:(NSArray *)leadingAdjacentDates trailingAdjacentDates:(NSArray *)trailingAdjacentDates
{
    UInt16 tileNum = 0;
    if (!leadingAdjacentDates)
        leadingAdjacentDates = @[];
    if (!mainDates)
        mainDates = @[];
    if (!trailingAdjacentDates)
        trailingAdjacentDates = @[];

    NSArray *dateGroups = @[leadingAdjacentDates, mainDates, trailingAdjacentDates];
    for (UInt8 groupIndex = 0; groupIndex < dateGroups.count; groupIndex++)
    {
        NSArray *dateGroup = dateGroups[groupIndex];
        BOOL isMainGroup = (groupIndex == 1);

        for (KalDate *date in dateGroup)
        {
            KalTileView *tile = [self tileForIndex:tileNum];
            [tile resetState];
            tile.date = date;

            if (!isMainGroup)
                tile.type = KalTileTypeAdjacent;
            else if ([date isToday])
                tile.type = KalTileTypeToday;
            else
                tile.type = KalTileTypeRegular;

            tileNum++;
        }
    }

    _numWeeks = ceilf(tileNum / 7.f);
    [self sizeToFit];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIImage *image = [UIImage imageNamed:@"Kal.bundle/kal_tile.png"];
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
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];

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

- (void)markTilesForDates:(NSArray *)dates
{
    for (KalTileView *tile in self.tiles)
    {
        tile.marked = [dates containsObject:tile.date];
    }
}

@end

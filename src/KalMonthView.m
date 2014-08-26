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

@synthesize numWeeks;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.opaque = NO;
        self.clipsToBounds = YES;
        UInt16 tileIndex = 0;
        NSMutableArray *tiles = [[NSMutableArray alloc] init];
        for (int i=0; i<6; i++) {
            for (int j=0; j<7; j++) {
                CGRect r = CGRectMake(j*kTileSize.width, i*kTileSize.height, kTileSize.width, kTileSize.height);
                KalTileView *tileView = [[KalTileView alloc] initWithFrame:r];
                tileView.tileIndex = tileIndex;
                [tiles addObject:tileView];
                [self addSubview:tileView];
                [tileView release];
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
    NSArray *dates[] = { leadingAdjacentDates, mainDates, trailingAdjacentDates };

    for (int i=0; i<3; i++) {
        for (KalDate *d in dates[i]) {
            KalTileView *tile = [self tileForIndex:tileNum];
            [tile resetState];
            tile.date = d;
            tile.type = ((dates[i] != mainDates) ? KalTileTypeAdjacent : [d isToday]) ? KalTileTypeToday : KalTileTypeRegular;
            tileNum++;
        }
    }

    numWeeks = ceilf(tileNum / 7.f);
    [self sizeToFit];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextDrawTiledImage(ctx, (CGRect){CGPointZero,kTileSize}, [[UIImage imageNamed:@"Kal.bundle/kal_tile.png"] CGImage]);
}

- (KalTileView *)firstTileOfMonth
{
    KalTileView *tile = nil;
    for (KalTileView *t in self.tiles) {
        if (!t.belongsToAdjacentMonth) {
            tile = t;
            break;
        }
    }

    return tile;
}

- (KalTileView *)tileForDate:(KalDate *)date
{
    KalTileView *tile = nil;
    for (KalTileView *t in self.tiles) {
        if ([t.date isEqual:date]) {
            tile = t;
            break;
        }
    }
    if (!tile)
        NSLog(@"Failed to find corresponding tile for date %@", date);

    return tile;
}

- (void)sizeToFit
{
    self.height = 1.f + kTileSize.height * numWeeks;
}

- (void)markTilesForDates:(NSArray *)dates
{
    for (KalTileView *tile in self.tiles)
        tile.marked = [dates containsObject:tile.date];
}

@end

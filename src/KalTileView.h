/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, KalTileType) {
    KalTileTypeRegular,
    KalTileTypeAdjacent,
    KalTileTypeToday,
};

@class KalDate;

@interface KalTileView : UIView

@property (nonatomic, retain) KalDate *date;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, getter=isSelected) BOOL selected;
@property (nonatomic, getter=isMarked) BOOL marked;
@property (nonatomic, assign) KalTileType type;
@property (nonatomic, assign) UInt16 tileIndex;
@property (nonatomic, readonly) CGPoint origin;

- (void)resetState;
- (BOOL)isToday;
- (BOOL)belongsToAdjacentMonth;

@end

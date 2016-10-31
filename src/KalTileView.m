/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalTileView.h"
#import "KalDate.h"
#import "KalPrivate.h"

extern const CGSize kTileSize;

@implementation KalTileView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.opaque = YES;
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
        _origin = frame.origin;
        [self resetState];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGFloat shadowOffset = -1;
    UIColor *shadowColor = [UIColor blackColor];
    UIColor *textColor = [UIColor whiteColor];
    UIImage *markerImage = nil;

    //CGContextTranslateCTM(ctx, 0, kTileSize.height);
    //CGContextScaleCTM(ctx, 1, -1);

    CGRect imageRect = CGRectMake(0, -1, kTileSize.width+1, kTileSize.height+1);

    BOOL isToday = self.isToday;
    BOOL isSelected = self.isSelected;
    BOOL isAdjacent = self.belongsToAdjacentMonth;

    if (isToday && isSelected)
    {
        UIImage *image = [UIImage imageNamed:@"Kal.bundle/kal_tile_today_selected.png"];
        if (image)
            [[image stretchableImageWithLeftCapWidth:6 topCapHeight:0] drawInRect:imageRect];
        markerImage = [UIImage imageNamed:@"Kal.bundle/kal_marker_today.png"];
    }
    else if (isToday)
    {
        UIImage *image = [UIImage imageNamed:@"Kal.bundle/kal_tile_today.png"];
        if (image)
            [[image stretchableImageWithLeftCapWidth:6 topCapHeight:0] drawInRect:imageRect];
        markerImage = [UIImage imageNamed:@"Kal.bundle/kal_marker_today.png"];
    }
    else if (isSelected)
    {
        UIImage *image = [UIImage imageNamed:@"Kal.bundle/kal_tile_selected.png"];
        if (image)
            [[image stretchableImageWithLeftCapWidth:1 topCapHeight:0] drawInRect:imageRect];
        markerImage = [UIImage imageNamed:@"Kal.bundle/kal_marker_selected.png"];
    }
    else if (isAdjacent)
    {
        UIImage *image = [UIImage imageNamed:@"Kal.bundle/kal_tile_dim_text_fill.png"];
        if (image)
            textColor = [UIColor colorWithPatternImage:image];
        shadowColor = nil;
        markerImage = [UIImage imageNamed:@"Kal.bundle/kal_marker_dim.png"];
    }
    else
    {
        UIImage *image = [UIImage imageNamed:@"Kal.bundle/kal_tile_text_fill.png"];
        if (image)
            textColor = [UIColor colorWithPatternImage:image];
        shadowColor = [UIColor whiteColor];
        shadowOffset = 1;
        markerImage = [UIImage imageNamed:@"Kal.bundle/kal_marker.png"];
    }

    NSMutableDictionary *attributes = [@{NSFontAttributeName: [UIFont boldSystemFontOfSize:24],
                                         NSForegroundColorAttributeName: textColor} mutableCopy];
    if (shadowColor)
    {
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowColor = shadowColor;
        shadow.shadowOffset = CGSizeMake(0, shadowOffset);

        attributes[NSShadowAttributeName] = shadow;
    }

    if (self.isMarked && markerImage)
        [markerImage drawAtPoint:CGPointMake(21, 1)];

    NSInteger n = [self.date day];
    NSString *dayText = [@(n) stringValue];
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:dayText attributes:attributes];

    NSStringDrawingContext *stringContext = [[NSStringDrawingContext alloc] init];
    NSStringDrawingOptions options = (NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin);
    CGRect boundingRect = [string boundingRectWithSize:rect.size options:options context:stringContext];
    CGSize textSize = boundingRect.size;

    CGFloat textX = roundf(0.5f * (kTileSize.width - textSize.width));
    CGFloat textY = roundf(0.5f * (kTileSize.height - textSize.height));
    boundingRect.origin = CGPointMake(textX, textY);

    boundingRect = CGRectIntegral(boundingRect);
    [string drawWithRect:boundingRect options:options context:stringContext];

    if (self.isHighlighted)
    {
        UIColor *highlightColor = [UIColor colorWithWhite:0.25f alpha:0.3f];
        [highlightColor setFill];
        CGRect fillRect = (CGRect){CGPointZero,kTileSize};
        CGContextFillRect(ctx, fillRect);
    }
}

- (void)resetState
{
    // realign to the grid
    CGRect frame = (CGRect){self.origin, kTileSize};
    self.frame = CGRectIntegral(frame);

    if (_date)
        [_date release];
    _date = nil;
    self.highlighted = NO;
    self.selected = NO;
    self.marked = NO;

    self.type = KalTileTypeRegular;
}

- (void)setDate:(KalDate *)aDate
{
    if (_date == aDate)
        return;

    if (_date)
        [_date release];
    _date = [aDate retain];

    [self setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected
{
    if (_selected == selected)
        return;
    _selected = selected;
    [self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (_highlighted == highlighted)
        return;
    _highlighted = highlighted;
    [self setNeedsDisplay];
}

- (void)setMarked:(BOOL)marked
{
    if (_marked == marked)
        return;
    _marked = marked;
    [self setNeedsDisplay];
}

- (void)setType:(KalTileType)tileType
{
    if (_type == tileType)
        return;
    _type = tileType;
    [self setNeedsDisplay];
}

- (BOOL)isToday { return self.type == KalTileTypeToday; }

- (BOOL)belongsToAdjacentMonth { return self.type == KalTileTypeAdjacent; }

- (void)dealloc
{
    if (_date)
        [_date release];
    _date = nil;
    [super dealloc];
}

@end

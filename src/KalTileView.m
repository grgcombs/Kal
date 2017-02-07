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
    if ((self = [super initWithFrame:frame]))
    {
        self.opaque = YES;
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
        _origin = frame.origin;
        [self resetState];
    }
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    NSString *kalBundlePath = [[NSBundle mainBundle] pathForResource:@"Kal" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:kalBundlePath];
    NSAssert1(bundle != NULL, @"Must have a Kal.bundle of image assets.  No bundle found at: %@", kalBundlePath);
    UITraitCollection *traits = self.traitCollection;

    CGContextRef ctx = UIGraphicsGetCurrentContext();

    UIColor *textColor = [UIColor whiteColor];
    UIImage *tileImage = nil;

    //CGContextTranslateCTM(ctx, 0, kTileSize.height);
    //CGContextScaleCTM(ctx, 1, -1);

    CGRect imageRect = CGRectMake(0, -1, kTileSize.width+1, kTileSize.height+1);

    BOOL isToday = self.isToday;
    BOOL isSelected = self.isSelected;
    BOOL isAdjacent = self.belongsToAdjacentMonth;

    if (isToday)
    {
        NSString *imageName = @"kal_tile_today";
        if (isSelected)
            imageName = [imageName stringByAppendingString:@"_selected"];
        tileImage = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:traits];
        if (tileImage)
        {
            UIImage *imageToDraw = [tileImage stretchableImageWithLeftCapWidth:6 topCapHeight:0];
            [imageToDraw drawInRect:imageRect];
        }
    }
    else if (isSelected)
    {
        tileImage = [UIImage imageNamed:@"kal_tile_selected" inBundle:bundle compatibleWithTraitCollection:traits];
        if (tileImage)
        {
            UIImage *imageToDraw = [tileImage stretchableImageWithLeftCapWidth:1 topCapHeight:0];
            [imageToDraw drawInRect:imageRect];
        }
    }
    else if (isAdjacent)
    {
        tileImage = [UIImage imageNamed:@"kal_tile_dim_text_fill" inBundle:bundle compatibleWithTraitCollection:traits];
        if (tileImage)
            textColor = [UIColor colorWithPatternImage:tileImage];
    }
    else
    {
        tileImage = [UIImage imageNamed:@"kal_tile_text_fill" inBundle:bundle compatibleWithTraitCollection:traits];
        if (tileImage)
            textColor = [UIColor colorWithPatternImage:tileImage];
    }

    if (!textColor)
        textColor = [UIColor lightTextColor];

    static UIFont *tileFont = nil;
    if (!tileFont)
        tileFont = [UIFont boldSystemFontOfSize:24];

    NSDictionary *attributes = @{NSFontAttributeName: tileFont,
                                 NSForegroundColorAttributeName: textColor};

    NSInteger n = [self.date day];
    NSString *dayText = [@(n) stringValue];
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:dayText attributes:attributes];

    NSStringDrawingContext *stringContext = [[NSStringDrawingContext alloc] init];
    NSStringDrawingOptions options = (NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin);
    CGRect boundingRect = [string boundingRectWithSize:rect.size options:options context:stringContext];
    CGSize textSize = boundingRect.size;

    CGFloat textX = floorf(0.5f * (kTileSize.width - textSize.width));
    CGFloat textY = ceilf(0.5f * (kTileSize.height - textSize.height));
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

    if (self.isMarked)
    {
        CGSize markSize = CGSizeMake(4, 4);
        CGFloat midMarkWidth = ceil(markSize.width / 2.f);
        CGFloat midTileWidth = CGRectGetMidX(rect);
        CGPoint markOrigin = CGPointMake(floor(midTileWidth - midMarkWidth), 2);
        CGRect markRect = CGRectIntegral((CGRect){markOrigin,markSize});
        [textColor setFill];
        CGContextFillEllipseInRect(ctx, markRect);
    }
}

- (void)resetState
{
    // realign to the grid
    CGRect frame = (CGRect){self.origin, kTileSize};
    self.frame = CGRectIntegral(frame);

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
    _date = aDate;
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

- (BOOL)isToday
{
    return self.type == KalTileTypeToday;
}

- (BOOL)belongsToAdjacentMonth
{
    return self.type == KalTileTypeAdjacent;
}

@end

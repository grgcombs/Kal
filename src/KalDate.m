/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalDate.h"
#import "KalPrivate.h"

static KalDate *today;


@interface KalDate ()
+ (void)cacheTodaysDate;
@end


@implementation KalDate

+ (void)initialize
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cacheTodaysDate) name:UIApplicationSignificantTimeChangeNotification object:nil];
    [self cacheTodaysDate];
}

+ (void)cacheTodaysDate
{
    [today release];
    today = [[KalDate dateFromNSDate:[NSDate date]] retain];
}

+ (KalDate *)dateForDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year
{
    return [[[KalDate alloc] initForDay:day month:month year:year] autorelease];
}

+ (KalDate *)dateFromNSDate:(NSDate *)date
{
	if (!date || [[NSNull null] isEqual:date])
		date = [NSDate date];
    NSDateComponents *parts = [date cc_componentsForMonthDayAndYear];
    KalDate *kalDate = [KalDate dateForDay:[parts day] month:[parts month] year:[parts year]];
    kalDate.date = date;
    return kalDate;
}

- (id)initForDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year
{
    if ((self = [super init])) {
        _day = day;
        _month = month;
        _year = year;
    }
    return self;
}

- (NSDate *)NSDate
{
    if (!_date)
    {
        NSDateComponents *c = [[NSDateComponents alloc] init];
        c.day = _day;
        c.month = _month;
        c.year = _year;
        _date = [[[NSCalendar currentCalendar] dateFromComponents:c] retain];
        [c release];
    }
    return _date;
}

- (BOOL)isToday { return [self isEqual:today]; }

- (NSComparisonResult)compare:(KalDate *)otherDate
{
    if (![otherDate isKindOfClass:[KalDate class]])
    {
        return NSNotFound;
    }
    return [[self NSDate] compare:[otherDate NSDate]];
}

#pragma mark -
#pragma mark NSObject interface

- (BOOL)isEqual:(id)anObject
{
    if (![anObject isKindOfClass:[KalDate class]])
        return NO;

    KalDate *d = (KalDate*)anObject;
    return [[d NSDate] isEqual:[self NSDate]];
}

- (NSUInteger)hash
{
    return [[self NSDate] hash];
}

- (NSString *)description
{
    return [[self NSDate] description];
}

@end

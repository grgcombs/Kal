/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <Foundation/Foundation.h>

@interface KalDate : NSObject

@property (nonatomic,assign) NSInteger month;
@property (nonatomic,assign) NSInteger day;
@property (nonatomic,assign) NSInteger year;
@property (nonatomic,strong) NSDate *date;


+ (instancetype)dateForDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year;
+ (instancetype)dateFromNSDate:(NSDate *)date;

- (instancetype)initForDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year;
- (NSDate *)NSDate;
- (NSComparisonResult)compare:(KalDate *)otherDate;
- (BOOL)isToday;

@end

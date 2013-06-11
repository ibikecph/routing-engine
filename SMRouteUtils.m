//
//  SMRouteUtils.m
//  testRouteMe
//
//  Created by Rasko Gojkovic on 6/10/13.
//  Copyright (c) 2013 Rasko Gojkovic. All rights reserved.
//

#import "SMRouteUtils.h"

@implementation SMRouteUtils


// Format distance string (choose between meters and kilometers)
NSString *formatDistance(float meters) {
    if (meters < 5) {
        return @"";
    } else if (meters <= 94) {
        return [NSString stringWithFormat:@"%.0f %@", roundf(meters/10.0f) * 10, DISTANCE_M_SHORT];
    } else if (meters < 1000) {
        return [NSString stringWithFormat:@"%.0f %@", roundf(meters/100.0f) * 100, DISTANCE_M_SHORT];
    } else {
        return [NSString stringWithFormat:@"%.1f %@", meters/1000.0f, DISTANCE_KM_SHORT];
    }
    return meters >= 1000.0f ? [NSString stringWithFormat:@"%.1f %@", meters/1000.0f, DISTANCE_KM_SHORT] : [NSString stringWithFormat:@"%.0f %@", meters, DISTANCE_M_SHORT];
}

// Format time duration string (choose between seconds and hours)
NSString *formatTime(float seconds) {
    return seconds > 60.0f ? [NSString stringWithFormat:@"%.0f %@", seconds/60.0f, TIME_MINUTES_SHORT] : [NSString stringWithFormat:@"%.0f %@", seconds, TIME_MINUTES_SHORT];
}

// Format time passed between two dates
NSString *formatTimePassed(NSDate *startDate, NSDate *endDate) {
    NSCalendar * cal = [NSCalendar currentCalendar];
    NSDateComponents * comp = [cal components:(NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit) fromDate:startDate toDate:endDate options:0];
    
    NSString * timestr = @"";
    if (comp.day > 0) {
        timestr = [timestr stringByAppendingFormat:@"%d%@ ", comp.day, TIME_DAYS_SHORT];
    }
    if (comp.hour > 0) {
        timestr = [timestr stringByAppendingFormat:@"%d%@ ", comp.hour, TIME_HOURS_SHORT];
    }
    if (comp.minute > 0) {
        timestr = [timestr stringByAppendingFormat:@"%d%@ ", comp.minute, TIME_MINUTES_SHORT];
    }
    if (comp.second > 0) {
        timestr = [timestr stringByAppendingFormat:@"%d%@", comp.second, TIME_SECONDS_SHORT];
    }
    return timestr;
}



NSString *formatTimeLeft(NSInteger seconds) {
    NSMutableArray * arr = [NSMutableArray array];
    
    NSInteger x = seconds / 86400;
    if (x > 0) {
        [arr addObject:[NSString stringWithFormat:@"%02d", x]];
    }
    seconds = seconds % 86400;
    x = seconds / 3600;
    if (x > 0 || [arr count] > 0) {
        [arr addObject:[NSString stringWithFormat:@"%02d", x]];
    }
    seconds = seconds % 3600;
    x = seconds / 60;
    if (x > 0 || [arr count] > 0) {
        [arr addObject:[NSString stringWithFormat:@"%02d", x]];
    }
    seconds = seconds % 60;
    if ([arr count] > 0) {
        [arr addObject:[NSString stringWithFormat:@"%02d", seconds]];
    } else {
        [arr addObject:@"00"];
        [arr addObject:[NSString stringWithFormat:@"%02d", seconds]];
    }
    return [arr componentsJoinedByString:@":"];
}

NSString *expectedArrivalTime(NSInteger seconds) {
    NSDate * d = [NSDate dateWithTimeInterval:seconds sinceDate:[NSDate date]];
    NSDateFormatter * df = [NSDateFormatter new];
    [df setDateFormat:@"HH:mm"];
    return [df stringFromDate:d];
}

// Calculate how many calories are burned given speed and time spent cycling
float caloriesBurned(float avgSpeed, float timeSpent){
    float calBurned = 0.0f;
    
    if (avgSpeed < 10.5) {
        calBurned = timeSpent * 288;
    } else if (avgSpeed < 12.9) {
        calBurned = timeSpent * 324;
    } else if (avgSpeed < 13.7) {
        calBurned = timeSpent * 374;
    } else if (avgSpeed < 16.1) {
        calBurned = timeSpent * 540;
    } else if (avgSpeed < 19.3) {
        calBurned = timeSpent * 639;
    } else if (avgSpeed < 21) {
        calBurned = timeSpent * 702;
    } else if (avgSpeed < 22.5) {
        calBurned = timeSpent * 806;
    } else if (avgSpeed < 24.2) {
        calBurned = timeSpent * 873;
    } else if (avgSpeed < 25.8) {
        calBurned = timeSpent * 945;
    } else if (avgSpeed < 32.2) {
        calBurned = timeSpent * 1121;
    } else if (avgSpeed < 35.4) {
        calBurned = timeSpent * 1359;
    } else if (avgSpeed < 38.7) {
        calBurned = timeSpent * 1746;
    } else if (avgSpeed < 45.1) {
        calBurned = timeSpent * 2822;
    } else  {
        calBurned = timeSpent * 3542;
    }
    
    return roundf(calBurned);
}


@end

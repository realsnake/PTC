//
//  Pairs.h
//  PTC
//
//  Created by snake on 12-1-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Pairs : NSManagedObject

@property (nonatomic, retain) NSString * word;
@property (nonatomic, retain) NSString * antonym;

@end

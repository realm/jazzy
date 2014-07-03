//
//  JAZMusician.m
//  JazzyApp
//

#import "JAZMusician.h"

@implementation JAZMusician

- (instancetype)initWithName:(NSString *)name birthyear:(NSUInteger)birthyear {
    self = [super init];
    if (self) {
        _name = [name copy];
        _birthyear = birthyear;
    }
    return self;
}

@end

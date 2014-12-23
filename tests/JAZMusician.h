//
//  JAZMusician.h
//  JazzyApp
//

#import <Foundation/Foundation.h>

/**
 JAZMusician models, you guessed it... Jazz Musicians!
 From Ellington to Marsalis, this class has you covered.
 */
@interface JAZMusician : NSObject

/**
 The name of the musician. i.e. "John Coltrane"
 */
@property (nonatomic, readonly) NSString  *name;

/**
 The year the musician was born. i.e. 1926
 */
@property (nonatomic, readonly) NSUInteger birthyear;

/**
 Initialize a JAZMusician.
 Don't forget to have a name and a birthyear.
 
 @warning Jazz can be addicting.
 Please be careful out there.
 
 @param name      The name of the musician.
 @param birthyear The year the musician was born.
 
 @return          An initialized JAZMusician instance.
 */
- (instancetype)initWithName:(NSString *)name birthyear:(NSUInteger)birthyear;

@end

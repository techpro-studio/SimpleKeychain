//
//  SimpleKeychain.h
//  Runner
//
//  Created by Alex on 21.07.2020.
//  Copyright © 2020 Alex Moiseenko. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SimpleKeychain : NSObject

-(instancetype) initWithSharedGroup: (nullable NSString *) sharedGroup;

-(nullable NSString *) get: (NSString *) key;
-(BOOL) set:(NSString *) value forKey: (NSString *) key;
-(void) remove: (NSString *) key;

@end

NS_ASSUME_NONNULL_END

//
//  SimpleKeychain.h
//  Runner
//
//  Created by Alex on 21.07.2020.
//  Copyright © 2020 Alex Moiseenko. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface KeychainResult : NSObject

@property (nonatomic, readonly, nullable) NSString *value;
@property (nonatomic, readonly, nullable) NSError* error;

@end

@interface SimpleKeychain : NSObject

-(instancetype) initWithSharedGroup: (nullable NSString *) sharedGroup;

-(KeychainResult *) get: (NSString *) key;
-(NSError *) set:(NSString *) value forKey: (NSString *) key;
-(NSError *) remove: (NSString *) key;

@end

NS_ASSUME_NONNULL_END

//
//  SimpleKeychain.m
//  Runner
//
//  Created by Alex on 21.07.2020.
//  Copyright © 2020 Alex Moiseenko. All rights reserved.
//

#import "SimpleKeychain.h"
#import <Security/Security.h>


@implementation SimpleKeychain
{
    NSString * sharedGroup;
    dispatch_queue_t syncQueue;
}

-(instancetype)initWithSharedGroup: (nullable NSString *)sharedGroup
{
    self = [super init];
    if (self) {
        self->sharedGroup = sharedGroup;
        self->syncQueue = dispatch_queue_create("keychain.sync", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

-(instancetype)init
{
    return [self initWithSharedGroup:nil];
}

-(NSMutableDictionary *) makeBaseQuery: (NSString *) key
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity: 5];
    dict[(__bridge  NSString*) kSecClass] = (__bridge  NSString*) kSecClassGenericPassword;
    dict[(__bridge  NSString*) kSecAttrAccount] = key;
    if (sharedGroup)
        dict[(__bridge  NSString*) kSecAttrAccessGroup] = sharedGroup;
    return dict;

}



-(NSString *) get: (NSString *)key
{
    __block NSString *result;
    dispatch_sync(syncQueue, ^{
        CFTypeRef dataTypeRef = NULL;
        __auto_type query = [self makeBaseQuery:key];
        query[(id)kSecReturnData] = (__bridge  NSNumber*) kCFBooleanTrue;
        query[(__bridge  NSString*)kSecMatchLimit] =  (__bridge  NSString*) kSecMatchLimitOne;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) query, &dataTypeRef);
        if (status == errSecSuccess){
            NSData *data = (__bridge NSData *)dataTypeRef;
            result = [NSString stringWithUTF8String: [data bytes]];
        }
    });
    return result;
}

-(BOOL)set: (NSString *)value forKey:(NSString *)key
{
    __block BOOL result = NO;
    dispatch_sync(syncQueue, ^{
        NSMutableDictionary * query = [self makeBaseQuery:key];
        query[(__bridge  NSString*)kSecMatchLimit] =  (__bridge  NSString*) kSecMatchLimitOne;
        OSStatus status;
        status = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
        switch (status) {
            case errSecSuccess:
                query[(__bridge  NSString*)kSecMatchLimit] = nil;
                status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef) @{(__bridge id)kSecValueData: [value dataUsingEncoding:NSUTF8StringEncoding]});
                if (status == errSecSuccess){
                    result = YES;
                }
                break;
            case errSecItemNotFound:
                query[(__bridge  NSString*)kSecMatchLimit] = nil;
                query[(id)kSecValueData] = [value dataUsingEncoding:NSUTF8StringEncoding];
                status = SecItemAdd((__bridge CFDictionaryRef)query, nil);
                if (status == errSecSuccess){
                    result = YES;
                }
                break;
            default:
                break;
        }
    });
    return result;
}

-(void)remove: (NSString *)key
{
    dispatch_sync(syncQueue, ^{
        SecItemDelete((__bridge CFDictionaryRef) [self makeBaseQuery:key]);
    });
}

@end

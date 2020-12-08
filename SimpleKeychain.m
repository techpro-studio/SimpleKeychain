//
//  SimpleKeychain.m
//  Runner
//
//  Created by Alex on 21.07.2020.
//  Copyright © 2020 Alex Moiseenko. All rights reserved.
//

#import "SimpleKeychain.h"
#import <Security/Security.h>


@interface KeychainResult ()

+(instancetype) success: ( NSString * _Nonnull)value;
+(instancetype) error: ( NSError * _Nonnull)error;


@end


@implementation KeychainResult


+ (instancetype)success:(NSString *)value{
    return [[KeychainResult alloc] initWithValue:value andError:nil];
}

+ (instancetype)error:(NSError *)error {
    return [[KeychainResult alloc] initWithValue:nil andError:error];
}


- (instancetype)initWithValue:(NSString *) value andError: (NSError *) error
{
    self = [super init];
    if (self) {
        self->_value = value;
        self->_error = error;
    }
    return self;
}

@end


static NSError* errorWithOSStatus(OSStatus status){
    return [NSError errorWithDomain:@"keychain" code:status userInfo:@{NSLocalizedDescriptionKey: @"OSStatus error"}];
}

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




-(KeychainResult *) get: (NSString *) key
{
    __block KeychainResult* result;
    dispatch_sync(syncQueue, ^{
        CFTypeRef dataTypeRef = NULL;
        __auto_type query = [self makeBaseQuery:key];
        query[(id)kSecReturnData] = (__bridge  NSNumber*) kCFBooleanTrue;
        query[(__bridge  NSString*)kSecMatchLimit] =  (__bridge  NSString*) kSecMatchLimitOne;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) query, &dataTypeRef);
        if (status == errSecSuccess){
            NSData *data = (__bridge NSData *)dataTypeRef;
            result = [KeychainResult success:[NSString stringWithUTF8String: [data bytes]]];
        } else{
            result = [KeychainResult error:errorWithOSStatus(status)];
        }
    });
    return result;
}

-(NSError *) set:(NSString *) value forKey: (NSString *) key;
{
    __block NSError* error = nil;
    dispatch_sync(syncQueue, ^{
        NSMutableDictionary * query = [self makeBaseQuery:key];
        query[(__bridge  NSString*)kSecMatchLimit] =  (__bridge  NSString*) kSecMatchLimitOne;
        OSStatus status;
        status = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
        switch (status) {
            case errSecSuccess:
                query[(__bridge  NSString*)kSecMatchLimit] = nil;
                status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef) @{(__bridge id)kSecValueData: [value dataUsingEncoding:NSUTF8StringEncoding]});
                if (status != errSecSuccess){
                    error = errorWithOSStatus(status);
                }
                break;
            case errSecItemNotFound:
                query[(__bridge  NSString*)kSecMatchLimit] = nil;
                query[(id)kSecValueData] = [value dataUsingEncoding:NSUTF8StringEncoding];
                status = SecItemAdd((__bridge CFDictionaryRef)query, nil);
                if (status != errSecSuccess){
                    error = errorWithOSStatus(status);
                }
                break;
            default:
                error = errorWithOSStatus(status);
                break;
        }
    });
    return error;
}

-(NSError *) remove: (NSString *) key
{
    __block NSError* error = nil;
    dispatch_sync(syncQueue, ^{
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef) [self makeBaseQuery:key]);
        if (status != errSecSuccess){
            error = errorWithOSStatus(status);
        }
    });
    return error;
}

@end

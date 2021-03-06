//
//  NextApplication.m
//  next-cocoa
//
//  Created by John Mercouris on 3/25/18.
//  Copyright © 2018 Next. All rights reserved.
//

#import "NextApplication.h"
#include <xmlrpc-c/base.h>
#include <xmlrpc-c/client.h>
#include <xmlrpc-c/config.h>
#include "Global.h"
#include "NextApplicationDelegate.h"

@implementation NextApplication

- (void)sendEvent:(NSEvent *)event
{
    if ([event type] == NSEventTypeKeyDown && [event timestamp] != 0) {
        NextApplicationDelegate *delegate = [NSApp delegate];
        NSString *activeWindow = [delegate windowActive];
        NSEventModifierFlags modifierFlags = [event modifierFlags];
        short keyCode = [event keyCode];
        NSString* characters = [event charactersIgnoringModifiers];
        bool controlPressed = (modifierFlags & NSEventModifierFlagControl);
        bool alternatePressed = (modifierFlags & NSEventModifierFlagOption);
        bool commandPressed = (modifierFlags & NSEventModifierFlagCommand);
        bool functionPressed = (modifierFlags & NSEventModifierFlagFunction);
        bool shiftPressed = (modifierFlags & NSEventModifierFlagShift);

        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            xmlrpc_env env = [[Global sharedInstance] getXMLRPCEnv];
            xmlrpc_value * resultP;
            xmlrpc_value * modifiers;
            xmlrpc_int consumed;
            const char * const serverUrl = [[[Global sharedInstance] coreSocket] UTF8String];
            
            modifiers = xmlrpc_array_new(&env);
            
            if (controlPressed) {
                xmlrpc_value * itemP;
                itemP = xmlrpc_string_new(&env, "C");
                xmlrpc_array_append_item(&env, modifiers, itemP);
                xmlrpc_DECREF(itemP);
            };
            if (alternatePressed) {
                xmlrpc_value * itemP;
                itemP = xmlrpc_string_new(&env, "M");
                xmlrpc_array_append_item(&env, modifiers, itemP);
                xmlrpc_DECREF(itemP);
            };
            if (commandPressed) {
                xmlrpc_value * itemP;
                itemP = xmlrpc_string_new(&env, "S");
                xmlrpc_array_append_item(&env, modifiers, itemP);
                xmlrpc_DECREF(itemP);
            };
            if (functionPressed) {
                xmlrpc_value * itemP;
                itemP = xmlrpc_string_new(&env, "F");
                xmlrpc_array_append_item(&env, modifiers, itemP);
                xmlrpc_DECREF(itemP);
            };
            if (shiftPressed) {
                xmlrpc_value * itemP;
                itemP = xmlrpc_string_new(&env, "s");
                xmlrpc_array_append_item(&env, modifiers, itemP);
                xmlrpc_DECREF(itemP);
            };
            
            // Make the remote procedure call
            resultP = xmlrpc_client_call(&env, serverUrl, "PUSH-KEY-EVENT",
                                         "(isAs)",
                                         (xmlrpc_int) keyCode,
                                         [characters UTF8String],
                                         modifiers,
                                         [activeWindow UTF8String]);
            xmlrpc_DECREF(modifiers);
            
            xmlrpc_read_int(&env, resultP, &consumed);
            if (!consumed) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [super sendEvent: [NSEvent keyEventWithType:NSEventTypeKeyDown
                                                       location:[event locationInWindow]
                                                  modifierFlags:[event modifierFlags]
                                                      timestamp:0
                                                   windowNumber:[event windowNumber]
                                                        context:nil
                                                     characters:[event characters]
                                    charactersIgnoringModifiers:[event charactersIgnoringModifiers]
                                                      isARepeat:[event isARepeat]
                                                        keyCode:[event keyCode]]];
                });
            } else {
                xmlrpc_client_call(&env, serverUrl, "CONSUME-KEY-SEQUENCE",
                                   "(s)",
                                   [activeWindow UTF8String]);
            }
        });
    } else {
        [super sendEvent:event];
    }
}

@end

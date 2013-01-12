// Copyright (c) 2006-2008 Simon Fell
//
// Permission is hereby granted, free of charge, to any person obtaining a 
// copy of this software and associated documentation files (the "Software"), 
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, 
// and/or sell copies of the Software, and to permit persons to whom the 
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included 
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
// THE SOFTWARE.
//

#import "ZKPartnerEnvelope.h"

@implementation ZKPartnerEnvelope

- (id)initWithSessionHeader:(NSString *)sessionId clientId:(NSString *)clientId {
	return [self initWithSessionAndMruHeaders:sessionId mru:NO clientId:clientId namespaceUri:@"partner.soap.sforce.com" prefix:@"urn"];
}

// Prefix met =  meta data api
- (id)initWithSessionHeader:(NSString *)sessionId clientId:(NSString *)clientId namespaceUri:(NSString*)primaryNamespceUri prefix:(NSString*)prefix{
	return [self initWithSessionAndMruHeaders:sessionId mru:NO clientId:clientId namespaceUri:primaryNamespceUri prefix:prefix];
}

- (id)initWithSessionAndMruHeaders:(NSString *)sessionId mru:(BOOL)mru clientId:(NSString *)clientId namespaceUri:(NSString*)primaryNamespceUri prefix:(NSString*)prefix{
    
	return [self initWithSessionAndMruHeaders:sessionId mru:mru clientId:clientId namespaceUri:primaryNamespceUri prefix:prefix organisationId:nil portalId:nil];
}

- (id)initWithSessionAndMruHeaders:(NSString *)sessionId mru:(BOOL)mru clientId:(NSString *)clientId namespaceUri:(NSString*)primaryNamespceUri prefix:(NSString*)prefix organisationId:(NSString*)orgId portalId:(NSString*)pid{
    
	self = [super init];

	[self start:primaryNamespceUri prefix:prefix];
    if (![prefix isEqualToString:@""]) {
        [self writeSessionHeader:sessionId prefix:prefix];
        [self writeCallOptionsHeader:clientId  prefix:prefix];
        if (orgId!=nil) {
            [self writeLoginScopeHeaderWithPortalId:pid organisation:orgId prefix:prefix];
        }else{
            if (pid!=nil) {
                [self writeLoginScopeHeaderWithPortalId:pid organisation:orgId prefix:prefix];
            }
        }
        [self writeMruHeader:mru];
        [self moveToBody];
    }else{
       	[self writeSessionHeader:sessionId];
        [self writeCallOptionsHeader:clientId];
        if (orgId!=nil) {
            [self writeLoginScopeHeaderWithPortalId:pid organisation:orgId prefix:prefix];
        }else{
            if (pid!=nil) {
                [self writeLoginScopeHeaderWithPortalId:pid organisation:orgId prefix:prefix];
            }
        }
        [self writeMruHeader:mru];
        [self moveToBody];
    }

	return self;
}

@end

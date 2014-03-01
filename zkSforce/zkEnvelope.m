// Copyright (c) 2006,2013 Simon Fell
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


#import "zkEnvelope.h"
#import "ZKXMLSerializable.h"

@implementation ZKEnvelope

enum envState {
	inEnvelope = 1,
	inHeaders = 2,
	inBody = 3
};

- (void)start:(NSString *)primaryNamespceUri {
	[env release];
	env = [NSMutableString stringWithFormat:@"<s:Envelope xmlns:s='http://schemas.xmlsoap.org/soap/envelope/' xmlns:x='http://www.w3.org/2001/XMLSchema-instance' xmlns='%@'>", primaryNamespceUri];
	state = inEnvelope;
}

- (void)start:(NSString *)primaryNamespceUri prefix:(NSString*)prefix {
	[env release];
    
    if (![prefix isEqualToString:@""]){
        env = [NSMutableString stringWithFormat:@"<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:%@=\"%@\">",prefix, primaryNamespceUri];      
    }else{
       	env = [NSMutableString stringWithFormat:@"<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns=\"%@\">", primaryNamespceUri]; 
    }

	state = inEnvelope;
}

- (void)moveToHeaders {
	if (state == inBody)
		@throw [NSException exceptionWithName:@"Illegal State Exception" reason:@"Unable to write headers once we've moved to the body" userInfo:nil];
	if (state == inHeaders) return;
	[self startElement:@"s:Header"];
	state = inHeaders;
}

- (void)writeSessionHeader:(NSString *)sessionId {
	[self writeSessionHeader:sessionId prefix:@""];
}
- (void)writeSessionHeader:(NSString *)sessionId prefix:(NSString*)prefix{
	if ([sessionId length] == 0) return;
	[self moveToHeaders];
    if (![prefix isEqualToString:@""]) {
        [self startElement:[NSString stringWithFormat:@"%@:SessionHeader",prefix]];
        [self addElement:[NSString stringWithFormat:@"%@:sessionId",prefix]  elemValue:sessionId];
        [self endElement:[NSString stringWithFormat:@"%@:SessionHeader",prefix]];
    }else{
        [self startElement:@"SessionHeader"];
        [self addElement:@"sessionId" elemValue:sessionId];
        [self endElement:@"SessionHeader"];
    }

}
- (void)writeCallOptionsHeader:(NSString *)clientId{
    [self writeCallOptionsHeader:clientId prefix:@""];
}
- (void)writeCallOptionsHeader:(NSString *)clientId  prefix:(NSString*)prefix{
	if ([clientId length] == 0) return;
	[self moveToHeaders];
    if (![prefix isEqualToString:@""]) {
        [self startElement:[NSString stringWithFormat:@"%@:CallOptions",prefix]];
        [self addElement:[NSString stringWithFormat:@"%@:client",prefix]  elemValue:clientId];
        [self endElement:[NSString stringWithFormat:@"%@:CallOptions",prefix]];
    }else{
        [self startElement:@"CallOptions"];
        [self addElement:@"client" elemValue:clientId];
        [self endElement:@"CallOptions"];
    }

}


- (void)writeLoginScopeHeaderWithPortalId:(NSString *)portalId  organisation:(NSString*)oid prefix:(NSString*)prefix  {
	if ([portalId length] == 0) return;
	[self moveToHeaders];
    if (![prefix isEqualToString:@""]) {
        [self startElement:[NSString stringWithFormat:@"%@:LoginScopeHeader",prefix]];
        if (oid!=nil) {
           [self addElement:[NSString stringWithFormat:@"%@:organizationId",prefix]  elemValue:oid]; 
        }
        if (portalId!=nil) {
            [self addElement:[NSString stringWithFormat:@"%@:portalId",prefix]  elemValue:portalId];
        }
        
        [self endElement:[NSString stringWithFormat:@"%@:LoginScopeHeader",prefix]];
    }else{
        [self startElement:@"LoginScopeHeader"];
        if (oid!=nil) {
            [self addElement:@"organizationId"  elemValue:oid];
        }
        if (portalId!=nil) {
            [self addElement:@"portalId"  elemValue:portalId];
        }
        [self endElement:@"LoginScopeHeader"];
    }
    
}



- (void)writeMruHeader:(BOOL)updateMru {
	if (!updateMru) return;
	[self moveToHeaders];
	[self startElement:@"MruHeader"];
	[self addElement:@"updateMru" elemValue:@"true"];
	[self endElement:@"MruHeader"];
}

- (void) moveToBody {
	if (state == inHeaders)
		[self endElement:@"s:Header"];
	if (state != inBody) 
		[self startElement:@"s:Body"];
	state = inBody;
}

- (void) addNullElement:(NSString *)elemName {
    [env appendFormat:@"<%@ x:nil='true'/>", elemName];
}

- (void) addBoolElement:(NSString *)elemName elemValue:(BOOL)elemValue {
    [self addElement:elemName elemValue:(elemValue ? @"true" :@"false")];
}

- (void) addIntElement:(NSString *)elemName elemValue:(NSInteger)elemValue {
    [self addElement:elemName elemValue:[NSNumber numberWithInteger:elemValue]];
}

- (void) addElement:(NSString *)elemName elemValue:(id)elemValue {
    [self addElement:elemName elemValue:elemValue nillable:NO optional:NO];
}

- (void)addSoapPayload:(NSString *)elemName payloadValue:(NSString *)payloadValue {
	[self startElement:elemName];
    [env appendFormat:@"%@", payloadValue];
	[self endElement:elemName];
}


- (void) addElement:(NSString *)elemName elemValue:(id)elemValue nillable:(BOOL)nillable optional:(BOOL)optional {
    if (elemValue == nil) {
        if (optional) return;
        if (nillable) [self addNullElement:elemName];
        else [self addElementString:elemName elemValue:@""];
    } else if ([elemValue isKindOfClass:[NSString class]])    [self addElementString:elemName elemValue:elemValue];
	else if ([elemValue isKindOfClass:[NSArray class]]) 	[self addElementArray:elemName elemValue:elemValue];
	else if ([elemValue isKindOfClass:[ZKSObject class]]) 	[self addElementSObject:elemName elemValue:elemValue];
    else if ([elemValue conformsToProtocol:@protocol(ZKXMLSerializable)]) [elemValue serializeToEnvelope:self elemName:elemName];
	else [self addElementString:elemName elemValue:[elemValue stringValue]];
}

- (void) addElementArray:(NSString *)elemName elemValue:(NSArray *)elemValues {
    for (id o in elemValues)
		[self addElement:elemName elemValue:o];
}

- (void) addElementString:(NSString *)elemName elemValue:(NSString *)elemValue {
	[self startElement:elemName];
	[self writeText:elemValue];
	[self endElement:elemName];
}

- (void) addElementSObject:(NSString *)elemName elemValue:(ZKSObject *)sobject {
	[self startElement:elemName];
	[self addElement:@"type" elemValue:[sobject type]];
	[self addElement:@"fieldsToNull" elemValue:[sobject fieldsToNull]];
	if ([sobject id]) 
		[self addElement:@"Id" elemValue:[sobject id]];
    
	NSEnumerator *e = [[sobject fields] keyEnumerator];
	NSString *key;
	while((key = [e nextObject])) {
		[self addElement:key elemValue:[[sobject fields] valueForKey:key]];
	}
	[self endElement:elemName];
}

- (void) writeText:(NSString *)text  {
	unichar c;
	NSUInteger i, len = [text length];
	for (i = 0; i < len; i++)
	{
		c = [text characterAtIndex:i];
		switch (c)
		{
			case '<' : [env appendString:@"&lt;"]; break;
			case '>' : [env appendString:@"&gt;"]; break;
			case '&' : [env appendString:@"&amp;"]; break;
			default  : [env appendFormat:@"%C", c];
		}
	}
}

- (void )startElement:(NSString *)elemName {
	[env appendFormat:@"<%@>", elemName];
}

- (void )endElement:(NSString *)elemName {
	[env appendFormat:@"</%@>", elemName];
}

- (NSString *)end {
    if (state == inHeaders)
        [self endElement:@"s:Header"];
    if (state == inBody)
        [self endElement:@"s:Body"];
    [self endElement:@"s:Envelope"];
	return env;
}

@end

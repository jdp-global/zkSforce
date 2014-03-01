// Copyright (c) 2006,2013,2014 Simon Fell
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

#import "zkXmlDeserializer.h"
#import "zkParser.h"
#import "ZKBase64.h"
#import "ZKSoapDate.h"
#import "zkSObject.h"
#import "zkQueryResult.h"

static NSString *SCHEMA_INSTANCE_NS = @"http://www.w3.org/2001/XMLSchema-instance";

@implementation ZKXmlDeserializer

-(id)initWithXmlElement:(zkElement *)e {
	self = [super init];
	node = [e retain];
	values = [[NSMutableDictionary alloc] init];
	return self;
}

-(void)dealloc {
	[node release];
	[values release];
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithXmlElement:node];
}

- (NSString *)string:(NSString *)elem {
	id cached = [values objectForKey:elem];
	if (cached != nil) return cached == [NSNull null] ? nil : cached;
	id v = [self string:elem fromXmlElement:node];
	[values setObject:(v != nil ? v : [NSNull null]) forKey:elem];
	return v;
}

- (BOOL)boolean:(NSString *)elem {
	return [[self string:elem] isEqualToString:@"true"];
}

- (int)integer:(NSString *)elem {
	return [[self string:elem] intValue];
}

- (double)double:(NSString *)elem {
	return [[self string:elem] doubleValue];
}

- (NSDate *)date:(NSString *)elem {
    return [[ZKSoapDate instance] fromDateString:[self string:elem]];
}

- (NSDate *)dateTime:(NSString *)elem {
    return [[ZKSoapDate instance] fromDateTimeString:[self string:elem]];
}

- (ZKSObject *)sObject:(NSString *)elem {
    return [[self complexTypeArrayFromElements:elem cls:[ZKSObject class]] lastObject];
}

- (ZKQueryResult *)queryResult:(NSString *)elem {
    return [[self complexTypeArrayFromElements:elem cls:[ZKQueryResult class]] lastObject];
}

- (NSData *)blob:(NSString *)elem {
    NSData *cached = [values objectForKey:elem];
    if (cached == nil) {
        NSString *b64 = [self string:elem fromXmlElement:node];
        cached = [b64 ZKBase64Decode];
        [values setObject:cached forKey:elem];
    }
    return cached;
}

- (NSArray *)strings:(NSString *)elem {
	NSArray *cached = [values objectForKey:elem];
	if (cached != nil) return cached;
	NSArray *nodes = [node childElements:elem];
	NSMutableArray *s = [NSMutableArray arrayWithCapacity:[nodes count]];
	for (zkElement *e in nodes) 
		[s addObject:[e stringValue]];
	
	[values setObject:s forKey:elem];
	return s;
}

- (NSString *)string:(NSString *)elemName fromXmlElement:(zkElement*)xmlElement {
	return [[xmlElement childElement:elemName] stringValue];
}

-(Class)parseType:(NSString *)xsiType baseClass:(Class)base {
    if ([xsiType length] == 0) return base;
    NSString *typeName = [[xsiType componentsSeparatedByString:@":"] lastObject];
    NSString *className = [NSString stringWithFormat:@"ZK%@%@", [[typeName substringToIndex:1] uppercaseString], [typeName substringFromIndex:1]];
    Class cls = NSClassFromString(className);
    return cls != nil && [cls isSubclassOfClass:base] ? cls : base;
}

- (NSArray *)complexTypeArrayFromElements:(NSString *)elemName cls:(Class)type {
	NSArray *cached = [values objectForKey:elemName];
	if (cached == nil) {
		NSArray *elements = [node childElements:elemName];
		NSMutableArray *results = [NSMutableArray arrayWithCapacity:[elements count]];
		for(zkElement *childNode in elements) {
            NSString *xsiType = [childNode attributeValue:@"type" ns:SCHEMA_INSTANCE_NS];
            Class actualType = [self parseType:xsiType baseClass:(Class)type];
			NSObject *child = [[actualType alloc] initWithXmlElement:childNode];
			[results addObject:child];
			[child release];
		}
		[values setObject:results forKey:elemName];
		cached = results;
	}
	return cached;
}

@end

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

#import "zkBaseClient.h"
#import "zkSoapException.h"
#import "zkParser.h"
#import "XMLReader.h"

@implementation ZKBaseClient

static NSString *SOAP_NS = @"http://schemas.xmlsoap.org/soap/envelope/";

@synthesize endpointUrl;

- (void)dealloc {
	[endpointUrl release];
	[super dealloc];
}

- (zkElement *)sendRequest:(NSString *)payload {
	return [self sendRequest:payload returnRoot:NO];
}
/*

be sure to backspace ! in token eg. test! = test\!
curl -d "<s:Envelope xmlns:s='http://schemas.xmlsoap.org/soap/envelope/' xmlns='urn:partner.soap.sforce.com'><s:Header><SessionHeader><sessionId>test\!ARwAQKUTdc3ypwRwLOBNeXnPjHKHkjSrGE1zU.keP_L006e7i7fBWCAMcmIlJ8.ZsMg9er856TgMFEYhgipJCkt95FcTJIHg</sessionId></SessionHeader></s:Header><s:Body><describeGlobal></describeGlobal></s:Body></s:Envelope>" https://na14.salesforce.com/services/Soap/u/26.0 -H "Content-Type:text/xml"  -H 'SOAPAction: ""'
 
 */

- (zkElement *)sendRequest:(NSString *)payload returnRoot:(BOOL)returnRoot {
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:endpointUrl];
    NSLog(@"endpointUrl:%@",[endpointUrl absoluteString]);
	[request setHTTPMethod:@"POST"];
	[request addValue:@"text/xml; charset=UTF-8" forHTTPHeaderField:@"content-type"];	
	[request addValue:@"\"\"" forHTTPHeaderField:@"SOAPAction"];
	NSLog(@"payload %@",payload);
	NSData *data = [payload dataUsingEncoding:NSUTF8StringEncoding];
	[request setHTTPBody:data];
	
	NSHTTPURLResponse *resp = nil;
	NSError *err = nil;
	// todo, support request compression
	// todo, support response compression
	NSData *respPayload = [NSURLConnection sendSynchronousRequest:request returningResponse:&resp error:&err];
	NSLog(@"response \r\n%@", [NSString stringWithCString:[respPayload bytes] length:[respPayload length]]);
	zkElement *root = [zkParser parseData:respPayload];
	if (root == nil)	
		@throw [NSException exceptionWithName:@"Xml error" reason:@"Unable to parse XML returned by server" userInfo:nil];
	if (![[root name] isEqualToString:@"Envelope"])
		@throw [NSException exceptionWithName:@"Xml error" reason:[NSString stringWithFormat:@"response XML not valid SOAP, root element should be Envelope, but was %@", [root name]] userInfo:nil];
	if (![[root namespace] isEqualToString:SOAP_NS])
		@throw [NSException exceptionWithName:@"Xml error" reason:[NSString stringWithFormat:@"response XML not valid SOAP, root namespace should be %@ but was %@", SOAP_NS, [root namespace]] userInfo:nil];
	zkElement *body = [root childElement:@"Body" ns:SOAP_NS];
	if (500 == [resp statusCode]) {
		zkElement *fault = [body childElement:@"Fault" ns:SOAP_NS];
		if (fault == nil)
			@throw [NSException exceptionWithName:@"Xml error" reason:@"Fault status code returned, but unable to find soap:Fault element" userInfo:nil];
		NSString *fc = [[fault childElement:@"faultcode"] stringValue];
		NSString *fm = [[fault childElement:@"faultstring"] stringValue];
        //DLog(@"WARNING: faultcode: %@",fc);
        //DLog(@"WARNING: faultstring: %@",fm);
        
		@throw [ZKSoapException exceptionWithFaultCode:fc faultString:fm];
	}
	return returnRoot ? root : [[body childElements] objectAtIndex:0];
}

// Return a vanilla json /nsdictionary response
- (NSDictionary *)fireRequest:(NSString *)payload  {

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:endpointUrl];
	[request setHTTPMethod:@"POST"];
	[request addValue:@"text/xml; charset=UTF-8" forHTTPHeaderField:@"content-type"];
	[request addValue:@"\"\"" forHTTPHeaderField:@"SOAPAction"];
	[request addValue:@"gzip,deflate" forHTTPHeaderField:@"Accepts-Encoding"];
    
    NSLog(@"payload:%@",payload);
	NSData *data = [payload dataUsingEncoding:NSUTF8StringEncoding];
	[request setHTTPBody:data];
	
	NSHTTPURLResponse *resp = nil;
	NSError *err = nil;

	NSData *respPayload = [NSURLConnection sendSynchronousRequest:request returningResponse:&resp error:&err];
	
    NSString* newStr = [NSString stringWithUTF8String:[respPayload bytes]];
   // NSLog(@"response %@", newStr);
    
    NSError *parseError = nil;  
    NSDictionary *dict = [XMLReader dictionaryForXMLString:newStr error:&parseError];
   // NSLog(@"dict %@", dict);
    NSDictionary *root = [[dict objectForKey:@"soapenv:Envelope"] objectForKey:@"soapenv:Body"];

	if (root == nil){
        NSLog(@"WARNING: - this dictionary didn't return properly for soapenv:Envelope :%@", dict);
      	@throw [NSException exceptionWithName:@"Xml error" reason:@"Unable to parse XML returned by server" userInfo:nil];  
    }
	

	return root;
}


- (NSDictionary *)fireMetaDataRequest:(NSString *)payload  {
    NSString* metaDataUrl = [[endpointUrl absoluteString] stringByReplacingOccurrencesOfString:@"Soap/u/" withString:@"Soap/m/"];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:metaDataUrl]];
    NSLog(@"metaDataEndpointUrl:%@",[request.URL absoluteString]);
	[request setHTTPMethod:@"POST"];
	[request addValue:@"text/xml; charset=UTF-8" forHTTPHeaderField:@"content-type"];
	[request addValue:@"\"\"" forHTTPHeaderField:@"SOAPAction"];
	[request addValue:@"gzip,deflate" forHTTPHeaderField:@"Accepts-Encoding"];
    NSLog(@"payload %@ ",payload);
    
	NSData *data = [payload dataUsingEncoding:NSUTF8StringEncoding];
	[request setHTTPBody:data];
	
	NSHTTPURLResponse *resp = nil;
	NSError *err = nil;
    
	NSData *respPayload = [NSURLConnection sendSynchronousRequest:request returningResponse:&resp error:&err];
	
    NSString* newStr = [NSString stringWithUTF8String:[respPayload bytes]];
     NSLog(@"response %@", newStr);
    
    NSError *parseError = nil;
    NSDictionary *dict = [XMLReader dictionaryForXMLString:newStr error:&parseError];
     NSLog(@"dict %@", dict);
    NSDictionary *root = [[dict objectForKey:@"soapenv:Envelope"] objectForKey:@"soapenv:Body"];
    
	if (root == nil){
        NSLog(@"WARNING: - this dictionary didn't return properly for soapenv:Envelope :%@", dict);
      	@throw [NSException exceptionWithName:@"Xml error" reason:@"Unable to parse XML returned by server" userInfo:nil];
    }
	
    
	return root;
}


@end

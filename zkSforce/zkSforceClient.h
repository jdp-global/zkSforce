// Copyright (c) 2006-2013 Simon Fell
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
#import "zkAuthentication.h"

@class ZKUserInfo;
@class ZKDescribeSObject;
@class ZKQueryResult;
@class ZKLoginResult;
@class ZKDescribeLayoutResult;
@class ZKLimitInfoHeader;
@class ZKEnvelope;
@class ZKCallOptions;
@class ZKPackageVersionHeader;
@class ZKLocaleOptions;
@class ZKAssignmentRuleHeader;
@class ZKMruHeader;
@class ZKAllowFieldTruncationHeader;
@class ZKDisableFeedTrackingHeader;
@class ZKStreamingEnabledHeader;
@class ZKAllOrNoneHeader;
@class ZKDebuggingHeader;
@class ZKEmailHeader;
@class ZKOwnerChangeOptions;
@class ZKUserTerritoryDeleteHeader;
@class ZKQueryOptions;

// This is the primary entry point into the library, you'd create one of these
// call login, then use it to make other API calls. Your session is automatically
// kept alive, and login will be called again for you if needed.
//////////////////////////////////////////////////////////////////////////////////////
@interface ZKSforceClient : ZKBaseClient <NSCopying> {
	NSString	*authEndpointUrl;
	ZKUserInfo	*userInfo;
	BOOL		cacheDescribes;
	NSMutableDictionary	*describes;
	int			preferedApiVersion;

    NSObject<ZKAuthenticationInfo>  *authSource;
    ZKLimitInfoHeader *limitInfo;
    
    // Soap Headers on requests
    ZKCallOptions           *callOptions;
    ZKPackageVersionHeader  *packageVersionHeader;
    ZKLocaleOptions         *localeOptions;
    ZKAssignmentRuleHeader  *assignmentRuleHeader;
    ZKMruHeader             *mruHeader;
    ZKAllowFieldTruncationHeader *allowFieldTruncationHeader;
    ZKDisableFeedTrackingHeader  *disableFeedTrackingHeader;
    ZKStreamingEnabledHeader     *streamingEnabledHeader;
    ZKAllOrNoneHeader            *allOrNoneHeader;
    ZKDebuggingHeader            *debuggingHeader;
    ZKEmailHeader                *emailHeader;
    ZKOwnerChangeOptions         *ownerChangeOptions;
    ZKUserTerritoryDeleteHeader  *userTerritoryDeleteHeader;
    ZKQueryOptions               *queryOptions;
}

// configuration for where to connect to and what api version to use
//////////////////////////////////////////////////////////////////////////////////////
// Set the default API version to connect to. (defaults to v29.0)
// login will automatically detect if the endpoint doesn't have this
// version and automatically retry on a lower API version.
@property (assign) int preferedApiVersion;

// What endpoint to connect to? this should just be the protocol and host
// part of the URL, e.g. https://test.salesforce.com
-(void)setLoginProtocolAndHost:(NSString *)protocolAndHost;

// set both the endpoint to connect to, and an explicit API version to use.
-(void)setLoginProtocolAndHost:(NSString *)protocolAndHost andVersion:(int)version;

// returns an NSURL of where authentication will currently go.
-(NSURL *)authEndpointUrl;

//////////////////////////////////////////////////////////////////////////////////////
// Start an API session, need to call one of these before making any api calls
//////////////////////////////////////////////////////////////////////////////////////

// Attempt a login request. If a security token is required to be used you need to
// append it to the password parameter.
- (ZKLoginResult *)login:(NSString *)username password:(NSString *)password;


- (ZKLoginResult *)login:(NSString *)un password:(NSString *)pwd organisationId:(NSString*)orgId portalId:(NSString*)pid;;

// Initialize the authentication info from the parameters contained in the OAuth
// completion callback Uri passed in.
// call this when the oauth flow is complete, this doesn't start the oauth flow.
- (void)loginFromOAuthCallbackUrl:(NSString *)callbackUrl oAuthConsumerKey:(NSString *)oauthClientId;

// Login by making a refresh token request with this refresh Token to the specifed
// authentication host. oAuthConsumerKey is the oauth client_id / consumer key
- (void)loginWithRefreshToken:(NSString *)refreshToken authUrl:(NSURL *)authUrl oAuthConsumerKey:(NSString *)oauthClientId;

// Attempt a login for a portal User.
// OrgId is required, and should be the Id of the organization that owns the portal.
// PortalId is required for new generation portals, can be null for old style self service portals.
// In the case of self service portals, you can ony authenticate users, they don't have access
// to the rest of the API, attempts to call other API methods will return an error.
- (ZKLoginResult *)portalLogin:(NSString *)username password:(NSString *)password orgId:(NSString *)orgId portalId:(NSString *)portalId;

// Authentication Management
// This lets you manage different authentication schemes, like oauth
// Normally you'd just call login:password or loginFromOAuthCallbackUrl:
// which will create a ZKAuthenticationInfo object for you.
//////////////////////////////////////////////////////////////////////////////////////
@property (retain) NSObject<ZKAuthenticationInfo> *authenticationInfo;


// thse set of methods pretty much map directly onto their Web Services counterparts.
// These methods will throw a ZKSoapException if there's an error.
//////////////////////////////////////////////////////////////////////////////////////

// makes a desribeGlobal call and returns an array of ZKDescribeGlobalSobject instances.
// if describeCaching is enabled, subsequent calls to this will use the locally cached
// copy.
- (NSArray *)describeGlobal;

// makes a describeSObject call and returns a ZKDescribeSObject instance, if describe
// caching is enabled, subsequent requests for the same sobject will return the locally
// cached copy.
- (ZKDescribeSObject *)describeSObject:(NSString *)sobjectName;

// makes a search call with the passed in SOSL expression, returns an array of ZKSObject
// instances.
- (NSArray *)search:(NSString *)sosl;

// retreives a set of records, fields is a comma separated list of fields to fetch values for
// ids can be upto 200 record Ids, the returned dictionary is keyed from Id and the dictionary
// values are ZKSObject's.
- (NSDictionary *)retrieve:(NSString *)fields sObjectType:(NSString *)sobjectType ids:(NSArray *)ids;
// old signature of this method, same impl as above
- (NSDictionary *)retrieve:(NSString *)fields sobject:(NSString *)sobjectType ids:(NSArray *)ids;

// pass an array of ZKSObject's to create in salesforce, returns a matching array of ZKSaveResults
- (NSArray *)create:(NSArray *)objects;

// pass an array of ZKSObject's to update in salesforce, returns a matching array of ZKSaveResults
- (NSArray *)update:(NSArray *)objects;

//////////////////////////////////////////////////////////////////////////////////////
// Other methods from the WSDL such as delete, query, merge, etc are all declared in
// ZKSforceClient+Operations.h
//////////////////////////////////////////////////////////////////////////////////////

- (NSDictionary*)describeMetaData;
- (NSDictionary *)listMetaDataWithType:(NSString*)qType folder:(NSString*)folder;

// Information about the current session
//////////////////////////////////////////////////////////////////////////////////////
// returns true if we've performed a login request and it succeeded.
- (BOOL)loggedIn;

// the UserInfo returned by the last call to login.
- (ZKUserInfo *)currentUserInfo;

// the current endpoint URL where requests are being sent.
- (NSURL *)serverUrl;

// the current API session Id being used to make requests.
- (NSString *)sessionId;

// the short name of the current serverUrl, e.g. na1, eu0, cs5 etc, if the short name ends in -api, the -api part will be removed.
- (NSString *)serverHostAbbriviation;

//////////////////////////////////////////////////////////////////////////////////////
// SOAP Headers
//////////////////////////////////////////////////////////////////////////////////////
// contains the last received LimitInfoHeader we got from the server.
@property (readonly) ZKLimitInfoHeader *lastLimitInfoHeader;

// These 3 are for backwards compat, they will update the relevant header property
// Should create/update calls also update the users MRU info? (defaults false)
@property (assign) BOOL updateMru;

// If you have a clientId for a certifed partner application, you can set it here.
@property (retain) NSString *clientId;

// If you want to change the batch size for queries, you can set this to 200-2000, the default is null. (uses the server side default)
@property (retain) NSNumber *queryBatchSize;

@property (retain) ZKCallOptions                *callOptions;
@property (retain) ZKPackageVersionHeader       *packageVersionHeader;
@property (retain) ZKLocaleOptions              *localeOptions;
@property (retain) ZKAssignmentRuleHeader       *assignmentRuleHeader;
@property (retain) ZKMruHeader                  *mruHeader;
@property (retain) ZKAllowFieldTruncationHeader *allowFieldTruncationHeader;
@property (retain) ZKDisableFeedTrackingHeader  *disableFeedTrackingHeader;
@property (retain) ZKStreamingEnabledHeader     *streamingEnabledHeader;
@property (retain) ZKAllOrNoneHeader            *allOrNoneHeader;
@property (retain) ZKDebuggingHeader            *debuggingHeader;
@property (retain) ZKEmailHeader                *emailHeader;
@property (retain) ZKOwnerChangeOptions         *ownerChangeOptions;
@property (retain) ZKUserTerritoryDeleteHeader  *userTerritoryDeleteHeader;
@property (retain) ZKQueryOptions               *queryOptions;

// describe caching support, if true, describeGlobal & describeSObject call results are cached.
//////////////////////////////////////////////////////////////////////////////////////
@property (assign) BOOL cacheDescribes;
- (void)flushCachedDescribes;



@end


// These are helper methods used by the Operations category, you shouldn't need to call these directly 
@interface ZKSforceClient (Helpers)
-(void)checkSession;
-(void)updateLimitInfo;
-(void)addCallOptions:(ZKEnvelope *)env;
-(void)addPackageVersionHeader:(ZKEnvelope *)env;
-(void)addLocaleOptions:(ZKEnvelope *)env;
-(void)addAssignmentRuleHeader:(ZKEnvelope *)env;
-(void)addMruHeader:(ZKEnvelope *)env;
-(void)addAllowFieldTruncationHeader:(ZKEnvelope *)env;
-(void)addDisableFeedTrackingHeader:(ZKEnvelope *)env;
-(void)addStreamingEnabledHeader:(ZKEnvelope *)env;
-(void)addAllOrNoneHeader:(ZKEnvelope *)env;
-(void)addDebuggingHeader:(ZKEnvelope *)env;
-(void)addEmailHeader:(ZKEnvelope *)env;
-(void)addOwnerChangeOptions:(ZKEnvelope *)env;
-(void)addUserTerritoryDeleteHeader:(ZKEnvelope *)env;
-(void)addQueryOptions:(ZKEnvelope *)env;
@end


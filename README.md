# zkSforce README

zkSforce is a cocoa library for calling the [Salesforce.com Web Services APIs](http://www.salesforce.com/us/developer/docs/api/index.htm), easily integrate Salesforce into your OSX and iOS projects. (supports OSX 10.7+, iOS 6+)

zkSforce supports all of the partner web services API, including

 * login, getUserInfo, serverTimestamp, setPassword, resetPassword
 * describeGlobal, describeSObject, describeLayout, describeTabs and other describes.
 * create, update, delete, undelete, merge, upsert, convertLead
 * search, query, queryAll, queryMore, retrieve, process.
 * everything else in the parter API.
 * OAuth support for refresh tokens


In general the client acts just like the Web Services API, however in a few places it has some smarts to make your life easier.

 * it'll track the duration of the session and re-login as required, so just keep calling methods as needed and don't worry about the session expiring away from under you.
 * in ZKDescribeSObject there's a helper method to get the ZKDescribeField given the fields name.
 * In ZKSObject the fieldsToNull collection is managed for you, if you add a field to the fieldsToNull collection (via setFieldToNull) it'll automatically remove any field value, also you can just set the field value directly to nil (aka null) in setFieldValue:field: and it'll automatically translate that into a fieldsToNull call for you.
 * ZKQueryResult implements the NSTableView informal data source interface, so you can easily show a queries results in a table view (just like SoqlX does)
 * You can ask the ZKSforceClient object to automatically cache describeGlobal/describeSObject results for you by calling setCacheDescribes


Usage is really straight forward, create an instance of the [ZKSforceClient](https://github.com/superfell/zkSforce/blob/master/zkSforce/zkSforceClient.h) class, call login, then call the other operations as needed, e.g.

Login and find the URL to the new Task UI Page.

        ZKSforceClient *sforce = [[ZKSforceClient alloc] init];
        [sforce login:username password:password];
        ZKDescribeSObject *taskDescribe = [sforce describeSObject:@"Task"];
        NSLog(@"url for the new Task page is %@", [taskDescribe urlNew]);	
        [sforce release];


Login and create a new contact for Simon Fell, and check the result

        ZKSforceClient *sforce = [[ZKSforceClient alloc] init];
        [sforce login:username password:password];
        ZKSObject *contact = [ZKSObject withType:@"Contact"];
        [contact setFieldValue:@"Fell" field:@"LastName"];
        [contact setFieldValue:@"Simon" field:@"FirstName"];
        NSArray *results = [sforce create:[NSArray arrayWithObject:contact]];
        ZKSaveResult *sr = [results objectAtIndex:0];
        if ([sr success])
	        NSLog(@"new contact id %@", [sr id]);
        else
	        NSLog(@"error creating contact %@ %@", [sr statusCode], [sr message]);
        [sforce release];

		
Calls are made synchronously on the thread making the call (and therefore you shouldn't really call it directly from the UI thread), zkSforceClient+zkAsyncQuery.h has a versions of all the calls that are asynchronous and use blocks to get completion/error callbacks.

		[client performQuery:query 
        	failBlock:^(NSException *ex) {
				[self showError:ex];
        	} 
        	completeBlock:^(ZKQueryResult *qr) {
				[self setResult:qr];
				[table setDataSource:qr];
				[table reloadData];
        	}];

As well as the traditional username and password login, there's also support for working with OAuth based authentication, you can pass it the finalized callbackURL you receive at the end of the oauth login flow, and it'll automatically extract all the parameters it needs from that URL.

		ZKSforceClient *sforce = [[ZKSforceClient alloc] init];
		[sforce loginFromOAuthCallbackUrl:callbackUrl oAuthConsumerKey:OAUTH_CLIENTID];
		// use as normal


You'll need to store the refresh_token and authHost somewhere safe, like the keychain, then when you restart, you can pass these to ZKSforceClient to initialize it, it'll automatically use the refresh token service to get a new sessionId.

	ZKSforceClient *sforce = [[ZKSforceClient alloc] init];
	[sforce loginWithRefreshToken:refreshToken authUrl:authHost oAuthConsumerKey:OAUTH_CLIENTID];
	// use as normal
	// See the OAuthDemo sample for more info.
	

# Updating from older versions
v29 is a major update where a significant amount of the code is now code-generated from the partner WSDL, because of this there are a number of API changes that might affect an existing project that you're trying to update to this version of zkSforce.

 * some files have had the casing of their filename fixed to match the classname (e.g. zkChildRelationship.h is now ZKChildRelationship.h)
 * The Id property on ZKDescribeLayout is now called id
 * message & statusCode properties on ZKSaveResult have been moved to an Extras category/file
 * describe & fieldsColumnNames properties on ZKRelatedList have been moved to an Extras category/file
 * many properties on ZKUserInfo are now in an Extras category/file
 * licenceType from ZKUserInfo was removed (its not longer in the API)
 * validFor on ZKPicklistEntry now returns an NSData rather than an NSString
 * the signature for setPassword has changed from setPassword:forUserId: to setPassword:userId:
 * delete now returns an NSArray of ZKDeleteResult rather than an NSArray of ZKSaveResult (note that these 2 types both have the same properties though)
 * the serverTimestamp method is replaced by getServerTimestamp, and now returns a ZKGetServerTimestampResult class with a timestamp member (of type NSDate) instead of returning a string.
 * the componentType enum was removed from ZKDescribeLayoutComponent
 * on ZKDecribeGlobalSObject defaultOnCreate is now defaultedOnCreate, undeleteable is now deletable, deleteable is now deletable
 * on OSX you need to add Security framework to the list of frameworks to link against.



## Project setup (via CocoaPods)

The easiest way to get ZKSforce integrated into your app is to use [CocoaPods](http://cocoapods.org/), the new Cocoa dependency manager framework, simply create a Podfile, e.g.

    platform :osx
	pod 'ZKSforce', '29'
	
and run  `pod install myApp.xcodeproj`


## Project setup (manual)

In order to support usage on both OSX & iOS, the library now uses libxml as its XML parser rather than NSXML, which isn't fully implemented on iOS. Once you've added all the .h & .m files to your project, you'll need to goto the build settings and add /usr/include/libxml2 to the Header Search Paths, and add libxml2.dylib to the linked frameworks section, and then you should be good to go. For OSX you'll also need to add Security framework to the list of linked Frameworks. The [Wiki](https://github.com/superfell/zkSforce/wiki/Creating-a-new-project-that-uses-zkSforce) has a detailed write up on these steps.



## Helper methods

This fork of zkSForce has a single method that allows you to get dirty with SOAP API without having to know about the >200 boiler plate model classes or regenerating code from wsdl.
As long as you know how to structure the payload - you can simply inject any soapString here 
    NSDictionary *dict = [client doSoapCallWithMethod:@"create" payload:soapString];
The SOAP response is parsed using XMLReader ARC version. https://github.com/RyanCopley/XMLReader That's it.

    // Not sure of the correct soap string? You can use curl to test - just switch in sessionids and replace any ! with \!.
    curl -d "<s:Envelope xmlns:s='http://schemas.xmlsoap.org/soap/envelope/' xmlns='urn:partner.soap.sforce.com'><s:Header><SessionHeader><sessionId>REPLACETHEEXCLAMATIONWITHBACKSLASH!!!!!\\\\\\\\!!!!!!!</sessionId></SessionHeader></s:Header><s:Body>
          
     /// just iterate over your collection append the 
     <create>
         <sObjects>
             <type>FieldStorm__Check_In__c</type>
             <OwnerId>005d0000000rfBUAAY</OwnerId>
             <FieldStorm__AccountId__c>001d000000V4CA4AAN</FieldStorm__AccountId__c>
             <FieldStorm__UserId__c>005d0000000rfBUAAY</FieldStorm__UserId__c>
          </sObjects>
          <sObjects>
              <type>FieldStorm__Check_In__c</type>
              <OwnerId>005d0000000rfBUAAY</OwnerId>
              <Name>(null)</Name>
              <FieldStorm__AccountId__c>001d000000V4CA4AAN</FieldStorm__AccountId__c>
              <FieldStorm__CheckInTime__c>
          </sObjects>
       </create>
               //end paste
           
    </s:Body></s:Envelope>" https://na14.salesforce.com/services/Soap/u/29.0 -H "Content-Type:text/xml"  -H 'SOAPAction: ""'

So here - the soap string is

       NSSString *soapString   = @"<sObjects>"
        ""<type>FieldStorm__Check_In__c</type>"
        "<OwnerId>005d0000000rfBUAAY</OwnerId>"
        "<FieldStorm__AccountId__c>001d000000V4CA4AAN</FieldStorm__AccountId__c>"
        "<FieldStorm__UserId__c>005d0000000rfBUAAY</FieldStorm__UserId__c>"
       "</sObjects>"
       "<sObjects>"
         "<type>FieldStorm__Check_In__c</type>"
         "<OwnerId>005d0000000rfBUAAY</OwnerId>"
         "<Name>(null)</Name>"
         "<FieldStorm__AccountId__c>001d000000V4CA4AAN</FieldStorm__AccountId__c>"
         "<FieldStorm__CheckInTime__c>"
        "</sObjects>"


     ZKSforceClient *client = [[ZKSforceClient alloc] init];
        [client login:username password:password];
     	[client performRequest:^id {
    		  return [self doSoapCallWithMethod:@"create" payload:soapString];
    		}
    		 checkSession:NO
    		    failBlock:^(NSException *e) {
                        NSLog(@"exception:%@", e);
            }
    		completeBlock: ^(id results) {
                        NSLog(@"dict:%@", results);
            }];
		
		
	
returns this


    dict:{
    createResponse =     {
        result =         (
                        {
                id =                 {
                    text = 00T9000000en4XKEAY;
                };
                success =                 {
                    text = true;
                };
            },
                        {
                id =                 {
                    text = 00T9000000en4XLEAY;
                };
                success =                 {
                    text = true;
                };
            },
                etc...
        );
    };

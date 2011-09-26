//
//  SettingsViewController.m
//  UAV
//
//  Created by Eric Dong on 8/18/10.
//  Copyright 2010 NUS. All rights reserved.
//

#import "SettingsViewController.h"

#define MAX_INCOMING_DATA_LENGTH 200
#define MAX_DISPLAY_DATA_LENGTH 13

@implementation SettingsViewController

@synthesize connectSwitch;
@synthesize status;
@synthesize connected;
@synthesize notConnected;
@synthesize consoleInput;
@synthesize uavIP;
@synthesize viewControllersFull;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	slider1.transform = CGAffineTransformMakeRotation(M_PI/2);
	slider2.transform = CGAffineTransformMakeRotation(M_PI/2);
	slider3.transform = CGAffineTransformMakeRotation(M_PI/2);
	slider4.transform = CGAffineTransformMakeRotation(M_PI/2);
	slider5.transform = CGAffineTransformMakeRotation(M_PI/2);
	slider6.transform = CGAffineTransformMakeRotation(M_PI/2);
	slider7.transform = CGAffineTransformMakeRotation(M_PI/2);
	slider8.transform = CGAffineTransformMakeRotation(M_PI/2);
	
	const int diff = 44;
	const int first = 112;
	slider1.center = CGPointMake(first+diff*0, 550);
	slider2.center = CGPointMake(first+diff*1, 550);
	slider3.center = CGPointMake(first+diff*2, 550);
	slider4.center = CGPointMake(first+diff*3, 550);
	slider5.center = CGPointMake(first+diff*4, 550);
	slider6.center = CGPointMake(first+diff*5, 550);
	slider7.center = CGPointMake(first+diff*6, 550);
	slider8.center = CGPointMake(first+diff*7, 550);
	
	slider1.maximumValue = 255;
	slider2.maximumValue = 255;
	slider3.maximumValue = 255;
	slider4.maximumValue = 255;
	slider5.maximumValue = 255;
	slider6.maximumValue = 255;
	slider7.maximumValue = 255;
	slider8.maximumValue = 255;
	
	sliderLabel1.text = @"H";
	sliderLabel2.text = @"S";
	sliderLabel3.text = @"RL";
	sliderLabel4.text = @"RU";
	sliderLabel5.text = @"BL";
	sliderLabel6.text = @"BU";
	sliderLabel7.text = @"GL";
	sliderLabel8.text = @"GU";
	
	[self setEnableSliders:NO];
	
	uavIP.text = [@"UAV IP: " stringByAppendingString:[UAV sharedInstance].uavIP] ;
	prevRow = 0;
	[connected setHidden:YES];// = YES;
	notConnected.hidden = YES;
#if !(TARGET_IPHONE_SIMULATOR)
	
	InitAddresses();
	GetHWAddresses();
	GetIPAddresses();
	
	defaultConnectedText = [NSString stringWithFormat:@"GCS IP: %s", ip_names[1]];
	
	if (![defaultConnectedText isEqualToString:@"GCS IP: 192.168.1.2"]) {
		[[[[UIAlertView alloc]  initWithTitle:@"Not connected to WiFi" message:@"Wrong IP, not 192.168.1.2" delegate:self cancelButtonTitle:@"Ok"  otherButtonTitles:nil] autorelease] show];
	}
	status.text = defaultConnectedText;
#else
	status.text = @"Not supported on simulator";
#endif
	int rv;
	struct sockaddr_in iPhoneAddr;
	connectSwitch.on = YES;
	connectSwitch.enabled = NO;
	sockfd = socket(AF_INET, SOCK_DGRAM, 0);
	if (sockfd == -1)
	{
		status.text = @"Fail to create socket";
		return;
	}	
	//getAddrinfo(
	bzero(&iPhoneAddr, sizeof(iPhoneAddr));
	iPhoneAddr.sin_family = AF_INET;
	iPhoneAddr.sin_addr.s_addr = htonl(INADDR_ANY);//htonl(hostlong);
	iPhoneAddr.sin_port = htons(9001);
	rv = bind(sockfd, (struct sockaddr *)&iPhoneAddr, sizeof(iPhoneAddr));
	if (rv == -1)
	{
		close(sockfd);
		status.text = @"Fail to bind socket";
		return;
	} else {
		status.text = defaultConnectedText;
	}
	
	// create and initialize a mutex lock that control access to shared data between threads		
	// create a thread to monitor incoming data and a thread to update the display
	[NSThread detachNewThreadSelector:@selector(checkForIncomingData) toTarget:self withObject:nil];	
	
	//attempt to initiate connection to the UAV. 
	
	NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http:/%@", [UAV sharedInstance].uavIP]] 
												cachePolicy:NSURLRequestUseProtocolCachePolicy
											timeoutInterval:0.5];
	
	[[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
	
	[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(ping) userInfo:nil repeats:YES];
	
	sqlArray = [[NSMutableArray array] retain];
	[self performSelectorInBackground:@selector(insertSQL:) withObject:@""];
	
	
	self.viewControllersFull = [[self tabBarController] viewControllers];
	[self uavTypeToggled:nil];

	[super viewDidLoad];
	[[UAV sharedInstance] removeSpinner];
	
}

- (void)ping{
	
	NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http:/%@", [UAV sharedInstance].uavIP]] 
												cachePolicy:NSURLRequestUseProtocolCachePolicy
											timeoutInterval:0.5];
	
	[[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	NSLog(@"data");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
	//NSLog(@"%@, %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
	if ([[error localizedDescription] isEqualToString:@"Could not connect to the server."]) {
		//NSLog(@"Ping successful");
		[UAV sharedInstance].uavFound = YES;
	} else {
		//NSLog(@"Ping unsuccessful");
		[UAV sharedInstance].uavFound = NO;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ping" object:nil ];
	
	
	
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

#pragma mark -
#pragma mark IBAction
- (IBAction) mapSwitchToggled: (id)sender{
	
}

- (IBAction) connectSwitchToggled: (id)sender{	
	int rv;
	struct sockaddr_in iPhoneAddr;
	
	
	if (connectSwitch.on) // if the switch is on, create a socket and bind it
	{
		sockfd = socket(AF_INET, SOCK_DGRAM, 0);
		if (sockfd == -1)
		{
			status.text = @"Fail to create socket";
			return;
		}	
		//getAddrinfo(
		bzero(&iPhoneAddr, sizeof(iPhoneAddr));
		iPhoneAddr.sin_family = AF_INET;
		iPhoneAddr.sin_addr.s_addr = htonl(INADDR_ANY);//htonl(hostlong);
		iPhoneAddr.sin_port = htons(9001);
		rv = bind(sockfd, (struct sockaddr *)&iPhoneAddr, sizeof(iPhoneAddr));
		if (rv == -1)
		{
			close(sockfd);
			status.text = @"Fail to bind socket";
			return;
		} else {
			status.text = defaultConnectedText;
		}
		
		// create and initialize a mutex lock that control access to shared data between threads		
		// create a thread to monitor incoming data and a thread to update the display
		[NSThread detachNewThreadSelector:@selector(checkForIncomingData) toTarget:self withObject:nil];	
	}	
	else // close the socket to terminate the connection
	{	
		//sockfd = [[globalVars sharedInstance] getSockfd];
		//		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto://singjie@purehub.com?attachment=UAVSQL6.sql"]];
		close(sockfd);
		status.text = [NSString stringWithFormat:@"Not listening at id:%d", sockfd];	
	}
	
	return;
	
}

- (void) checkForIncomingData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	////status.text = [NSString stringWithFormat:@"Listening at id:%d", sockfd];
	struct sockaddr_in aircraftAddr;
	socklen_t len;	
	
	struct UAVSTATE *currentDataNew = malloc(sizeof(struct UAVSTATE));
	
	memset(currentDataNew, 0, sizeof(struct UAVSTATE));
	
	
	NSData *imageData;
	char fullbuffer[100000]; //100kb pic size. MAX.
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	
	NSString *documentsDirectory = [paths objectAtIndex:0];
	
	BOOL checkFirstPacket = YES;
	
	BOOL skippedPacket = NO;
	int rv = 0;
	char buffer[1400];
	
	NSLog(@"size:%d", sizeof(struct UAVSTATE));
	for(;;)
	{
		NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];
		if (skippedPacket == YES) {
			NSLog(@"d");
			//memcpy(currentDataNew, buffer, sizeof(struct UAVSTATE));
			
			skippedPacket = NO;
		} else {
			memset(currentDataNew, 0, sizeof(struct UAVSTATE));
			
			rv = recvfrom(sockfd, buffer, sizeof(buffer), 0, (struct sockaddr *)&aircraftAddr, &len);
		}
		
		//rv = recvfrom(sockfd, buffer, sizeof(buffer), 0, (struct sockaddr *)&aircraftAddr, &len);
		//memcpy(currentDataNew, buffer, rv);
		
		if(checkFirstPacket){
			checkFirstPacket = 0;
			[UAV sharedInstance].firstPacketDate = [[NSDate date] retain];
		}
		
		
		
#pragma mark ERROR PACKET CHECK 
		//limit of packet size is 50kb = 50*1000 => 50 packets. more than that means error, throw.
		while (/*currentDataNew->imagePackets > 300 || currentDataNew->imagePackets < 0 || */rv != sizeof(struct UAVSTATE)){
			//error packet
			[UAV sharedInstance].packetImproper = YES; 
			NSLog(@"gps: latitude%f", currentDataNew->latitude);
			
			NSLog(@"rv:%d", rv);
			//get new packet
			memset(currentDataNew, 0, sizeof(struct UAVSTATE));
			
			rv = recvfrom(sockfd, buffer, sizeof(buffer), 0, (struct sockaddr *)&aircraftAddr, &len);
			
			
		}
		memcpy(currentDataNew, buffer, sizeof(struct UAVSTATE));
		
#pragma mark IMAGE LOOP
		if (currentDataNew->imagePackets > 0){		
			
			int countpackets = 0;
			while(currentDataNew->imagePackets--){
				//get image packets
				countpackets++;
				rv = recvfrom(sockfd, buffer, sizeof(buffer), 0, (struct sockaddr *)&aircraftAddr, &len);
				if(rv == -1){
					//countpackets = 5;
				}
				if (rv == sizeof(struct UAVSTATE)) { //64bit sim to 32bit pad
					//received the wrong packet! stop immediately. this packet contains UAV state.
					countpackets = currentDataNew->imagePackets;
					skippedPacket = YES;
					
					[UAV sharedInstance].packetImproper = YES;
					break;
				} else {
					//NSLog(@"good");
				}
				
				if(countpackets == 1) //first packet.
					memcpy(fullbuffer, buffer, sizeof(buffer));
				else {
					memcpy(fullbuffer+(sizeof(buffer)*(countpackets-1)), buffer, sizeof(buffer));
				}
				
			}
			
			if (skippedPacket) {
				[pool2 drain];
				continue;
			}
			
			imageData = [NSData dataWithBytes:fullbuffer length:(countpackets*sizeof(buffer))];
			
			NSMutableArray *imagePasser = [NSMutableArray array];
			[imagePasser addObject:imageData];
			[imagePasser addObject:[documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"file%d.jpg", filelist]]];
			
			[self performSelectorInBackground:@selector(writeImage:) withObject:imagePasser];
			
			filelist++;
			
			[[UAV sharedInstance].imageLock lock];
			[UAV sharedInstance].image = imageData;
			[[UAV sharedInstance].imageLock unlock];
			
			
		}
		NSString *createSQL;
		createSQL = [[NSString alloc]initWithFormat:@"INSERT INTO FLIGHTDATA ("
					 "x,y,z,"
					 "u,v,w,"
					 "a,b,c,"
					 "p,q,r,"
					 "acx, acy, acz,"
					 "acp, acq, acr,"
					 "ug, vg, wg,"
					 "longitude, latitude, altitude,"
					 "'as', bs, rfb"
					 ")" 
					 "Values (%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f);", 
					 currentDataNew->x, currentDataNew->y, currentDataNew->z, 
					 currentDataNew->u, currentDataNew->v, currentDataNew->w,  
					 currentDataNew->a, currentDataNew->b, currentDataNew->c, 
					 currentDataNew->p, currentDataNew->q, currentDataNew->r,  
					 currentDataNew->acx, currentDataNew->acy, currentDataNew->acz, 
					 currentDataNew->acp, currentDataNew->acq, currentDataNew->acr,  
					 currentDataNew->ug, currentDataNew->vg, currentDataNew->wg, 
					 currentDataNew->longitude, currentDataNew->latitude, currentDataNew->altitude, 
					 currentDataNew->as, currentDataNew->bs, currentDataNew->rfb];
		
		
		//		[NSThread detachNewThreadSelector:@selector(insertSQL:) toTarget:self withObject:createSQL];	
		
		[sqlArray addObject:createSQL];
		//	[NSThread detachNewThreadSelector:@selector(updateFullData:) toTarget:self withObject:[[UAV sharedInstance] convertDataToObject:currentDataNew]];	
		
		[self performSelectorInBackground:@selector(updateFullData:) withObject:[[UAV sharedInstance] convertDataToObject:currentDataNew]];
		
		[self performSelectorOnMainThread:@selector(postNotificationToUI) withObject:nil waitUntilDone:NO];
		[createSQL release];
		
		
#pragma mark WANGFEI 2D
		if ([[UAV sharedInstance] currentUAVType] == kUAVTypeCANCAM) {
			//-----------------------------------------------------------------------------------------------------------
			//CATER TO WANGFEI -2D Coordinates
			//-----------------------------------------------------------------------------------------------------------
			rv = recvfrom(sockfd, buffer, sizeof(buffer), 0, (struct sockaddr *)&aircraftAddr, &len);
			
			//NSLog(@"Length of packet:%d", rv);
			
			while (rv == 1400 || rv < 300) {
				//something wrong with packet size
				NSLog(@"%@", [NSString stringWithFormat:@"thrown away one packet. Size:(%d)", rv]);
				rv = recvfrom(sockfd, buffer, sizeof(buffer), 0, (struct sockaddr *)&aircraftAddr, &len);
			}
			[self performSelectorOnMainThread:@selector(drawCoordinates:) withObject:[NSData dataWithBytes:buffer length:rv] waitUntilDone:NO];
		}
		
		[pool2 drain];
		
	}
	
	[pool drain];
}
-(void) writeImage:(NSMutableArray*)arr{
	[[arr objectAtIndex:0] writeToFile:	[arr objectAtIndex:1] atomically:NO];
	
}
-(void) postNotificationToUI{
	
	/*generate notification here, on main thread*/
	[[NSNotificationCenter defaultCenter] postNotificationName:@"settings" object:[[UAV sharedInstance] getLatestRowData]];
}


-(void) updateFullData:(id) object{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	UAV *uav = [UAV sharedInstance];
	[uav.fullDataLock lock];
	if ([uav.fullData count] == GRAPHLIMIT){
		[uav.fullData removeObjectAtIndex:0];
	}
	[uav.fullData addObject:object] ;
	[uav.fullDataLock unlock];
	
	
	
	
	[pool drain];
	
	
	
}
-(void) insertSQL:(NSString*) sql{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//	NSMutableArray *durationArray = [NSMutableArray array];
	while (1) {
		NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];
		if ([sqlArray count]) {
			UAV *uav = [UAV sharedInstance];
			//			NSDate *startDate = [NSDate date];
			[uav.sqlLock lock];
			sqlite3_exec(uav.db, [[sqlArray objectAtIndex:0] UTF8String], NULL,NULL, NULL);
			[uav.sqlLock unlock]; 
			//			NSTimeInterval duration = [startDate timeIntervalSinceNow] * -1;
			//			NSNumber *num = [NSNumber numberWithDouble:duration];
			//			[durationArray addObject:num];
			//			if ([durationArray count] == 500) {
			//				NSLog(@"%@", durationArray);
			//			}
			[sqlArray removeObjectAtIndex:0];
		}
		[pool2 release];
	}
	
	[pool drain];
	
}

-(IBAction) viewJpeg:(id) sender{
	//	[[UIPopoverController alloc] initWithContentViewController:[[ImageViewController alloc] init] ];
	UIPopoverController *pop = [[UIPopoverController alloc] initWithContentViewController:[[[ImageViewController alloc] init] autorelease]] ;
	[pop presentPopoverFromRect:[sender frame] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
	pop.popoverContentSize = CGSizeMake(600, 240.0/320*600);
}

-(IBAction) sendData:(id) sender{
	
	if(![[UAV sharedInstance] parseAndSendCommand:[sender text]]){
		UIAlertView *alert = [[[UIAlertView alloc] 
							   initWithTitle:@"Invalid Command" 
							   message:@"Please check your command!" 
							   delegate:self
							   cancelButtonTitle:@"Ok" 
							   otherButtonTitles:nil] autorelease];
		[alert show];
	}
	
	else 
		consoleInput.text = @"";
	
}

- (IBAction) emailData: (id) sender{
	MFMailComposeViewController *controller = [[MFMailComposeViewController alloc ] init];
	controller.mailComposeDelegate = self;
	[controller setSubject:@"UAV"];
	[controller setMessageBody:@"As attached." isHTML:NO];
	
	NSString *path = [UAV sharedInstance].SQLFileName;
	NSData *data  = [NSData dataWithContentsOfFile:path];
	[controller addAttachmentData:data mimeType:@"application/octet-stream" fileName:[[path lastPathComponent] stringByDeletingPathExtension]];
	
	
	[self presentModalViewController:controller animated:YES];
	//NSLog(@"displayed");
	
}

- (IBAction) deleteAllJPG: (id) sender{
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	
	//Consolidate all the files in the Documents directory. 
	NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
	
	int countjpg = 0;
	int count = [files count];
	for (int i=0; i < count ; i++) {
		if ([[[files objectAtIndex:i] pathExtension] isEqualToString:@"jpg"])	{
			countjpg++;
			//NSLog(@"%@", [NSString stringWithFormat:@"%@/%@",[paths objectAtIndex:0], [files objectAtIndex:i] ]);
			
			[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",[paths objectAtIndex:0], [files objectAtIndex:i]] error:nil];
		}
	}
	
	[[[[UIAlertView alloc]  initWithTitle:@"JPEGs Deletion" message:[NSString stringWithFormat:@"%d files deleted", countjpg] delegate:self cancelButtonTitle:@"Ok"  otherButtonTitles:nil] autorelease] show];
}
- (IBAction) calibrateCamera: (UIButton*) sender{
	
	
	if (sender.titleLabel.text  != @"Send Data") {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableHSVPicture) name:@"settings" object:nil];
		imageView = [[UIImageView alloc] initWithFrame:CGRectMake(110,180,320,240)];
		[self.view addSubview:imageView];
		if (!notFirstTimeActivate) {
			
			
			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
			
			NSString *documentsDirectory = [paths objectAtIndex:0];
			
			documentsDirectory = [documentsDirectory stringByAppendingPathComponent:@"camera.plist"];
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:documentsDirectory]){
				NSMutableDictionary *plistDict = [NSMutableDictionary dictionaryWithContentsOfFile:documentsDirectory];
				
				slider1.value = [[plistDict objectForKey:@"H"] intValue];
				slider2.value = [[plistDict objectForKey:@"S"] intValue];
				slider3.value = [[plistDict objectForKey:@"RL"] intValue];
				slider4.value = [[plistDict objectForKey:@"RU"] intValue];
				slider5.value = [[plistDict objectForKey:@"BL"] intValue];
				slider6.value = [[plistDict objectForKey:@"BU"] intValue];
				slider7.value = [[plistDict objectForKey:@"GL"] intValue];
				slider8.value = [[plistDict objectForKey:@"GU"] intValue];
			} else {
				
				
				slider1.value = 39;
				slider2.value = 48;
				slider3.value = 165;
				slider4.value = 15;
				slider5.value = 93;
				slider6.value = 135;
				slider7.value = 26;
				slider8.value = 86;
				NSMutableDictionary *plistDict = [NSMutableDictionary dictionary];
				
				[plistDict setValue:[NSString stringWithFormat:@"%0.f", slider1.value] forKey:@"H"];
				[plistDict setValue:[NSString stringWithFormat:@"%0.f", slider2.value] forKey:@"S"];
				[plistDict setValue:[NSString stringWithFormat:@"%0.f", slider3.value] forKey:@"RL"];
				[plistDict setValue:[NSString stringWithFormat:@"%0.f", slider4.value] forKey:@"RU"];
				[plistDict setValue:[NSString stringWithFormat:@"%0.f", slider5.value] forKey:@"BL"];
				[plistDict setValue:[NSString stringWithFormat:@"%0.f", slider6.value] forKey:@"BU"];
				[plistDict setValue:[NSString stringWithFormat:@"%0.f", slider7.value] forKey:@"GL"];
				[plistDict setValue:[NSString stringWithFormat:@"%0.f", slider8.value] forKey:@"GU"];
				
				NSLog(@"written: %d", [plistDict writeToFile:documentsDirectory atomically:YES]);
			}
			
			
			notFirstTimeActivate = YES;
		}
		
		[self setEnableSliders:YES];
		
		//use to trigger into hsv mode + for all 0 conditions to update label
		[self valueChangedForSliders];
		[sender setTitle:@"Send Data" forState:UIControlStateNormal];
		
	} else {
		if ([[UAV sharedInstance] parseAndSendCommand:[NSString stringWithFormat:@"calibrate(%.0f, %.0f, %.0f, %.0f, %.0f, %.0f, %.0f, %.0f)", slider1.value, slider2.value, slider3.value, slider4.value, slider5.value, slider6.value, slider7.value, slider8.value]]) {
			sender.enabled = NO;
			
			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
			
			NSString *documentsDirectory = [paths objectAtIndex:0];
			
			documentsDirectory = [documentsDirectory stringByAppendingPathComponent:@"camera.plist"];
			
			
			NSMutableDictionary *plistDict = [NSMutableDictionary dictionary];
			
			[plistDict setValue:[NSString stringWithFormat:@"%0.f", slider1.value] forKey:@"H"];
			[plistDict setValue:[NSString stringWithFormat:@"%0.f", slider2.value] forKey:@"S"];
			[plistDict setValue:[NSString stringWithFormat:@"%0.f", slider3.value] forKey:@"RL"];
			[plistDict setValue:[NSString stringWithFormat:@"%0.f", slider4.value] forKey:@"RU"];
			[plistDict setValue:[NSString stringWithFormat:@"%0.f", slider5.value] forKey:@"BL"];
			[plistDict setValue:[NSString stringWithFormat:@"%0.f", slider6.value] forKey:@"BU"];
			[plistDict setValue:[NSString stringWithFormat:@"%0.f", slider7.value] forKey:@"GL"];
			[plistDict setValue:[NSString stringWithFormat:@"%0.f", slider8.value] forKey:@"GU"];
			
			NSLog(@"written: %d", [plistDict writeToFile:documentsDirectory atomically:YES]);
			
			[sender setTitle:@"Data Sent!" forState:UIControlStateNormal];
			[self performSelector:@selector(renameCalibrateCamera:) withObject:sender afterDelay:1];
		} 
		
		[self setEnableSliders:NO];
		
		[imageView removeFromSuperview];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"settings" object:nil];
	}
	
}
- (void)setEnableSliders:(BOOL)enable{
	slider1.enabled = enable;
	slider2.enabled = enable;
	slider3.enabled = enable;
	slider4.enabled = enable;
	slider5.enabled = enable;
	slider6.enabled = enable;
	slider7.enabled = enable;
	slider8.enabled = enable;
	
	sliderAdd1.enabled = enable;
	sliderAdd2.enabled = enable;
	sliderAdd3.enabled = enable;
	sliderAdd4.enabled = enable;
	sliderAdd5.enabled = enable;
	sliderAdd6.enabled = enable;
	sliderAdd7.enabled = enable;
	sliderAdd8.enabled = enable;
	
	sliderSub1.enabled = enable;
	sliderSub2.enabled = enable;
	sliderSub3.enabled = enable;
	sliderSub4.enabled = enable;
	sliderSub5.enabled = enable;
	sliderSub6.enabled = enable;
	sliderSub7.enabled = enable;
	sliderSub8.enabled = enable;
	
	sliderLabel1.enabled = enable;
	sliderLabel2.enabled = enable;
	sliderLabel3.enabled = enable;
	sliderLabel4.enabled = enable;
	sliderLabel5.enabled = enable;
	sliderLabel6.enabled = enable;
	sliderLabel7.enabled = enable;
	sliderLabel8.enabled = enable;
}
- (void)setVisibleSliders:(double)alpha{
	slider1.alpha = alpha;
	slider2.alpha = alpha;
	slider3.alpha = alpha;
	slider4.alpha = alpha;
	slider5.alpha = alpha;
	slider6.alpha = alpha;
	slider7.alpha = alpha;
	slider8.alpha = alpha;
	
	sliderAdd1.alpha = alpha;
	sliderAdd2.alpha = alpha;
	sliderAdd3.alpha = alpha;
	sliderAdd4.alpha = alpha;
	sliderAdd5.alpha = alpha;
	sliderAdd6.alpha = alpha;
	sliderAdd7.alpha = alpha;
	sliderAdd8.alpha = alpha;
	
	sliderSub1.alpha = alpha;
	sliderSub2.alpha = alpha;
	sliderSub3.alpha = alpha;
	sliderSub4.alpha = alpha;
	sliderSub5.alpha = alpha;
	sliderSub6.alpha = alpha;
	sliderSub7.alpha = alpha;
	sliderSub8.alpha = alpha;
	
	sliderLabel1.alpha = alpha;
	sliderLabel2.alpha = alpha;
	sliderLabel3.alpha = alpha;
	sliderLabel4.alpha = alpha;
	sliderLabel5.alpha = alpha;
	sliderLabel6.alpha = alpha;
	sliderLabel7.alpha = alpha;
	sliderLabel8.alpha = alpha;
	
	sliderText1.alpha = alpha;
	sliderText2.alpha = alpha;
	sliderText3.alpha = alpha;
	sliderText4.alpha = alpha;
	sliderText5.alpha = alpha;
	sliderText6.alpha = alpha;
	sliderText7.alpha = alpha;
	sliderText8.alpha = alpha;
	
	calibrateCamera.alpha = alpha;
	
	if (alpha < 0.01) {
		calibrateCamera.enabled = NO;
	} else {
		calibrateCamera.enabled = YES;
	}

	
}

- (void)enableHSVPicture{
	
	int i=0;
	for (i=0; i<[self.tabBarController.viewControllers count]; i++) {
		if([[self.tabBarController.viewControllers objectAtIndex:i] isKindOfClass:[self class]]){
			break;
		}
	}
	if(self.tabBarController.selectedIndex == i){
		[[imageView image] release];
		[[UAV sharedInstance].imageLock lock];
		[imageView setImage:[[UIImage alloc] initWithData:[UAV sharedInstance].image]];
		[[UAV sharedInstance].imageLock unlock];
	}
}



- (void)renameCalibrateCamera:(UIButton *)btn{
	[btn setTitle:@"Calibrate Cam" forState:UIControlStateNormal];
	btn.enabled = YES;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	
	return [[UAV sharedInstance].consoleCommandShortcuts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //Configure each individual cell of the table.
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
	//Show filename
	cell.textLabel.text = [[UAV sharedInstance].consoleCommandShortcuts objectAtIndex:[indexPath row]];
    
    return cell;
}

#pragma mark Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	//indexPath row is selected
	BOOL rv = [[UAV sharedInstance] parseAndSendCommand:[[UAV sharedInstance].consoleCommandShortcuts objectAtIndex:[indexPath row]]];
	if (!rv) {
		[[[[UIAlertView alloc]  initWithTitle:@"Problem! Can't Send:" message:[[UAV sharedInstance].consoleCommandShortcuts objectAtIndex:[indexPath row]] delegate:self cancelButtonTitle:@"Cancel"  otherButtonTitles:nil] autorelease] show];
	} else {
		
		UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"1282981803_Check.png"]] ;
		image.alpha = 0;
		image.center = self.view.center;
		[self.view addSubview:image];
		
		
		[UIView animateWithDuration:0.1 animations:^(void) {
			image.alpha = 1;
		} completion:^(BOOL finished){
			[UIView animateWithDuration:0.1 animations:^(void) {
				image.alpha = 0;
			} completion:^(BOOL finished){
				[image removeFromSuperview];
				[image release];
			}];
		}];
	}
	
}
#pragma mark MFMailComposeView Delegate
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error{
	[controller dismissModalViewControllerAnimated:YES];
	if (result == MFMailComposeResultSent) {
		NSLog(@"sent");
	}
	else if	(result == MFMailComposeResultSaved){
		NSLog(@"saved");
	}
	else if (result == MFMailComposeResultFailed){
		NSLog(@"%@", error);
		NSLog(@"failed");
	}
	else {
		NSLog(@"gg");
	}
	
}

- (IBAction)valueChangedForSliders{
	sliderText1.text = [NSString stringWithFormat:@"%.0f", slider1.value];
	sliderText2.text = [NSString stringWithFormat:@"%.0f", slider2.value];
	sliderText3.text = [NSString stringWithFormat:@"%.0f", slider3.value];
	sliderText4.text = [NSString stringWithFormat:@"%.0f", slider4.value];
	sliderText5.text = [NSString stringWithFormat:@"%.0f", slider5.value];
	sliderText6.text = [NSString stringWithFormat:@"%.0f", slider6.value];
	sliderText7.text = [NSString stringWithFormat:@"%.0f", slider7.value];
	sliderText8.text = [NSString stringWithFormat:@"%.0f", slider8.value];
	
	if ([[UAV sharedInstance] parseAndSendCommand:[NSString stringWithFormat:@"calibrateLive(%.0f, %.0f, %.0f, %.0f, %.0f, %.0f, %.0f, %.0f)", slider1.value, slider2.value, slider3.value, slider4.value, slider5.value, slider6.value, slider7.value, slider8.value]]) {
		NSLog(@"%@", [NSString stringWithFormat:@"calibrateLive(%.0f, %.0f, %.0f, %.0f, %.0f, %.0f, %.0f, %.0f)", slider1.value, slider2.value, slider3.value, slider4.value, slider5.value, slider6.value, slider7.value, slider8.value]);	
	}
}


- (IBAction) addValue: (UIButton*) sender{
	if (sender.center.x == sliderText1.center.x) {
		slider1.value++;
	} else if (sender.center.x == sliderText2.center.x) {
		slider2.value++;
	} else if (sender.center.x == sliderText3.center.x) {
		slider3.value++;
	} else if (sender.center.x == sliderText4.center.x) {
		slider4.value++;
	} else if (sender.center.x == sliderText5.center.x) {
		slider5.value++;
	} else if (sender.center.x == sliderText6.center.x) {
		slider6.value++;
	} else if (sender.center.x == sliderText7.center.x) {
		slider7.value++;
	} else if (sender.center.x == sliderText8.center.x) {
		slider8.value++;
	}
	
	[self valueChangedForSliders];
}

- (IBAction) subValue: (UIButton*) sender{
	if (sender.center.x == sliderText1.center.x) {
		slider1.value--;
	} else if (sender.center.x == sliderText2.center.x) {
		slider2.value--;
	} else if (sender.center.x == sliderText3.center.x) {
		slider3.value--;
	} else if (sender.center.x == sliderText4.center.x) {
		slider4.value--;
	} else if (sender.center.x == sliderText5.center.x) {
		slider5.value--;
	} else if (sender.center.x == sliderText6.center.x) {
		slider6.value--;
	} else if (sender.center.x == sliderText7.center.x) {
		slider7.value--;
	} else if (sender.center.x == sliderText8.center.x) {
		slider8.value--;
	}
	
	[self valueChangedForSliders];
}

- (void)drawCoordinates:(id) obj{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"plotCoordinates" object:obj];
}
- (IBAction) uavTypeToggled:(id)sender{
	NSParameterAssert(self.viewControllersFull != nil);
		UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
		
	if (sender == nil || [segmentedControl selectedSegmentIndex] == kUAVTypeCANCAM){
		NSLog(@"UISegmentedControl nil");
		
		[UAV sharedInstance].currentUAVType = kUAVTypeCANCAM;
		NSMutableArray* newArray = [NSMutableArray arrayWithArray:self.viewControllersFull];
		
		
		int i=0;
		for (i=0; i<[newArray count]; i++) {
			if([[newArray objectAtIndex:i] isKindOfClass:[MapViewController class]]){
				break;
			}
		}
		[newArray removeObjectAtIndex:i];
		[self.tabBarController setViewControllers:newArray animated:YES];
		
		for (i=0; i<[newArray count]; i++) {
			if([[newArray objectAtIndex:i] isKindOfClass:[OpenGLViewController class]]){
				break;
			}
		}
		[newArray removeObjectAtIndex:i];
		[self.tabBarController setViewControllers:newArray animated:YES];
		
		[self setVisibleSliders:0];
		
	}
	else if ([segmentedControl selectedSegmentIndex] == kUAVTypeMerlion) {
		NSMutableArray* newArray = [NSMutableArray arrayWithArray:self.viewControllersFull];
		
		[UAV sharedInstance].currentUAVType = kUAVTypeMerlion;
		
		int i=0;
		for (i=0; i<[newArray count]; i++) {
			if([[newArray objectAtIndex:i] isKindOfClass:[SLAM class]]){
				break;
			}
		}
		[newArray removeObjectAtIndex:i];
		[self.tabBarController setViewControllers:newArray animated:YES];
		
		
		[self setVisibleSliders:1];
		
	}
		else {
			NSAssert(0, @"segment UAV index wrong");
		}
	
	
}
@end

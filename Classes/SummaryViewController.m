//
//  SummaryViewController.m
//  UAV
//
//  Created by Eric Dong on 8/16/10.
//  Copyright 2010 NUS. All rights reserved.
//

#import "SummaryViewController.h"
#import "SummaryTableViewCustomCell.h"
#import "GraphView.h"

@implementation SummaryViewController

@synthesize textLabel;

@synthesize listData;
@synthesize listComponent;

@synthesize summaryTable;
@synthesize dataHeader;

//@synthesize graph_1;
//@synthesize graph_2;
//@synthesize graph_3;

@synthesize tableRows;

@synthesize graphView1;
@synthesize graphView2;
@synthesize graphView3;

@synthesize temparray;
@synthesize temparray2;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	int value = GRAPHLIMIT;
	temparray = [[NSMutableArray alloc] initWithCapacity:value];
	for ( int i = 0 ; i <= value ; i++ ) {
		[temparray addObject:[NSNumber numberWithInt:i]];	
	}
	temparray2 = [[NSMutableArray alloc] initWithCapacity:value];
	for ( int i = 0 ; i <= value ; i++ ) {
		[temparray2 addObject:[NSNumber numberWithInt:rand()%100]];	
	}
	self.listData = [[NSArray alloc] initWithObjects:
					 
					 @"Position", 
					 @"Velocity", 
					 @"Attitudes", 
					 @"Rotating Angles", 
					 @"Acceleration", 
					 @"Angular Acceleration", 
					 @"Velocities", 
					 @"GPS", 
					 @"Variables",
					 
					 
					 nil];
	self.listComponent = [[NSArray alloc] initWithObjects:
						  @"x:", @"y:", @"z:",
						  @"u:", @"v:", @"w:",
						  @"a:", @"b:", @"c:",
						  @"p:", @"q:", @"r:",
						  @"acx:", @"acy:", @"acz:",
						  @"acp:", @"acq:", @"acr:",
						  @"ug:", @"vg:", @"wg:",
						  @"longitude:", @"latitude:", @"altitude:",
						  @"as:", @"bs:", @"rfb:",
						  nil];
	
	db =  [UAV sharedInstance].db;
	
	row = 0;
	oldResult = 0;
	tableRows = NULL;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable:) name:@"settings" object:nil];
	
    [super viewDidLoad];
	
	NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
	[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[numberFormatter setMinimumFractionDigits:0];
	[numberFormatter setMaximumFractionDigits:3];
	
	self.graphView1.yValuesFormatter = numberFormatter;
	self.graphView2.yValuesFormatter = numberFormatter;
	self.graphView3.yValuesFormatter = numberFormatter;
	
	NSDateFormatter *dateFormatter = [NSDateFormatter new];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	
	/*uses numformatter same as y axis.*/
	self.graphView1.xValuesFormatter = numberFormatter;
	self.graphView2.xValuesFormatter = numberFormatter;
	self.graphView3.xValuesFormatter = numberFormatter;

	
	[dateFormatter release];        
	[numberFormatter release];
	
	self.graphView1.backgroundColor = [UIColor blackColor];
	
	self.graphView1.drawAxisX = YES;
	self.graphView1.drawAxisY = YES;
	self.graphView1.drawGridX = YES;
	self.graphView1.drawGridY = YES;
	
	self.graphView1.xValuesColor = [UIColor whiteColor];
	self.graphView1.yValuesColor = [UIColor whiteColor];
	
	self.graphView1.gridXColor = [UIColor whiteColor];
	self.graphView1.gridYColor = [UIColor whiteColor];
	
	self.graphView1.drawInfo = NO;
	self.graphView1.info = @"1";
	self.graphView1.infoColor = [UIColor whiteColor];
	
	
	self.graphView2.backgroundColor = [UIColor blackColor];
	
	self.graphView2.drawAxisX = YES;
	self.graphView2.drawAxisY = YES;
	self.graphView2.drawGridX = YES;
	self.graphView2.drawGridY = YES;

	self.graphView2.xValuesColor = [UIColor whiteColor];
	self.graphView2.yValuesColor = [UIColor whiteColor];
	
	self.graphView2.gridXColor = [UIColor whiteColor];
	self.graphView2.gridYColor = [UIColor whiteColor];
	
	self.graphView2.drawInfo = NO;
	self.graphView2.info = @"2";
	self.graphView2.infoColor = [UIColor whiteColor];
	
	
	self.graphView3.backgroundColor = [UIColor blackColor];
	self.graphView3.drawAxisX = YES;
	self.graphView3.drawAxisY = YES;
	self.graphView3.drawGridX = YES;
	self.graphView3.drawGridY = YES;
	
	self.graphView3.xValuesColor = [UIColor whiteColor];
	self.graphView3.yValuesColor = [UIColor whiteColor];
	
	self.graphView3.gridXColor = [UIColor whiteColor];
	self.graphView3.gridYColor = [UIColor whiteColor];
	
	self.graphView3.drawInfo = NO;
	self.graphView3.info = @"3";
	self.graphView3.infoColor = [UIColor whiteColor];
	//When you need to update the data, make this call:
	
	//	[NSThread detachNewThreadSelector:@selector(refreshTable) toTarget:self withObject:nil];	
	[[UAV sharedInstance] removeSpinner];

}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

/*
 - (void)didReceiveMemoryWarning {
 // Releases the view if it doesn't have a superview.
 [super didReceiveMemoryWarning];
 
 // Release any cached data, images, etc that aren't in use.
 }
 
 - (void)viewDidUnload {
 [super viewDidUnload];
 }
 
 
 - (void)dealloc {
 [super dealloc];
 }
 */

#pragma mark -
#pragma mark Table View DataSource 
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	
	static NSString *SimpleTableIdentifier = @"SimpleTableIdentifier";
	
	SummaryTableViewCustomCell *cell = (SummaryTableViewCustomCell *)[tableView dequeueReusableCellWithIdentifier: SimpleTableIdentifier];
	
	if(cell == nil){
		NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SummaryTableIPAD" 
													 owner:self
												   options:nil];
		cell = [nib objectAtIndex:0];
	}
	
	NSMutableArray *results = [[UAV sharedInstance]getLatestRowData]; // returns whole t-uple.
	if([results count] == 0){ //if no data return, set attribute row to 0.
		cell.label1.text = @"No data in DB.";
		cell.label2.text = @"No data in DB.";
		cell.label3.text = @"No data in DB.";
	}
	else{
		cell.label1.text = [NSString stringWithFormat: @"%.8f", [[results objectAtIndex:[indexPath row]*3] doubleValue]];
		cell.label2.text = [NSString stringWithFormat: @"%.8f", [[results objectAtIndex:[indexPath row]*3+1] doubleValue]];
		cell.label3.text = [NSString stringWithFormat: @"%.8f", [[results objectAtIndex:[indexPath row]*3+2] doubleValue]];
		
	}
	[results release];
	cell.nameoflabel1.text = [listComponent objectAtIndex:[indexPath row]*3];
	cell.nameoflabel2.text = [listComponent objectAtIndex:[indexPath row]*3+1];
	cell.nameoflabel3.text = [listComponent objectAtIndex:[indexPath row]*3+2];
	cell.parameterLabel.text = [listData objectAtIndex:[indexPath row]];
	
	[SimpleTableIdentifier release];
	
	return cell;
}

-(NSInteger) newDataInDB{ //not in use. this lags data. 
	//return 1;
	[[UAV sharedInstance].sqlLock lock];
	
	NSString *query = @"Select count(*) from FLIGHTDATA;";
	
	NSInteger numOfDataCount=0;
	
	sqlite3_stmt *statement;
	if(sqlite3_prepare_v2(db, [query UTF8String], -1, &statement, nil) == SQLITE_OK){
		if (sqlite3_step(statement) == SQLITE_ROW){
			numOfDataCount = sqlite3_column_int(statement, 0);
		}
	}
	[query release];
	[[UAV sharedInstance].sqlLock unlock];
	
	if(numOfDataCount > oldResult)
		oldResult = numOfDataCount;
	else {
		return 0;
	}
	return 1;
}
- (NSUInteger)graphViewNumberOfPlots:(S7GraphView *)graphView {
	return 1;
	/* Return the number of plots you are going to have in the view. 1+ */
}

- (NSArray *)graphViewXValues:(S7GraphView *)graphView {
	return [[UAV sharedInstance] graphData];
	/* An array of objects that will be further formatted to be displayed on the X-axis.
	 The number of elements should be equal to the number of points you have for every plot. */
}

- (NSArray *)graphView:(S7GraphView *)graphView yValuesForPlot:(NSUInteger)plotIndex {
	NSArray *tempResult = [[UAV sharedInstance] graphData];
	NSMutableArray *ar = [NSMutableArray array];
	int count = [tempResult count];
	for(int i=0;i<count;i++){
		UAVSTRUCT *re = [tempResult objectAtIndex:i];
		switch (row) {
			case 0:
				if (graphView.info == @"1")
					[ar addObject:[NSNumber numberWithDouble:re.x]];
				else if (graphView.info == @"2")
					[ar addObject:[NSNumber numberWithDouble:re.y]];
				else if (graphView.info == @"3")
					[ar addObject:[NSNumber numberWithDouble:re.z]];
				break;
			case 1:
				if (graphView.info == @"1")
					[ar addObject:[NSNumber numberWithDouble:re.u]];
				else if (graphView.info == @"2")
					[ar addObject:[NSNumber numberWithDouble:re.v]];
				else if (graphView.info == @"3")
					[ar addObject:[NSNumber numberWithDouble:re.w]];
				break;
			case 2:
				if (graphView.info == @"1")
					[ar addObject:[NSNumber numberWithDouble:re.a]];
				else if (graphView.info == @"2")
					[ar addObject:[NSNumber numberWithDouble:re.b]];
				else if (graphView.info == @"3")
					[ar addObject:[NSNumber numberWithDouble:re.c]];
				break;
			case 3:
				if (graphView.info == @"1")
					[ar addObject:[NSNumber numberWithDouble:re.p]];
				else if (graphView.info == @"2")
					[ar addObject:[NSNumber numberWithDouble:re.q]];
				else if (graphView.info == @"3")
					[ar addObject:[NSNumber numberWithDouble:re.r]];
				break;
			case 4:
				if (graphView.info == @"1")
					[ar addObject:[NSNumber numberWithDouble:re.acx]];
				else if (graphView.info == @"2")
					[ar addObject:[NSNumber numberWithDouble:re.acy]];
				else if (graphView.info == @"3")
					[ar addObject:[NSNumber numberWithDouble:re.acz]];
				break;
			case 5:
				if (graphView.info == @"1")
					[ar addObject:[NSNumber numberWithDouble:re.acp]];
				else if (graphView.info == @"2")
					[ar addObject:[NSNumber numberWithDouble:re.acq]];
				else if (graphView.info == @"3")
					[ar addObject:[NSNumber numberWithDouble:re.acr]];
				break;
			case 6:
				if (graphView.info == @"1")
					[ar addObject:[NSNumber numberWithDouble:re.ug]];
				else if (graphView.info == @"2")
					[ar addObject:[NSNumber numberWithDouble:re.vg]];
				else if (graphView.info == @"3")
					[ar addObject:[NSNumber numberWithDouble:re.wg]];
				break;
			case 7:
				if (graphView.info == @"1")
					[ar addObject:[NSNumber numberWithDouble:re.longitude]];
				else if (graphView.info == @"2")
					[ar addObject:[NSNumber numberWithDouble:re.latitude]];
				else if (graphView.info == @"3")
					[ar addObject:[NSNumber numberWithDouble:re.altitude]];
				break;
			case 8:
				if (graphView.info == @"1")
					[ar addObject:[NSNumber numberWithDouble:re.as]];
				else if (graphView.info == @"2")
					[ar addObject:[NSNumber numberWithDouble:re.bs]];
				else if (graphView.info == @"3")
					[ar addObject:[NSNumber numberWithDouble:re.rfb]];
				break;
			default:
				NSAssert(0, @"PLEASE CHECK summaryViewController.m\n");
				break;
		}	
		
	
	
	
	
	}
	//[[UAV sharedInstance].sqlLock unlock];
	return ar;
				  
	/* Return the values for a specific graph. Each plot is meant to have equal number of points.
	 And this amount should be equal to the amount of elements you return from graphViewXValues: method. */
}
-(void) refreshTable:(NSNotification*)pNotification {
	NSArray *results = (NSArray*) [pNotification object];
	
	int i=0;
	for (i=0; i<[self.tabBarController.viewControllers count]; i++) {
		if([[self.tabBarController.viewControllers objectAtIndex:i] isKindOfClass:[self class]]){
			break;
		}
	}
		if(self.tabBarController.selectedIndex == i){
			[self performSelectorOnMainThread:@selector(refresh:) withObject:results waitUntilDone:NO];
			
		}
	
}
- (void) refresh:(id)results{
	UAV* uav = [UAV sharedInstance];
	
		
		if([uav.sqlLock tryLock]){
			[self.graphView1 reloadData];
			[uav.sqlLock unlock];
		}
		if([uav.sqlLock tryLock]){
			[self.graphView2 reloadData];
			[uav.sqlLock unlock];
		}
		if([uav.sqlLock tryLock]){
			[self.graphView3 reloadData];
			[uav.sqlLock unlock];
		}

	NSArray *indexPaths = [summaryTable indexPathsForVisibleRows] ;
	
	SummaryTableViewCustomCell *cell;
	NSInteger maxCells = [indexPaths count];
	//[indexPaths objectAtIndex:0] 
	for(NSInteger i=0; i<maxCells;i++){
		cell = (SummaryTableViewCustomCell *)[summaryTable cellForRowAtIndexPath:[indexPaths objectAtIndex:i]];
		
		if([results count] == 0){ //if no data return, set attribute row to 0.
			cell.label1.text = @"No data in DB.";
			cell.label2.text = @"No data in DB.";
			cell.label3.text = @"No data in DB.";
		}
		{
			cell.label1.text = [NSString stringWithFormat: @"%.8f", [[results objectAtIndex:[[indexPaths objectAtIndex:i] row]*3] doubleValue]];
			cell.label2.text = [NSString stringWithFormat: @"%.8f", [[results objectAtIndex:[[indexPaths objectAtIndex:i] row]*3+1] doubleValue]];
			cell.label3.text = [NSString stringWithFormat: @"%.8f", [[results objectAtIndex:[[indexPaths objectAtIndex:i] row]*3+2] doubleValue]];
			
		}
		cell.nameoflabel1.text = [listComponent objectAtIndex:[[indexPaths objectAtIndex:i] row]*3];
		cell.nameoflabel2.text = [listComponent objectAtIndex:[[indexPaths objectAtIndex:i] row]*3+1];
		cell.nameoflabel3.text = [listComponent objectAtIndex:[[indexPaths objectAtIndex:i] row]*3+2];
		cell.parameterLabel.text = [listData objectAtIndex:[[indexPaths objectAtIndex:i] row]];
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	
	return [listData count];
}

#pragma mark -
#pragma mark Table View Delegate
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath: (NSIndexPath *)indexPath{
	
	dataHeader.text = [listData objectAtIndex:indexPath.row];
	
	row = indexPath.row;
	
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath{
	UAV *uav = [UAV sharedInstance];
	[uav.sqlLock lock];
	[graphView1 reloadData];
	[graphView2 reloadData];
	[graphView3 reloadData];
	[uav.sqlLock unlock];
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65;
}
#pragma mark -
@end

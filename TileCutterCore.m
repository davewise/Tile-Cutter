//
//  TileCutterCore.m
//  Tile Cutter
//
//  Created by Stepan Generalov on 28.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TileCutterCore.h"
#import "NSImage-Tile.h"

@implementation TileCutterCore

@synthesize keepAllTiles, tileWidth, tileHeight, inputFilename, 
			outputBaseFilename, outputSuffix, operationsDelegate, 
			queue, allTilesInfo, imageInfo, outputFormat;
@synthesize rigidTiles;

#pragma mark Public Methods

- (id) init
{
	if ( (self == [super init]) )
	{
		self.queue = [[[NSOperationQueue alloc] init] autorelease];
		[self.queue setMaxConcurrentOperationCount:1];
		
		self.outputFormat = NSPNGFileType;
		self.outputSuffix = @"";
		self.keepAllTiles = NO;
		self.rigidTiles = NO;
	}
	
	return self;
}

- (void) dealloc
{
	self.queue = nil;
	self.allTilesInfo = nil;
	self.imageInfo = nil;	
	self.inputFilename = nil;
	self.outputBaseFilename = nil;
	self.outputSuffix = nil;
	
	[super dealloc];
}

- (void) startSavingTiles
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; 
    
    NSImage *image = [[[NSImage alloc] initWithContentsOfFile: self.inputFilename] autorelease];
        
    progressCol = 0;
    progressRow = 0;
    
    tileRowCount = [image rowsWithTileHeight: self.tileHeight];
    tileColCount = [image columnsWithTileWidth: self.tileWidth];
	
	self.imageInfo = [NSDictionary dictionaryWithObjectsAndKeys: 
					  [self.inputFilename lastPathComponent], @"Filename",
					  NSStringFromSize([image size]), @"Size", nil];
	
	self.allTilesInfo = [NSMutableArray arrayWithCapacity: tileRowCount * tileColCount];
    
	// One ImageRep for all TileOperation
	NSBitmapImageRep *imageRep = 
		[[[NSBitmapImageRep alloc] initWithCGImage:[image CGImageForProposedRect:NULL context:NULL hints:nil]] autorelease];
	
    for (int row = 0; row < tileRowCount; row++)
    {
        TileOperation *op = [[TileOperation alloc] init];
        op.row = row;
        op.tileWidth = self.tileWidth;
        op.tileHeight = self.tileHeight;
        op.imageRep = imageRep;
        op.baseFilename = outputBaseFilename;
        op.delegate = self;
        op.outputFormat = self.outputFormat;
		op.outputSuffix = self.outputSuffix;
		op.skipTransparentTiles = (! self.keepAllTiles );
		op.rigidTiles = self.rigidTiles;
        [queue addOperation:op];
        [op release];
    }
    
    [pool drain];
}

- (void)operationDidFinishTile:(TileOperation *)op
{
	progressCol++;
    if (progressCol >= tileColCount)
    {
        progressCol = 0;
        progressRow++;
    }
	
	if ([self.operationsDelegate respondsToSelector: _cmd])
		[self.operationsDelegate performSelectorOnMainThread: _cmd 
												  withObject: op 
											   waitUntilDone: NO];
}

- (void)operationDidFinishSuccessfully:(TileOperation *)op
{
	[(NSMutableArray *)self.allTilesInfo addObjectsFromArray: op.tilesInfo];
	op.tilesInfo = nil;
	
	// All Tiles Finished?
	if (progressRow >= tileRowCount)
	{
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
							  self.imageInfo, @"Source",
							  self.allTilesInfo, @"Tiles", nil];
		
		if (!self.outputSuffix)
			self.outputSuffix = @"";
		[dict writeToFile:[NSString stringWithFormat:@"%@%@.plist", self.outputBaseFilename, self.outputSuffix]  atomically:YES];
	}
	
	if ([self.operationsDelegate respondsToSelector: _cmd])
		[self.operationsDelegate performSelectorOnMainThread: _cmd 
												  withObject: op 
											   waitUntilDone: NO];
}


- (void)operation:(TileOperation *)op didFailWithMessage:(NSString *)message
{
	if ([self.operationsDelegate respondsToSelector: _cmd])
		[self.operationsDelegate performSelectorOnMainThread: _cmd 
												  withObject: op 
											   waitUntilDone: NO];
}


@end

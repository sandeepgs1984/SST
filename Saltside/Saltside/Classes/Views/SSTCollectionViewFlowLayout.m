//
//  SSTCollectionViewFlowLayout.m
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import "SSTCollectionViewFlowLayout.h"

@interface SSTCollectionViewFlowLayout()

@property (nonatomic, strong) NSDictionary *sectionsToHeaderSizes;
@property (nonatomic, strong) NSDictionary *sectionsToSectionInsets;
@property (nonatomic, strong) NSDictionary *sectionsToItemsCount;
@property (nonatomic, strong) NSDictionary *indexPathsToItemSizes;
@property (nonatomic, strong) NSDictionary *indexPathsToLayoutAttributes;

@property (nonatomic, strong) NSArray *layoutAttributes;
@property (nonatomic, strong) NSArray *layoutAttributesForHeaders;
@property (nonatomic, strong) NSMutableArray *currentRowAttributes;
@property (nonatomic, strong) NSMutableArray *emptyColumnAttributes;

@property (nonatomic) CGSize contentSize;
@property (nonatomic, weak) id<SSTCollectionViewDelegateFlowLayout, UICollectionViewDelegate> delegate;
@property (nonatomic, strong) NSDictionary *protocolResponseDict;
@property (nonatomic) NSInteger numberOfSections;

@end

@implementation SSTCollectionViewFlowLayout

- (instancetype)init
{
	self = [super init];
	if (self) {
		_currentRowAttributes = [NSMutableArray array];
		_emptyColumnAttributes  = [NSMutableArray array];
	}
	return self;
}

- (void) setDelegate:(id<SSTCollectionViewDelegateFlowLayout,UICollectionViewDelegate>)delegate
{
	_delegate = delegate;
	
	NSMutableDictionary *protocolResponseDict = [NSMutableDictionary dictionary];
	[protocolResponseDict setObject:@([_delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) forKey:NSStringFromSelector(@selector(collectionView:layout:insetForSectionAtIndex:))];
	[protocolResponseDict setObject:@([_delegate respondsToSelector:@selector(collectionView:layout:referenceHeightForHeaderInSection:)]) forKey:NSStringFromSelector(@selector(collectionView:layout:referenceHeightForHeaderInSection:))];
	[protocolResponseDict setObject:@([_delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) forKey:NSStringFromSelector(@selector(collectionView:layout:sizeForItemAtIndexPath:))];
	[self setProtocolResponseDict:protocolResponseDict];
}

- (void) prepareLayout
{
	[super prepareLayout];
	
	_layoutAttributes = nil;
	_layoutAttributesForHeaders = nil;
	
	self.delegate = (id<SSTCollectionViewDelegateFlowLayout,UICollectionViewDelegate>)self.collectionView.delegate;
	[self collectDatafromDelegate];
	[self createLayoutAttributes];
}

- (void) createLayoutAttributes
{
	UIEdgeInsets sectionInsets = UIEdgeInsetsZero;
	CGSize sectionHeaderSize = CGSizeZero;
	NSInteger numberOfItems = 0;
	
	CGFloat lastSectionMaxY = 0.0;
	
	NSMutableArray *layoutAttributes = [NSMutableArray array];
	NSMutableArray *layoutAttributesForHeader = [NSMutableArray array];
	NSMutableDictionary *indexPathsToLayoutAttributes = [NSMutableDictionary dictionary];
	
	for (NSInteger i = 0; i < _numberOfSections; i++) {
		
		[_currentRowAttributes removeAllObjects];
		[_emptyColumnAttributes removeAllObjects];
		
		CGSize availableSize = CGSizeMake(self.collectionView.bounds.size.width, CGFLOAT_MAX);
		
		/**
		 *  Adding contentInset
		 */
		[[_sectionsToSectionInsets objectForKey:@(i)] getValue:&sectionInsets];
		availableSize.width -= sectionInsets.left - sectionInsets.right;
		CGFloat fullAvailableWidth = availableSize.width;//Used to later reset the available size.
		
		/**
		 *  Adding header heights
		 */
		[[_sectionsToHeaderSizes objectForKey:@(i)] getValue:&sectionHeaderSize];
		
		UICollectionViewLayoutAttributes *headerAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForItem:0 inSection:i]];
		
		CGRect headerFrame = CGRectZero;
		headerFrame.origin.x = sectionInsets.left;
		headerFrame.size = sectionHeaderSize;
		if (!i) {
			headerFrame.origin.y = sectionInsets.top;
		}
		else {
			/**
			 *  If its not the first header
			 */
			UIEdgeInsets lastSectionInset;
			[[_sectionsToSectionInsets objectForKey:@(i-1)] getValue:&lastSectionInset];
			
			/**
			 *  Find out the ending point of last section
			 */
			
			headerFrame.origin.y = lastSectionMaxY + sectionInsets.top + lastSectionInset.bottom;
		}
		
		headerAttributes.frame = headerFrame;
		[layoutAttributesForHeader addObject:headerAttributes];
		
		[[_sectionsToItemsCount objectForKey:@(i)] getValue:&numberOfItems];
		
		for (NSInteger j = 0; j < numberOfItems; j++) {
			
			NSIndexPath *indexPath = [NSIndexPath indexPathForItem:j inSection:i];
			CGSize itemSize;
			[[_indexPathsToItemSizes objectForKey:indexPath] getValue:&itemSize];
			
			UICollectionViewLayoutAttributes *layoutAttribute = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
			CGRect frame = CGRectZero;
			frame.size = itemSize;
			
			if (_currentRowAttributes.count == 0) {
				/**
				 *  Means we are going to a new row.
				 */
				availableSize.width = fullAvailableWidth;
				availableSize.height = CGFLOAT_MAX;
			}
			
			if (!j) {
				/**
				 *  First Object, so just add it
				 */
				/**
				 *  Update availableSize
				 */
				availableSize.width -= itemSize.width;
				
				frame.origin.y = CGRectGetMaxY(headerAttributes.frame);
				frame.origin.x = CGRectGetMinX(headerAttributes.frame);
			}
			else {
				
				if (availableSize.width > itemSize.width + _itemSpacing) {
					/**
					 *  We do have space to put items horizontally.
					 */
					UICollectionViewLayoutAttributes *lastItemAttribute = [_currentRowAttributes lastObject];
					
					frame.origin.x = CGRectGetMaxX(lastItemAttribute.frame) + _itemSpacing;
					frame.origin.y = lastItemAttribute.frame.origin.y;
					
					/**
					 *  This is to ensure that when an item is added adjucent to the lastAttribute, the spacing between the item and whts on top of it is not les than the item spacing.
					 */
					CGRect minFrame = [self getMaxFrameFromAvailableAttributes:NO];
					if (CGRectGetMinY(frame) - CGRectGetMaxY(minFrame) < _itemSpacing && [self doesFrame:frame fallsBelowFrame:minFrame]) {
						frame.origin.y = CGRectGetMaxY(minFrame) + _itemSpacing;
					}
					
					frame = [self adjustFrame:CGRectIntegral(frame) soThatItDoesntIntersectAnyAttributesWithNewRowOriginX:CGRectGetMinX(headerAttributes.frame)];
					
					availableSize.width = fullAvailableWidth - CGRectGetMaxX(frame);
				}
				else {
					/**
					 *  We don't have the space, and must go to the next row.
					 */
					availableSize.width = fullAvailableWidth - CGRectGetMaxX(frame);
					availableSize.height = CGFLOAT_MAX;
					
					CGRect minFrame = [self getMaxFrameFromAvailableAttributes:NO];
					frame.origin.x = CGRectGetMinX(minFrame);
					frame.origin.y = CGRectGetMaxY(minFrame) + _itemSpacing;
					frame = [self adjustFrame:frame soThatItDoesntIntersectAnyAttributesWithNewRowOriginX:CGRectGetMinX(headerAttributes.frame)];
					[_currentRowAttributes removeAllObjects];
				}
			}
			
			layoutAttribute.frame = CGRectIntegral(frame);
			[_currentRowAttributes addObject:layoutAttribute];
			[layoutAttributes addObject:layoutAttribute];
			[indexPathsToLayoutAttributes setObject:layoutAttribute forKey:indexPath];
			[_emptyColumnAttributes addObject:layoutAttribute];
		}
		
		/**
		 *  We do not want to reset the last section's maxY if we don't have any objets in the section. Else it will be reset to zero.
		 */
		if (numberOfItems > 0) {
			CGRect maxFrame = [self getMaxFrameFromAvailableAttributes:YES];
			lastSectionMaxY = CGRectGetMaxY(maxFrame) + sectionInsets.bottom;
		}
		
		if (i == _numberOfSections - 1) {
			/**
			 *  Last section. So lets note the contentSize
			 */
			_contentSize = CGSizeMake(self.collectionView.bounds.size.width, lastSectionMaxY);
		}
		
	}
	
	[self setLayoutAttributes:layoutAttributes];
	[self setLayoutAttributesForHeaders:layoutAttributesForHeader];
	[self setIndexPathsToLayoutAttributes:indexPathsToLayoutAttributes];
}

- (CGRect) adjustFrame:(CGRect) frame soThatItDoesntIntersectAnyAttributesWithNewRowOriginX:(CGFloat) newRowOriginX
{
	NSMutableArray *attributes = [NSMutableArray arrayWithArray:_emptyColumnAttributes];
	
	/**
	 *  Adding the item spacing to see if the we need an adjustment for the frame.
	 */
	
	BOOL adjustmentRequired = NO;
	
	if (CGRectGetMaxX(frame) > self.collectionView.bounds.size.width) {
		adjustmentRequired = YES;
	}
	else {
		for (UICollectionViewLayoutAttributes *anAttribute in attributes) {
			if (CGRectIntersectsRect(frame, anAttribute.frame)) {
				adjustmentRequired = YES;
				break;
			}
		}
	}
	
	if (!adjustmentRequired) {
		[self updateEmptyColumnAttributesForFrame:frame];
		return frame;
	}
	
	/**
	 *  All the possible frames where we can put the new frame
	 */
	NSMutableArray *possibleFrames = [NSMutableArray array];
	for (UICollectionViewLayoutAttributes *anAttribute in attributes) {
		CGRect aPossiblFrame =  anAttribute.frame;
		aPossiblFrame.size = frame.size;
		aPossiblFrame.origin.y = CGRectGetMaxY(anAttribute.frame) + _itemSpacing;
		[possibleFrames addObject:[NSValue valueWithCGRect:aPossiblFrame]];
	}
	
	possibleFrames = [[possibleFrames sortedArrayWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(NSValue *obj1, NSValue *obj2) {
		
		CGRect frame1;
		[obj1 getValue:&frame1];
		
		CGRect frame2;
		[obj2 getValue:&frame2];
		
		if (CGRectGetMaxY(frame1) > CGRectGetMaxY(frame2)) {
			return NSOrderedDescending;
		}
		else if (CGRectGetMaxY(frame1) < CGRectGetMaxY(frame2)) {
			return NSOrderedAscending;
		}
		else {
			return NSOrderedSame;
		}
		
	}] mutableCopy];
	
	CGRect highestFrame;
	[[possibleFrames lastObject] getValue:&highestFrame];
	
	/**
	 *  out of all the possibilities, discard the one's that intersect with existing frames
	 */
	NSMutableArray *intersectingPossibilities = [NSMutableArray array];
	for (NSValue *aFrameValue in possibleFrames) {
		
		CGRect aFrame;
		[aFrameValue getValue:&aFrame];
		
		CGFloat maxX = CGRectGetMaxX(aFrame);
		for (UICollectionViewLayoutAttributes *anAttribute in attributes) {
			if (CGRectIntersectsRect(aFrame, anAttribute.frame) || maxX > self.collectionView.bounds.size.width) {
				[intersectingPossibilities addObject:aFrameValue];
			}
		}
	}
	
	[possibleFrames removeObjectsInArray:intersectingPossibilities];
	
	
	CGRect adjustedFrame;
	
	if (possibleFrames.count > 0) {
		/**
		 *  Lets choose the frame which has the lowest y position
		 */
		CGRect lowestYFrame;
		[[possibleFrames firstObject] getValue:&lowestYFrame];
		adjustedFrame = lowestYFrame;
	}
	else {
		/**
		 *  Lets just put it as a new row
		 */
		adjustedFrame = highestFrame;
		adjustedFrame.origin.x = newRowOriginX;
		
		[_currentRowAttributes removeAllObjects];
	}
	
	/**
	 *  We need to remove the attributes that are no longer a valid empty column choices.
	 */
	[self updateEmptyColumnAttributesForFrame:adjustedFrame];
	
	return adjustedFrame;
}

- (void) updateEmptyColumnAttributesForFrame:(CGRect) frame
{
	NSMutableArray *filledColunAttributes = [NSMutableArray array];
	for (UICollectionViewLayoutAttributes *anAttribute in _emptyColumnAttributes) {
		if ([self doesFrame:frame fallsBelowFrame:anAttribute.frame]) {
			[filledColunAttributes addObject:anAttribute];
		}
	}
	[_emptyColumnAttributes removeObjectsInArray:filledColunAttributes];
}

- (BOOL) doesFrame:(CGRect) frame1 fallsBelowFrame:(CGRect) frame2
{
	BOOL doesMaxXFallsBetweenTheFrame = CGRectGetMaxX(frame2) >= CGRectGetMinX(frame1) && CGRectGetMaxX(frame2) <= CGRectGetMaxX(frame1);
	
	BOOL doesMinXFallsBetweenFrame = CGRectGetMinX(frame2) >= CGRectGetMinX(frame1) && CGRectGetMinX(frame2) <= CGRectGetMaxX(frame1);
	
	BOOL doBordersAlign = CGRectGetMinX(frame2) == CGRectGetMinX(frame1) || CGRectGetMaxX(frame2) == CGRectGetMaxX(frame1);
	
	return (doesMinXFallsBetweenFrame || doesMaxXFallsBetweenTheFrame || doBordersAlign);
}

- (CGRect) getMaxFrameFromAvailableAttributes:(BOOL) max
{
	NSArray *sortedAttributes =  [_emptyColumnAttributes sortedArrayWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(UICollectionViewLayoutAttributes *obj1, UICollectionViewLayoutAttributes *obj2) {
		
		if (CGRectGetMaxY(obj1.frame) > CGRectGetMaxY(obj2.frame)) {
			return NSOrderedDescending;
		}
		else if (CGRectGetMaxY(obj1.frame) < CGRectGetMaxY(obj2.frame)) {
			return NSOrderedAscending;
		}
		else {
			return NSOrderedSame;
		}
	}];
	
	CGRect frame;
	if (max) {
		frame = [[sortedAttributes lastObject] frame];
	}
	else {
		frame = [[sortedAttributes firstObject] frame];
		
		/**
		 *  If the gap is below the this threshold value 20, we want to place it below another card that has that threshold gap. This is to avoid the card being placed under a card that has very little difference in height in the cards beside it.
		 */
		for (NSUInteger i = 1; i < sortedAttributes.count; i++) {
			CGRect nextHighestFrame = [sortedAttributes[i] frame];
			if ((CGRectGetMaxY(nextHighestFrame) - CGRectGetMaxY(frame) < _itemSpacing) && CGRectGetMaxY(nextHighestFrame) != CGRectGetMaxY(frame)) {
				frame = nextHighestFrame;
			}
		}
	}
	
	return frame;
}

- (void) collectDatafromDelegate
{
	/**
	 *  header Sizes and sections
	 */
	if ([self.collectionView.dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
		_numberOfSections = [self.collectionView.dataSource numberOfSectionsInCollectionView:self.collectionView];
	}
	else {
		_numberOfSections = 1;
	}
	
	NSMutableDictionary *sectionsToHeaderSizes = [NSMutableDictionary dictionary];
	NSMutableDictionary *sectionToItemCount = [NSMutableDictionary dictionary];
	NSMutableDictionary *indexPathsToItemSizes = [NSMutableDictionary dictionary];
	NSMutableDictionary *sectionToSectionInsets = [NSMutableDictionary dictionary];
	
	for (NSUInteger i = 0; i < _numberOfSections; i++) {
		
		/**
		 *  Section Inset
		 */
		UIEdgeInsets insets = UIEdgeInsetsZero;
		if ([[_protocolResponseDict objectForKey:NSStringFromSelector(@selector(collectionView:layout:insetForSectionAtIndex:))] boolValue]) {
			insets = [_delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:i];
		}
		[sectionToSectionInsets setObject:[NSValue valueWithUIEdgeInsets:insets] forKey:@(i)];
		
		/**
		 *  Size of the header
		 */
		CGSize headerSize = CGSizeMake(self.collectionView.bounds.size.width - insets.left - insets.right, 0.0);
		if ([[_protocolResponseDict objectForKey:NSStringFromSelector(@selector(collectionView:layout:referenceHeightForHeaderInSection:))] boolValue]) {
			headerSize.height = [_delegate collectionView:self.collectionView layout:self referenceHeightForHeaderInSection:i];
		}
		
		[sectionsToHeaderSizes setObject:[NSValue valueWithCGSize:headerSize] forKey:@(i)];
		
		/**
		 *  Number of items in section
		 */
		NSInteger numberOfItems = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:i];
		[sectionToItemCount setObject:@(numberOfItems) forKey:@(i)];
		
		/**
		 *  Items sizes for indexPaths
		 */
		for (NSInteger j = 0; j < numberOfItems; j++) {
			NSIndexPath *indexPath = [NSIndexPath indexPathForItem:j inSection:i];
			CGSize itemSize = CGSizeZero;
			if ([[_protocolResponseDict objectForKey:NSStringFromSelector(@selector(collectionView:layout:sizeForItemAtIndexPath:))] boolValue]) {
				itemSize = [_delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPath];
			}
			[indexPathsToItemSizes setObject:[NSValue valueWithCGSize:itemSize] forKey:indexPath];
		}
	}
	
	[self setSectionsToHeaderSizes:sectionsToHeaderSizes];
	[self setSectionsToItemsCount:sectionToItemCount];
	[self setIndexPathsToItemSizes:indexPathsToItemSizes];
	[self setSectionsToSectionInsets:sectionToSectionInsets];
}

- (CGSize) collectionViewContentSize
{
	return _contentSize;
}

- (BOOL) shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
	return NO;
}

- (UICollectionViewLayoutAttributes *) layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
	UICollectionViewLayoutAttributes *attributes = nil;
	attributes = [_indexPathsToLayoutAttributes objectForKey:indexPath];
	return attributes;
}

- (NSArray *) layoutAttributesForElementsInRect:(CGRect)rect
{
	NSMutableArray *attributes = [NSMutableArray array];
	
	for (UICollectionViewLayoutAttributes *anAttribute in _layoutAttributes) {
		if (CGRectIntersectsRect(anAttribute.frame, rect)) {
			[attributes addObject:anAttribute];
		}
	}
	
	for (UICollectionViewLayoutAttributes *anAttribute in _layoutAttributesForHeaders) {
		if (CGRectIntersectsRect(anAttribute.frame, rect)) {
			[attributes addObject:anAttribute];
		}
	}
	
	return attributes;
}

- (UICollectionViewLayoutAttributes *) layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
	UICollectionViewLayoutAttributes *attribute  = nil;
	
	if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
		
		for (UICollectionViewLayoutAttributes *anAttribute in _layoutAttributesForHeaders) {
			if ([anAttribute.indexPath isEqual:indexPath]) {
				attribute = anAttribute;
				break;
			}
		}
	}
	
	return attribute;
}

@end

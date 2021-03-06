//
//  NITimelineTableModel.m
//  NimbusTimeline
//
//  Created by Lee jimney on 7/27/13.
//  Copyright (c) 2013 jimneylee. All rights reserved.
//

#import "OSCBaseTableModel.h"
#import "OSCAuthModel.h"

@interface OSCBaseTableModel()

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation OSCBaseTableModel

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithDelegate:(id<NITableViewModelDelegate>)delegate
{
	self = [super initWithDelegate:delegate];
	if (self) {
        
        self.superElementName = nil;
        self.itemElementName = nil;
        self.listElementName = nil;
	}
	return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Override

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString*)relativePath
{
    return nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSDictionary*)generateParameters
{
    if ([OSCGlobalConfig getAuthAccessToken]) {
        NSDictionary *parameters = @{@"access_token" : [OSCGlobalConfig getAuthAccessToken],
                                     @"dataType"     : @"xml"};
        return parameters;
    }
    return nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)apiSharedClient
{
    return [OSCAPIClient sharedClient];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loadDataWithBlock:(void(^)(NSArray* indexPaths, NSError *error))block
                     more:(BOOL)more refresh:(BOOL)refresh
{
    // 每次请求都要判断token是否过期，似乎有点不合理，
    // 但是还没有找到更好的解决token过期的检测问题
    
    if (![OSCGlobalConfig checkAuthValid]) {
        if (block) {
            NSError* error = [[NSError alloc] init];
            block(nil, error);
        }
        return;
    }
    
    self.showIndexPathsBlock = block;
    if (self.isLoading) {
        return;
    }
    else {
        self.isLoading = YES;
    }
    if (more) {
        self.pageIndex++;
    }
    else {
        self.pageIndex = self.pageStartIndex;
    }
    NSString* relativePath = [self relativePath];
    if (relativePath.length > 0
        && [[self apiSharedClient] respondsToSelector:@selector(GET:parameters:refresh:success:failure:)]) {
        
        [[self apiSharedClient] GET:relativePath parameters:[self generateParameters]  refresh:refresh
                                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                    self.isLoading = NO;
                                    if (!more) {
                                        if (self.sections.count > 0) {
                                            [self removeSectionAtIndex:0];
                                        }
                                    }
                                    if ([responseObject isKindOfClass:[NSXMLParser class]]) {
                                        NSXMLParser* parser = (NSXMLParser*)responseObject;
                                        [parser setShouldProcessNamespaces:YES];
                                        parser.delegate = self;
                                        [parser parse];
                                    }
                                    else {
                                        if (block) {
                                            NSError* error = [[NSError alloc] init];
                                            block(nil, error);
                                        }
                                    }
                                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                    self.isLoading = NO;
                                    if (block) {
                                        block(nil, error);
                                    }
                                }];
    }
    else {
        self.isLoading = NO;
        NSLog(@"Error: can not find method (getPath:parameters:refresh:success:failure:)");
        if (block) {
            NSError* error = [[NSError alloc] init];
            block(nil, error);
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)parseDataToIndexPaths
{
    NSArray* entities = nil;
    if (self.listDataArray.count) {
        entities = [self entitiesParsedFromResponseObject:self.listDataArray];
    }
    NSArray* indexPaths = nil;
    if (entities.count) {
        indexPaths = [self addObjectsFromArray:entities];
    }
    else {
        // just set empty array, show empty data but no error
        indexPaths = [NSArray array];
    }
    if (self.showIndexPathsBlock) {
        self.showIndexPathsBlock(indexPaths, nil);
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didFinishLoad
{
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didFailLoad
{
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSXMLParserDelegate

///////////////////////////////////////////////////////////////////////////////////////////////////
//http://www.raywenderlich.com/zh-hans/36079/afnetworking%E9%80%9F%E6%88%90%E6%95%99%E7%A8%8B%EF%BC%881%EF%BC%89
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:self.listElementName]) {
        self.listDataArray = [NSMutableArray arrayWithCapacity:self.pageSize];
    }
    
    // set super element and create dic
    else if ([elementName isEqualToString:self.itemElementName]
             || [elementName isEqualToString:XML_RESULT]
             || [elementName isEqualToString:XML_NOTICE]) {
        self.currentDictionary = [NSMutableDictionary dictionary];
        self.superElementName = elementName;
    }
    
    // tmptext to store value in <e>value</e>
    if ([self.superElementName isEqualToString:self.itemElementName]
        || [self.superElementName isEqualToString:XML_RESULT]
        || [self.superElementName isEqualToString:XML_NOTICE]) {
        self.tmpInnerElementText = [[NSMutableString alloc] init];;
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    if (self.tmpInnerElementText) {
        [self.tmpInnerElementText appendString:string];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // add each item's dictionary to list array
    if ([elementName isEqualToString:self.itemElementName]) {
        [self.listDataArray addObject:self.currentDictionary];
        self.currentDictionary = nil;
        self.superElementName = nil;
    }
    // get result error entity
    else if ([elementName isEqualToString:XML_RESULT]) {
        self.errorEntity = [OSCErrorEntity entityWithDictionary:self.currentDictionary];
        self.currentDictionary = nil;
        self.superElementName = nil;
    }
    // get notice entity
    else if ([elementName isEqualToString:XML_NOTICE]) {
        self.noticeEntiy = [OSCNoticeEntity entityWithDictionary:self.currentDictionary];
        self.currentDictionary = nil;
        self.superElementName = nil;
    }
    // set objects to item's dictionary
    else if ([self.superElementName isEqualToString:self.itemElementName]) {
        if (self.currentDictionary && self.tmpInnerElementText) {
            [self.currentDictionary setObject:self.tmpInnerElementText forKey:elementName];
        }
    }
    
    self.tmpInnerElementText = nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    if (!self.errorEntity || self.errorEntity.errorCode == ERROR_CODE_SUCCESS_200) {
        [self parseDataToIndexPaths];
        [self didFinishLoad];
    }
    else {
        NSError* error = [[NSError alloc] init];
        if (self.showIndexPathsBlock) {
            self.showIndexPathsBlock(nil, error);//TODO: error -> error entity
        }
        [self didFailLoad];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"Paser Error = %@", parseError);
    NSError* error = [[NSError alloc] init];
    if (self.showIndexPathsBlock) {
        self.showIndexPathsBlock(nil, error);//TODO: error -> error entity
    }
    [self didFailLoad];
}

@end

#import "SMXMLDocument.h"

NSString *const SMXMLDocumentErrorDomain = @"SMXMLDocumentErrorDomain";

static NSError *SMXMLDocumentError(NSXMLParser *parser, NSError *parseError) {	
	NSMutableDictionary *userInfo = [@{NSUnderlyingErrorKey : parseError} mutableCopy];
	NSNumber *lineNumber = @(parser.lineNumber);
	NSNumber *columnNumber = @(parser.columnNumber);
	userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:NSLocalizedString(@"Malformed XML document. Error at line %@:%@.", @""), lineNumber, columnNumber];
	userInfo[@"LineNumber"] = lineNumber;
	userInfo[@"ColumnNumber"] = columnNumber;
	return [NSError errorWithDomain:SMXMLDocumentErrorDomain code:1 userInfo:userInfo];
}

@implementation SMXMLElement
@synthesize document, parent, name, value, children, attributes;

- (id)initWithDocument:(SMXMLDocument *)aDocument {
	self = [super init];
	if (self)
		self.document = aDocument;
	return self;
}

- (void)dealloc {
	self.document = nil;
	self.parent = nil;
}

- (NSString *)descriptionWithIndent:(NSString *)indent {

	NSMutableString *s = [NSMutableString string];
	[s appendFormat:@"%@<%@", indent, name];
	
	for (NSString *attribute in attributes)
		[s appendFormat:@" %@=\"%@\"", attribute, attributes[attribute]];

	NSString *trimVal = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	if (trimVal.length > 25)
		trimVal = [NSString stringWithFormat:@"%@…", [trimVal substringToIndex:25]];
	
	if (children.count) {
		[s appendString:@">\n"];
		
		NSString *childIndent = [indent stringByAppendingString:@"  "];
		
		if (trimVal.length)
			[s appendFormat:@"%@%@\n", childIndent, trimVal];

		for (SMXMLElement *child in children)
			[s appendFormat:@"%@\n", [child descriptionWithIndent:childIndent]];
		
		[s appendFormat:@"%@</%@>", indent, name];
	}
	else if (trimVal.length) {
		[s appendFormat:@">%@</%@>", trimVal, name];
	}
	else [s appendString:@"/>"];
	
	return s;	
}

- (NSString *)description {
	return [self descriptionWithIndent:@""];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	
	if (!string) return;
	
	if (value)
		[(NSMutableString *)value appendString:string];
	else
		self.value = [NSMutableString stringWithString:string];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	SMXMLElement *child = [[SMXMLElement alloc] initWithDocument:self.document];
	child.parent = self;
	child.name = elementName;
	child.attributes = attributeDict;
	
	if (children)
		[(NSMutableArray *)children addObject:child];
	else
		self.children = [@[child] mutableCopy];
	
	[parser setDelegate:child];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	[parser setDelegate:parent];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	self.document.error = SMXMLDocumentError(parser, parseError);
}

- (SMXMLElement *)childNamed:(NSString *)nodeName {
	for (SMXMLElement *child in children)
		if ([child.name isEqual:nodeName])
			return child;
	return nil;
}

- (NSArray *)childrenNamed:(NSString *)nodeName {
	NSMutableArray *array = [NSMutableArray array];
	for (SMXMLElement *child in children)
		if ([child.name isEqual:nodeName])
			[array addObject:child];
	return [array copy];
}

- (SMXMLElement *)childWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue {
	for (SMXMLElement *child in children)
		if ([[child attributeNamed:attributeName] isEqual:attributeValue])
			return child;
	return nil;
}

- (NSString *)attributeNamed:(NSString *)attributeName {
	return attributes[attributeName];
}

- (SMXMLElement *)descendantWithPath:(NSString *)path {
	SMXMLElement *descendant = self;
	for (NSString *childName in [path componentsSeparatedByString:@"."])
		descendant = [descendant childNamed:childName];
	return descendant;
}

- (NSString *)valueWithPath:(NSString *)path {
	NSArray *components = [path componentsSeparatedByString:@"@"];
	SMXMLElement *descendant = [self descendantWithPath:components[0]];
	return [components count] > 1 ? [descendant attributeNamed:components[1]] : descendant.value;
}


- (SMXMLElement *)firstChild { return [children count] > 0 ? children[0] : nil; }
- (SMXMLElement *)lastChild { return [children lastObject]; }

@end

@implementation SMXMLDocument
@synthesize root, error;

- (id)initWithData:(NSData *)data error:(NSError **)outError {
    self = [super init];
	if (self) {
		NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
		[parser setDelegate:self];
		[parser setShouldProcessNamespaces:YES];
		[parser setShouldReportNamespacePrefixes:YES];
		[parser setShouldResolveExternalEntities:NO];
		[parser parse];
		
		if (self.error) {
			if (outError)
				*outError = self.error;
			return nil;
		}
        else if (outError)
            *outError = nil;
	}
	return self;
}


+ (SMXMLDocument *)documentWithData:(NSData *)data error:(NSError **)outError {
	return [[SMXMLDocument alloc] initWithData:data error:outError];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	
	self.root = [[SMXMLElement alloc] initWithDocument:self];
	root.name = elementName;
	root.attributes = attributeDict;
	[parser setDelegate:root];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	self.error = SMXMLDocumentError(parser, parseError);
}

- (NSString *)description {
	return root.description;
}

@end

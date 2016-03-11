//
//  MessageTableItemVideo.m
//  Telegram P-Edition
//
//  Created by Dmitry Kondratyev on 2/13/14.
//  Copyright (c) 2014 keepcoder. All rights reserved.
//

#import "MessageTableItemVideo.h"
#import "ImageUtils.h"
#import "NSStringCategory.h"
#import "NSString+Extended.h"
#import "NSAttributedString+Hyperlink.h"
#import "MessageTableCellVideoView.h"
@implementation MessageTableItemVideo

- (id) initWithObject:(TLMessage *)object {
    self = [super initWithObject:object];
    if(self) {
       
        [self rebuildTimeString];
        
        
        [self rebuildImageObject];
                
        [self checkStartDownload:[self.message.to_id isKindOfClass:[TL_peerChat class]] ? AutoGroupVideo : AutoPrivateVideo size:self.message.media.document.size];
    }
    return self;
}


-(void)rebuildImageObject {
    
    TLDocument *document = self.message.media.document;
    TLPhotoSize *photoSize = document.thumb;
    NSImage *placeholder;
    
    
    if([photoSize isKindOfClass:[TL_photoCachedSize class]]) {
        placeholder = [[NSImage alloc] initWithData:photoSize.bytes];
    }
    
    NSImage *image = [TGCache cachedImage:document.thumb.location.cacheKey];
    
    if(!image) {
        image = fileSize(document.thumb.location.path) > photoSize.size ? imageFromFile(document.thumb.location.path) : nil;
    }
    
    
    NSSize blockSize = NSMakeSize(photoSize.w , photoSize.h );
    
    self.imageObject = [[TGImageObject alloc] initWithLocation:image == nil && !placeholder ? photoSize.location : nil placeHolder:image == nil ? placeholder : image];
    
    self.imageObject.imageSize = blockSize;
    self.imageObject.thumbProcessor = image == nil ? [ImageUtils b_processor] : nil;
    self.imageObject.imageProcessor = [ImageUtils b_processor];
}

-(BOOL)makeSizeByWidth:(int)width {
    
    TL_documentAttributeVideo *video = (TL_documentAttributeVideo *) [self.message.media.document attributeWithClass:[TL_documentAttributeVideo class]];
    
    _videoSize = strongsize(NSMakeSize(video.w, video.h), MIN(320,width));
    

    
    
     self.blockSize = NSMakeSize(_videoSize.width, _videoSize.height);
    
    return [super makeSizeByWidth:width];
}

-(DownloadItem *)downloadItem {
    if(super.downloadItem == nil)
        [super setDownloadItem:[DownloadQueue find:self.message.media.document.n_id]];
    
    return [super downloadItem];
}

- (Class)downloadClass {
    return [DownloadVideoItem class];
}

-(void)rebuildTimeString {
    
    NSString *sizeInfo = self.message.media.document.size == 0 ? NSLocalizedString(@"Message.Send.Compressing", nil) : [NSString sizeToTransformedValue:self.message.media.document.size];
    
    TL_documentAttributeVideo *video = (TL_documentAttributeVideo *) [self.message.media.document attributeWithClass:[TL_documentAttributeVideo class]];
    
    
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:[[NSString durationTransformedValue:video.duration] stringByAppendingString:@", "] attributes:@{NSForegroundColorAttributeName: [NSColor whiteColor] }];
    
    
    [attr appendString:sizeInfo withColor:NSColorFromRGB(0xffffff)];
    
    [attr setFont:TGSystemFont(13) forRange:attr.range];
    
    self.videoTimeAttributedString = attr;
    
    
    NSSize size = [self.videoTimeAttributedString size];
    size.width = ceil(size.width + 14);
    size.height = ceil(size.height + 5);
    self.videoTimeSize = size;
}

- (NSString *)filePath {
    return mediaFilePath(self.message);
}

-(BOOL)isset {
    NSString *path = [self filePath];
    return isPathExists(path) && [FileUtils checkNormalizedSize:path checksize:self.message.media.document.size];
}

-(BOOL)needUploader {
    return YES;
}


-(void)doAfterDownload {
    [self rebuildImageObject];
    
}

-(Class)viewClass {
    return [MessageTableCellVideoView class];
}

-(BOOL)canDownload {
    return self.message.media.document.dc_id != 0;
}

@end

//
//  ADSAudioClass.h
//  ADSAudioCtr
//
//  Created by ADSmart Tech on 15/11/4.
//  Copyright © 2015年 ADSmart Tech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "EZAudio.h"
@interface ADSAudioClass : NSObject

-(ADSAudioClass *)init;
-(void)mySendData:(unsigned char *)sData len:(unsigned char)len;
@end

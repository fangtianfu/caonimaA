//
//  ADSAudioClass.m
//  ADSAudioCtr
//
//  Created by ADSmart Tech on 15/11/4.
//  Copyright © 2015年 ADSmart Tech. All rights reserved.
//

#import "ADSAudioClass.h"
@interface ADSAudioClass()
{
    AudioUnit remoteIOUnit;
    AUNode remoteIONode;
    AUGraph auGraph;
}
@end

#define AMPLITUDE (1<<24)
#define HIGHLOWTHREHOLD 5000
#define HIGH (-(1<<24))
#define LOW  (1<<24)


static BOOL StatusInAndOut = false;
static bool SendInitEnabled = true;
static bool InitEnabled    = false;
static bool SendNextEnabled = false;
static int  HandleProcess = 0;
static unsigned char SendDataBuf[20];
static int SendDataLen = 0;
static int SendCnt = 0;
static BOOL RecAnalysisEabled = false;

static SInt16 HeadIn = 0;
static int tempSendBuf[10240];
static int TheLastData[20];
static int SendIndex =0;
static int HasSendIndex = 0;
static bool SendEnabled = false;

static bool RecEnabled = false;
static int RecIndex = 0;
static int RecData[204800];


@implementation ADSAudioClass


-(void)mySendData:(unsigned char *)sData len:(unsigned char)len
{
    
    memset(SendDataBuf,0,20);
    memcpy(SendDataBuf, sData, len);
    memset(tempSendBuf,0,10240);
    SendIndex = 0;
    SendDataLen = len;
    SendData(sData, len);
    HandleProcess = 2;
    
}

void SendData (unsigned char *sData ,int len)
{
    NSLog(@" sendDataLen :%d",len);
    int sendDataArray[len];
    for (int myi = 0; myi < len ; myi++)
    {
        sendDataArray[myi] = (int)(sData[myi]);
        printf("sendData = %0x\n",sData[myi]);
    }
    
    memset(RecData,0,204800);
    
    if (SendInitEnabled)
    {
        SendInitEnabled = false;
        
    }
    SendEnabled = false;
    
    for (int l =0 ; l<22; l++)
    {
        tempSendBuf[SendIndex] = LOW;
        SendIndex++;
    }
    
    for (int i = 0 ; i<len; i++)
    {
        //printf("\n");
        //NSLog(@"Show the Data Current : %x ,SendIndex :%d",sendDataArray[i],SendIndex);
        for (int j = 0; j<8; j++)
        {
            if(sendDataArray[i]&(1<<(7-j)))
            {
                printf("1");
                for (int k = 0;k<22; k++)
                {
                    if (k<12)
                    {
                        tempSendBuf[SendIndex] = HIGH;
                        SendIndex++;
                    }else
                    {
                        tempSendBuf[SendIndex] = LOW;
                        SendIndex++;
                    }
                    
                }
                
            }else
            {
                printf("0");
                for (int l =0 ; l<44; l++)
                {
                    if (l<23)
                    {
                        tempSendBuf[SendIndex] =HIGH;
                        SendIndex++;
                    }else
                    {
                        tempSendBuf[SendIndex] =LOW;
                        SendIndex++;
                    }
                    
                }
                
            }
        }
        
    }
    HasSendIndex = 0;
    SendCnt = 0;
    SendEnabled = true;
}

void RecAnalysis()
{
    int tempSecData[25600];
    memset(tempSecData, 0, 102400);
    int tempSecIndex = 0;
    int SecIndexEnabled = false;
    tempSecIndex = 1;
    
    tempSecData[tempSecIndex] = 0;
    
    int changeValue = 0;
    int realdataIndex = 0;
    for(int j = 1; j < RecIndex; j++)
    {
        //NSLog(@"RealDataCount : %d",RecData[j]);
        if (!InitEnabled)
        {
            HandleProcess = 1;
            return ;
        }
        tempSecData[tempSecIndex]++;
        changeValue++;
        if((RecData[j]>=HIGHLOWTHREHOLD)&&(RecData[j-1]<HIGHLOWTHREHOLD))
        {
            
            if (changeValue <3)
            {
                SecIndexEnabled = false;
                tempSecData[tempSecIndex]+=changeValue;
            }else
            {
                tempSecIndex++;
                SecIndexEnabled = true;
                tempSecData[tempSecIndex] = 0;
            }
            changeValue = 0;
        }else if ((RecData[j]<HIGHLOWTHREHOLD)&&(RecData[j-1]>=HIGHLOWTHREHOLD))
        {
            if (changeValue <3)
            {
                if(SecIndexEnabled)
                {
                    if (tempSecIndex >1)
                    {
                        tempSecIndex--;
                    }
                    
                }
                tempSecData[tempSecIndex]+=changeValue;
            }
            
            changeValue = 0;
        }
    }
    int RealDataBitIndex = 0;
    int RealData;
    int TempRealData[128];
    memset(TempRealData, 0, 128);
    memset(TheLastData, 0, 20);
    
    TempRealData[0] = 0;
    for (int i = 0; i<tempSecIndex; i++)
    {
        if (!InitEnabled)
        {
            HandleProcess = 1;
            return ;
        }
        if ((tempSecData[i]<18)||(tempSecData[i]>50))
        {
            NSLog(@"count  %d error %d",tempSecData[i],i);
            RealDataBitIndex = 0;
            RealData = 0;
        }else
        {
            if ((tempSecData[i]>17)&&(tempSecData[i]<30))
            {
                NSLog(@"count  %d 1 %d",tempSecData[i],i);
                RealData |= 1<<(7-RealDataBitIndex);
            }else
            {
                NSLog(@"count  %d 0 %d",tempSecData[i],i);
                RealData &= ~(1<<(7-RealDataBitIndex));
            }
            RealDataBitIndex++;
        }
        if(RealDataBitIndex>7)
        {
            RealDataBitIndex = 0;
            TempRealData[realdataIndex]= RealData;
            realdataIndex++;
            RealData = 0;
        }
    }
    RecAnalysisEabled = false;
    bool read = true;
    
    for (int i =1 ; i<128; i++)
    {
        if (!InitEnabled)
        {
            HandleProcess = 1;
            return ;
        }
        // printf("TempRealData : %x  ,i:%d\n",TempRealData[i],i);
        if((TempRealData[i] == 0x5A)&&(TempRealData[i-1] == 0xFF))
        {
            printf("\n The Last Data: ");
            TheLastData[0] = 0xFF;
            TheLastData[1] = 0xFF;
            for (int j = 2; j<13; j++)
            {
                TheLastData[j] = TempRealData[(i+j-2)];
                printf("  %x ",TheLastData[j]);
            }
            printf("\n");
            
          //  [hiJackMgr->theDelegate receive:TheLastData];
            read = false;
            break;
        }
    }
    if (read)
    {
        NSLog(@"send now!,%d,%d",SendInitEnabled,SendCnt);
        
        // if(!SendInitEnabled)
        {
            if(SendCnt <5)
            {
                SendCnt++;
                SendInitEnabled = false;
                HasSendIndex = 0;
                HandleProcess = 2;
            }else
            {
                SendCnt = 0;
                SendInitEnabled = true;
                InitEnabled = false;
                HeadIn = 80;
               // [hiJackMgr->theDelegate SendTimeOut];
                
            }
        }
        
    }else
    {
        SendInitEnabled = true;
        HasSendIndex = 0;
        SendCnt = 0;
        HandleProcess = 0;
    }
    // NSLog(@"rec success now!");
}



-(void) outputDeviceChanged:(NSNotification *)aNotification
{
    BOOL TempOutInEnabled = false;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSInteger reason = [[[aNotification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (reason)
    {
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"] Audio Route: The route changed because no suitable route is now available for the specified category.");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"] Audio Route: The route changed when the device woke up from sleep.");
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"] Audio Route: The output route was overridden by the app.");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"] Audio Route: The category of the session object changed.");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"] Audio Route: The previous audio output path is no longer available.");
            break;
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            {
                TempOutInEnabled = true;
                NSLog(@"] Audio Route: A preferred new audio output path is now available.");
            }
            break;
        case AVAudioSessionRouteChangeReasonUnknown:
            NSLog(@"] Audio Route: The reason for the change is unknown.");
            break;
        default:
            NSLog(@"] Audio Route: The reason for the change is very unknown.");
            break;
    }
    
    // Input
    AVAudioSessionPortDescription *input = [[session.currentRoute.inputs count] ? session.currentRoute.inputs:nil objectAtIndex:0];
    
    if ([input.portType isEqualToString:AVAudioSessionPortLineIn]) {
        NSLog(@"] Audio Route: Input Port: LineIn");
    }
    else if ([input.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
        NSLog(@"] Audio Route: Input Port: BuiltInMic");
    }
    else if ([input.portType isEqualToString:AVAudioSessionPortHeadsetMic])
    {
        if(TempOutInEnabled)
        {
            HeadIn = 80;
            HandleProcess = 1;
            SendInitEnabled = true;
            StatusInAndOut = true;
            InitEnabled = false;
            AudioOutputUnitStart(remoteIOUnit);
           // [EZAudio checkResult:AUGraphStart(auGraph) operation:"couldn't AUGraphStart"];
            
        }
        NSLog(@"] Audio Route: Input Port: HeadsetMic");
    }
    else if ([input.portType isEqualToString:AVAudioSessionPortBluetoothHFP]) {
        NSLog(@"] Audio Route: Input Port: BluetoothHFP");
    }
    else if ([input.portType isEqualToString:AVAudioSessionPortUSBAudio]) {
        NSLog(@"] Audio Route: Input Port: USBAudio");
    }
    else if ([input.portType isEqualToString:AVAudioSessionPortCarAudio]) {
        NSLog(@"] Audio Route: Input Port: CarAudio");
    }
    else {
        NSLog(@"] Audio Input Port: Unknown: %@",input.portType);
    }
    if(!TempOutInEnabled)
    {
        StatusInAndOut = false;
        InitEnabled = false;
        HandleProcess = 0;
        SendInitEnabled = true;
        RecAnalysisEabled = false;
        RecEnabled        =false;
        SendEnabled       =false;
        HeadIn = 80;
        AudioOutputUnitStop(remoteIOUnit);
        //[EZAudio checkResult:AUGraphStop(auGraph) operation:"couldn't AUGraphStart"];
    }
    
    

    
    NSLog(@"]-------------------[ %s ]----------------[",__FUNCTION__);
}

-(void) audiosessionInterrupt:(NSNotification *)aNotification
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSInteger reason = [[[aNotification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (reason)
    {
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"] Audio Route: The route changed because no suitable route is now available for the specified category.");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"] Audio Route: The route changed when the device woke up from sleep.");
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"] Audio Route: The output route was overridden by the app.");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            {
                HandleProcess = 0;
                NSLog(@"] Audio Route: The category of the session object changed.");
            }
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"] Audio Route: The previous audio output path is no longer available.");
            break;
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"] Audio Route: A preferred new audio output path is now available.");
            break;
        case AVAudioSessionRouteChangeReasonUnknown:
            NSLog(@"] Audio Route: The reason for the change is unknown.");
            break;
        default:
            NSLog(@"] Audio Route: The reason for the change is very unknown.");
            break;
    }
    
        NSLog(@"]-------------------[ %s ]----------------[",__FUNCTION__);
    
}

//依照Apple提供的结果，PerformThru以C语言的Static Function存在的，所以放在上端
//里面根据声音的情况进行处理
    
static OSStatus PerformThru(void *inRefCon,AudioUnitRenderActionFlags *ioActionFlags,const AudioTimeStamp *inTimeStamp,UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
    ADSAudioClass *THIS = (__bridge ADSAudioClass *)inRefCon; //c语言里面没有当前对象指针,所以要把控制对象的指针传进来
    //AudioUnitRender将Remote I/O的输入端数据读进来，其中每次数据是以Frame存在的，
    //每笔Frame有N笔音频数据内容(这与类比特数的概念有关，在此会以每笔Frame有N点)，2声道就是乘上2倍的数据量，
    //整个数据都存在例子中的ioData指针中
  OSStatus renderErr = AudioUnitRender(THIS->remoteIOUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
    
    
    
    if (renderErr <0)
    {
        return renderErr;
    }
    SInt32* lchannel = (SInt32*)(ioData->mBuffers[0].mData);
    // ioData->mBuffers[i].mData 声音数据
    // ioData->mBuffers[i].mDataByteSize 声音数据长度 Apple一般会提供1024
     switch (HandleProcess)
        {
            case 0:
            {
                memset(ioData->mBuffers[1].mData, 0, ioData->mBuffers[1].mDataByteSize);
            }
                break;
            case 1:
            {
                memset(ioData->mBuffers[1].mData, 0, ioData->mBuffers[1].mDataByteSize);
            }
                break;
            case 2:
            {
                if (SendNextEnabled)
                {
                    SendNextEnabled = false;
                    printf("sendNextEnabled\n");
                    break;
                }
                SendNextEnabled = true;
                SInt32 values[inNumberFrames];
                memset(values, HIGH, sizeof(values));
               // printf("send start %d,%d,%d\n",HasSendIndex,inNumberFrames,SendIndex);
                for(int j = 0; j < (inNumberFrames); j++)
                {
                    if (HasSendIndex >= SendIndex)
                    {
                        values[j] = HIGH;
                        SendEnabled = false;
                        RecEnabled  = true;
                        RecIndex = 0;
                        HandleProcess = 3;
                        break;
                    }else
                    {
                        values[j] = tempSendBuf[HasSendIndex];
                        HasSendIndex++;
                        HandleProcess = 2;
                    }
    
                }
                printf("send end %d,%d,%d\n",HasSendIndex,inNumberFrames,SendIndex);
                memcpy(ioData->mBuffers[1].mData, values, ioData->mBuffers[1].mDataByteSize);
                SendNextEnabled = false;
            }
                break;
            case 3:
            {
                memset(ioData->mBuffers[1].mData, 0, ioData->mBuffers[1].mDataByteSize);
                if ((RecIndex +inNumberFrames)<10240)
                {
                    for(int j = 0; j < (inNumberFrames); j++)
                    {
                        if (RecEnabled )
                        {
                            RecData[(j+RecIndex)] = (int)(lchannel[j]);
                        }
                    }
                    RecIndex+=inNumberFrames;
                    HandleProcess = 3;
                }else
                {
                    RecEnabled = false;
                  //  RecAnalysisEabled = true;
                    HandleProcess = 4;
                }
    
            }
                break;
            case 4:
            {
                memset(ioData->mBuffers[1].mData, 0, ioData->mBuffers[1].mDataByteSize);
               // RecAnalysis();
                // HandleProcess = 5;
            }
                break;
    
            default:
                memset(ioData->mBuffers[1].mData, 0, ioData->mBuffers[1].mDataByteSize);
                break;
        }
    double waves;
    static UInt32 phase = 0;
    SInt32 lvalues[inNumberFrames*4];
    for(int j = 0; j < inNumberFrames*4; j++)
    {
        waves = 0;
       // waves += sin(M_PI * 2.0f /  22050.0 * phase);
        waves += sin(3.1425196 * (phase+0.5)); // This should be 22.050kHz
        waves *= (HIGH); // <--------- make sure to divide by how many waves you're stacking
        lvalues[j] = (SInt32)waves;
        phase++;
        //printf("lvalues %d\n",lvalues[j]);
    }
    printf(" %u %i",inNumberFrames,ioData->mBuffers[0].mDataByteSize);
    memcpy(ioData->mBuffers[0].mData, lvalues, ioData->mBuffers[0].mDataByteSize);

    return  noErr;
}

-(ADSAudioClass *) init
{
    self = [super init];
 
    if (self)
    {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        NSError *error;
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        [audioSession setPreferredSampleRate:44100.0 error:&error];
        
        
        //Audio Processing Graph(AUGraph)将多个输入声音进行混合，以及需要处理音讯资料时可以加入一个render的回调(callback)，
        // 完成后需要像打开文件一样开启它，这里使用AUGraphOpen，接下来就可以开始使用AUGraph相关设定，在使用与AUGraph有关时会在命名前面加上AUGraph，像是：
        //    AUGraphSetNodeInputCallback 设定回调时会被调用的Function
        //    AUGraphInitialize 初始化AUGraph
        //    AUGraphUpdate 更新AUGraph，当有增加Node或移除时可以执行这将整个AUGraph规则更新
        //    AUGraphStart 所有设定都无误要开始执行AUGraph功能。
        [EZAudio checkResult:NewAUGraph(&auGraph) operation:"couldn't NewAUGraph"];
        [EZAudio checkResult:AUGraphOpen(auGraph) operation:"couldn't AUGraphOpen"];
        //    AUGraphInitialize 初始化AUGraph
        [EZAudio checkResult:AUGraphInitialize(auGraph) operation:"couldn't AUGraphInitialize"];
        
        ////    typedef struct AudioComponentDescription {
        //        /*一个音频组件的通用的独特的四字节码标识*/
        //        OSType              componentType;
        //        /*根据componentType设置相应的类型*/
        //        OSType              componentSubType;
        //        /*厂商的身份验证*/
        //        OSType              componentManufacturer;
        //        /*如果没有一个明确指定的值，那么它必须被设置为0*/
        //        UInt32              componentFlags;
        //        /*如果没有一个明确指定的值，那么它必须被设置为0*/
        //        UInt32              componentFlagsMask;
        //    } AudioComponentDescription;
        AudioComponentDescription componentDesc;
        componentDesc.componentType = kAudioUnitType_Output;//编解码选项,可选mixer
        componentDesc.componentSubType = kAudioUnitSubType_RemoteIO;
        componentDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
        componentDesc.componentFlags = 0;
        componentDesc.componentFlagsMask = 0;
        //AUGraph中必需要加入功能性的Node才能完成
        //加入成功后利用Node的资料来取得这个Node的Audio Unit元件，对於Node中的一些细项设定必需要靠取得的Audio Unit元件来设定。
        //前面Remote I/O Unit中看到利用AudioUnitSetProperty设定时必需要指定你要哪个Audio Unit，每一个Node都是一个Audio Unit，
        //都能对它做各别的设定，设定的方式是一样的，但参数不一定相同，像在设定kAudioUnitType_Mixer时，可以设定它输入要几个Channel
        [EZAudio checkResult:AUGraphAddNode(auGraph, &componentDesc, &remoteIONode) operation:"couldn't add remote io node"];
        [EZAudio checkResult:AUGraphNodeInfo(auGraph, remoteIONode, NULL, &remoteIOUnit) operation:"couldn't get remote io unit from node"];
        //set BUS Remote I/O Unit是属于Audio Unit其中之一，也是与硬件有关的一个Unit，它分为输出端与输入端，输入端通常为 麦克风 ，输出端为 喇叭、耳机 …等
        //将Element 0的Output scope与喇叭接上，Element 1的Input scope与麦克风接上
        //然后通过AUGraph把Element 0和Element 1接上
        UInt32 oneFlag = 1;
        UInt32 busZero = 0;
        [EZAudio checkResult:AudioUnitSetProperty(remoteIOUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, busZero, &oneFlag, sizeof(oneFlag)) operation:"couldn't  set kAudioOutputUnitProperty_EnabledIO with kAudioUnitScope_Output"];
        
        UInt32 busOne = 1;
        [EZAudio checkResult:AudioUnitSetProperty(remoteIOUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, busOne, &oneFlag, sizeof(oneFlag)) operation:"couldn't kAudioOutputUnitProperty_EnabledIO with kAudioUnitScope_Input"];
        //音频流描述AudioStreamBasicDescription
        AudioStreamBasicDescription effectDataFormat;
        UInt32 propSize = sizeof(effectDataFormat);
        AURenderCallbackStruct inputProc;
        //当我们都将硬体与软体都设定完成后，接下来就要在音声音数据进来时设定一个Callback，
        //让每次音讯资料从硬体转成数位资料时都能直接呼叫Callbackle立即处理这些数位资料后再输出至输出端，
        //本例中设置为PerformThru，其定义在文章开始的地方
        inputProc.inputProc = PerformThru;
        //把self传给PerformThru，以获取控制权
        inputProc.inputProcRefCon = (__bridge void *)self;
        //  AUGraphSetNodeInputCallback 设定回调时会被调用的Function
        [EZAudio checkResult:AUGraphSetNodeInputCallback(auGraph, remoteIONode, 0, &inputProc) operation:"Error Setting io output callback"];
        
        [EZAudio checkResult:AudioUnitGetProperty(remoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &effectDataFormat, &propSize) operation:"couldn't get kAudioUnitProperty_StreamFormat with kAudioUnitScope_Output"];
        [EZAudio checkResult:AudioUnitSetProperty(remoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &effectDataFormat, propSize) operation:"couldn't set kAudioUnitProperty_StreamFormat with kAudioUnitScope_Output"];
        [EZAudio checkResult:AudioUnitSetProperty(remoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &effectDataFormat, propSize) operation:"couldn't set kAudioUnitProperty_StreamFormat with kAudioUnitScope_Intput"];
        [audioSession setPreferredIOBufferDuration:0.025 error:&error];
        [audioSession setActive:true error:&error];
        
        AVAudioSessionPortDescription *input = [[audioSession.currentRoute.inputs count] ? audioSession.currentRoute.inputs:nil objectAtIndex:0];
        
        if ([input.portType isEqualToString:AVAudioSessionPortHeadsetMic])
        {
            NSLog(@"has input");
            //  AUGraphUpdate 更新AUGraph，当有增加Node或移除时可以执行这将整个AUGraph规则更新
            AUGraphUpdate(auGraph, NULL);
             //    AUGraphStart 所有设定都无误要开始执行AUGraph功能。
            AudioOutputUnitStart(remoteIOUnit);
            
            //[EZAudio checkResult:AUGraphStart(auGraph) operation:"couldn't AUGraphStart"];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outputDeviceChanged:) name:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audiosessionInterrupt:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
        NSLog(@"audio INIT!");

    }
            return self;
}



@end

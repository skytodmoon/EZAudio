//
//  AppDelegate.m
//  PlayFile
//
//  Created by Syed Haris Ali on 12/1/13.
//  Updated by Syed Haris Ali on 1/23/16.
//  Copyright (c) 2013 Syed Haris Ali. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "AppDelegate.h"

@implementation AppDelegate

//------------------------------------------------------------------------------
#pragma mark - Dealloc
//------------------------------------------------------------------------------

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//------------------------------------------------------------------------------
#pragma mark - Customize the Audio Plot
//------------------------------------------------------------------------------

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    //
    // Customizing the audio plot's look
    //
    // Background color
    self.audioPlot.backgroundColor = [NSColor colorWithCalibratedRed: 0.816 green: 0.349 blue: 0.255 alpha: 1];
    // Waveform color
    self.audioPlot.color           = [NSColor colorWithCalibratedRed: 1.000 green: 1.000 blue: 1.000 alpha: 1];
    // Plot type
    self.audioPlot.plotType        = EZPlotTypeBuffer;
    // Fill
    self.audioPlot.shouldFill      = YES;
    // Mirror
    self.audioPlot.shouldMirror    = YES;
    
    //
    // Create EZOutput to play audio data
    //
    self.player = [EZAudioPlayer audioPlayerWithDelegate:self];
    self.player.shouldLoop = YES;
    
    //
    // Reload the menu for the output device selector popup button
    //
    [self reloadOutputDevicePopUpButtonMenu];
    
    //
    // Configure UI components
    //
    self.volumeSlider.floatValue = [self.player volume];
    self.volumeLabel.floatValue = [self.player volume];
    self.rollingHistoryLengthSlider.intValue = [self.audioPlot rollingHistoryLength];
    self.rollingHistoryLengthLabel.intValue = [self.audioPlot rollingHistoryLength];
    self.loopCheckboxButton.state = [self.player shouldLoop];
    
    //
    // Listen for state changes to the EZAudioPlayer
    //
    [self setupNotifications];
    
    //
    // Try opening the sample file
    //
    [self openFileWithFilePathURL:[NSURL fileURLWithPath:kAudioFileDefault]];
}

//------------------------------------------------------------------------------
#pragma mark - Notifications
//------------------------------------------------------------------------------

- (void)setupNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioPlayerDidChangeAudioFile:)
                                                 name:EZAudioPlayerDidChangeAudioFileNotification
                                               object:self.player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioPlayerDidChangeOutputDevice:)
                                                 name:EZAudioPlayerDidChangeOutputDeviceNotification
                                               object:self.player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioPlayerDidChangePlayState:)
                                                 name:EZAudioPlayerDidChangePlayStateNotification
                                               object:self.player];
    
    // This notification will only trigger if the player's shouldLoop property is set to NO
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioPlayerDidReachEndOfFile:)
                                                 name:EZAudioPlayerDidReachEndOfFileNotification
                                               object:self.player];
}

//------------------------------------------------------------------------------

- (void)audioPlayerDidChangeAudioFile:(NSNotification *)notification
{
    EZAudioPlayer *player = [notification object];
    NSLog(@"Player changed audio file: %@", [player audioFile]);
}

//------------------------------------------------------------------------------

- (void)audioPlayerDidChangeOutputDevice:(NSNotification *)notification
{
    EZAudioPlayer *player = [notification object];
    NSLog(@"Player changed output device: %@", [player device]);
}

//------------------------------------------------------------------------------

- (void)audioPlayerDidChangePlayState:(NSNotification *)notification
{
    EZAudioPlayer *player = [notification object];
    NSLog(@"Player change play state, isPlaying: %i", [player isPlaying]);
}

//------------------------------------------------------------------------------

- (void)audioPlayerDidReachEndOfFile:(NSNotification *)notification
{
    NSLog(@"Player did reach end of file!");
    [self.playButton setState:NSOffState];
}

//------------------------------------------------------------------------------
#pragma mark - Actions
//------------------------------------------------------------------------------

- (void)changedOutput:(NSMenuItem *)item
{
    EZAudioDevice *device = [item representedObject];
    [self.player setDevice:device];
}

//------------------------------------------------------------------------------

- (void)changePlotType:(id)sender
{
    NSInteger selectedSegment = [sender selectedSegment];
    switch(selectedSegment)
    {
        case 0:
            [self drawBufferPlot];
            break;
        case 1:
            [self drawRollingPlot];
            break;
        default:
            break;
    }
}

//------------------------------------------------------------------------------

- (void)changeShouldLoop:(id)sender
{
    NSInteger state = [(NSButton *)sender state];
    [self.player setShouldLoop:state];
}

//------------------------------------------------------------------------------

- (void)changeVolume:(id)sender
{
    float value = [(NSSlider *)sender floatValue];
    [self.player setVolume:value];
    self.volumeLabel.floatValue = value;
}

//------------------------------------------------------------------------------

- (void)changeRollingHistoryLength:(id)sender
{
    float value = [(NSSlider *)sender floatValue];
    self.audioPlot.rollingHistoryLength = (int)value;
    self.rollingHistoryLengthLabel.floatValue = value;
}

//------------------------------------------------------------------------------

- (void)openFile:(id)sender
{
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    openDlg.canChooseFiles = YES;
    openDlg.canChooseDirectories = NO;
    openDlg.delegate = self;
    if ([openDlg runModal] == NSModalResponseOK)
    {
        NSArray *selectedFiles = [openDlg URLs];
        [self openFileWithFilePathURL:selectedFiles.firstObject];
    }
}

//------------------------------------------------------------------------------

-(void)play:(id)sender
{
    if (![self.player isPlaying])
    {
        if (self.player.state == EZAudioPlayerStateEndOfFile)
        {
            [self.player seekToFrame:0];
        }
        if (self.audioPlot.plotType == EZPlotTypeBuffer
            && self.audioPlot.shouldFill == YES)
        {
            self.audioPlot.plotType = EZPlotTypeRolling;
        }
        [self.player play];
    }
    else
    {
        [self.player pause];
    }
}

//------------------------------------------------------------------------------

-(void)seekToFrame:(id)sender
{
    double value = [(NSSlider*)sender doubleValue];
    [self.player seekToFrame:(SInt64)value];
    self.positionLabel.stringValue = self.player.formattedCurrentTime;
}

//------------------------------------------------------------------------------
#pragma mark - Action Extensions
//------------------------------------------------------------------------------

//
// Give the visualization of the current buffer (this is almost exactly
// the openFrameworks audio input example)
//
-(void)drawBufferPlot
{
    // Change the plot type to the buffer plot
    self.audioPlot.plotType = EZPlotTypeBuffer;
    // Don't fill
    self.audioPlot.shouldFill = NO;
    // Don't mirror over the x-axis
    self.audioPlot.shouldMirror = NO;
}

//------------------------------------------------------------------------------

//
// Give the classic mirrored, rolling waveform look
//
-(void)drawRollingPlot
{
    // Change the plot type to the rolling plot
    self.audioPlot.plotType = EZPlotTypeRolling;
    // Fill the waveform
    self.audioPlot.shouldFill = YES;
    // Mirror over the x-axis
    self.audioPlot.shouldMirror = YES;
}

//------------------------------------------------------------------------------

-(void)openFileWithFilePathURL:(NSURL*)filePathURL
{
    //
    // Stop playback
    //
    [self.player pause];
    
    //
    // Clear the audio plot
    //
    [self.audioPlot clear];
    
    //
    // Change back to a buffer plot, but mirror and fill the waveform
    //
    self.audioPlot.plotType     = EZPlotTypeBuffer;
    self.audioPlot.shouldFill   = YES;
    self.audioPlot.shouldMirror = YES;
    
    //
    // Load the audio file and customize the UI
    //
    self.player.audioFile = [EZAudioFile audioFileWithURL:filePathURL];
    self.filePathLabel.stringValue = filePathURL.lastPathComponent;
    self.positionSlider.minValue = 0.0f;
    self.positionSlider.maxValue = (double)self.player.audioFile.totalFrames;
    self.playButton.state = NSOffState;
    self.plotSegmentControl.selectedSegment = self.audioPlot.plotType;
    
    //
    // Plot the whole waveform
    //
    __weak typeof (self) weakSelf = self;
    [self.player.audioFile getWaveformDataWithNumberOfPoints:1024
                                                  completion:^(float **waveformData,
                                                               int length)
     {
         [weakSelf.audioPlot updateBuffer:waveformData[0]
                           withBufferSize:length];
     }];
}

//------------------------------------------------------------------------------

- (void)reloadOutputDevicePopUpButtonMenu
{
    NSArray *outputDevices = [EZAudioDevice outputDevices];
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *defaultOutputDeviceItem;
    for (EZAudioDevice *device in outputDevices)
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:device.name
                                                      action:@selector(changedOutput:)
                                               keyEquivalent:@""];
        item.representedObject = device;
        item.target = self;
        [menu addItem:item];
        
        // If this device is the same one the microphone is using then
        // we will use this menu item as the currently selected item
        // in the microphone input popup button's list of items. For instance,
        // if you are connected to an external display by default the external
        // display's microphone might be used instead of the mac's built in
        // mic.
        if ([device isEqual:[self.player device]])
        {
            defaultOutputDeviceItem = item;
        }
    }
    self.outputDevicePopUpButton.menu = menu;
    
    //
    // Set the selected device to the current selection on the
    // microphone input popup button
    //
    [self.outputDevicePopUpButton selectItem:defaultOutputDeviceItem];
}

//------------------------------------------------------------------------------
#pragma mark - EZAudioPlayerDelegate
//------------------------------------------------------------------------------

- (void)  audioPlayer:(EZAudioPlayer *)audioPlayer
          playedAudio:(float **)buffer
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels
          inAudioFile:(EZAudioFile *)audioFile
{
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.audioPlot updateBuffer:buffer[0]
                          withBufferSize:bufferSize];
    });
}

//------------------------------------------------------------------------------

- (void)audioPlayer:(EZAudioPlayer *)audioPlayer
    updatedPosition:(SInt64)framePosition
        inAudioFile:(EZAudioFile *)audioFile
{
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!weakSelf.positionSlider.highlighted)
        {
            weakSelf.positionSlider.floatValue = (float)framePosition;
            weakSelf.positionLabel.stringValue = audioPlayer.formattedCurrentTime;
        }
    });
}

//------------------------------------------------------------------------------
#pragma mark - NSOpenSavePanelDelegate
//------------------------------------------------------------------------------

// Here's an example how to filter the open panel to only show the supported 
// file types by the EZAudioFile (which are just the audio file types supported
// by Core Audio).
- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename
{
    NSString *ext = [filename pathExtension];
    NSArray *fileTypes = [EZAudioFile supportedAudioFileTypes];
    BOOL isDirectory = [ext isEqualToString:@""];
    return [fileTypes containsObject:ext] || isDirectory;
}

//------------------------------------------------------------------------------

@end

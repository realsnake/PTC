//
//  MiaoHongViewController.m
//  PTC
//
//  Created by snake on 12-1-31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

//  Description:
//  1. It is like brush painter.
//  2. Set GLKViewController's render loop to pause in viewWillAppear, to use the needDisplay to paint on-demand.
//  3. As a result, GLKView's delegate "update" and GLKViewController's delegate "glkView:drawInRect" no longer be called automatically.

//  TODO:
//  1. There is dead space if drawing fast.
//  2. Tap works strangely.

#import "MiaoHongViewController.h"

#define kBrushScale			2
#define kBrushPixelStep     3

@interface MiaoHongViewController()
{
    GLfloat *_vertexBuffer;
    CGPoint _location;
    CGPoint _previousLocation;
    NSUInteger _vertexCount;
    BOOL    _firstTouch;
}

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) GLKBaseEffect *effect;
@end

@implementation MiaoHongViewController

@synthesize context = _context;
@synthesize effect = _effect;


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupGL
{
    GLKTextureInfo *info;
    CGImageRef brushImage;
    // Create a texture from an image
    // First create a UIImage object from the data in a image file, and then extract the Core Graphics image
    brushImage = [UIImage imageNamed:@"Particle.png"].CGImage;
        
    // Get the width and height of the image
    //width = CGImageGetWidth(brushImage);
    //height = CGImageGetHeight(brushImage);
    
    // Texture dimensions must be a power of 2. If you write an application that allows users to supply an image,
    // you'll want to add code that checks the dimensions and takes appropriate action if they are not a power of 2.
    if (brushImage) {
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithBool:YES],
                                  GLKTextureLoaderOriginBottomLeft,
                                  nil];
        info = [GLKTextureLoader textureWithCGImage:brushImage options:options error:NULL];
        if (!info) {
            NSLog(@"Failed to load file to create texture info!");
        }
    }

    
    // set texture info to base effect
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.texture2d0.name = info.name;
    self.effect.texture2d0.enabled = true;

    glDisable(GL_DITHER);
    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_VERTEX_ARRAY);
    
    glEnable(GL_BLEND);
    // Set a blending function appropriate for premultiplied alpha pixel data
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    glEnable(GL_POINT_SPRITE_OES);
    glTexEnvf(GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE);
    glPointSize(CGImageGetWidth(brushImage)/ kBrushScale);
    
    glColor4f(1.0, 0.0, 0.0, 1.0);

}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    if (!self.context) {
        NSLog(@"Failed to create OpenGL ES context!");
    }
    
    GLKView * view = (GLKView *)self.view;
    view.context = self.context;
    
    // enable normal on demand drawing
    view.enableSetNeedsDisplay = YES;
        
    [EAGLContext setCurrentContext:self.context];
    
    [self setupGL];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Pause the rendering loop to draw on demand.
    self.paused = YES;
    self.resumeOnDidBecomeActive = NO;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    


    [EAGLContext setCurrentContext:self.context];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
    self.effect = nil;
}

#pragma  mark - GLKView and GLKViewController delegate methods
- (void)update
{
    NSUInteger vertexMax = 64, count = 0, i = 0;
    CGPoint start, end;

    // Convert to GLKView's coordinate system (-1,1)
    start.x = (_previousLocation.x - self.view.bounds.size.width / 2) * self.view.contentScaleFactor / (self.view.bounds.size.width / 2);
    start.y = (_previousLocation.y - self.view.bounds.size.height / 2) * self.view.contentScaleFactor / (self.view.bounds.size.height / 2);
    end.x = (_location.x - self.view.bounds.size.width / 2) * self.view.contentScaleFactor / (self.view.bounds.size.width / 2);
    end.y = (_location.y - self.view.bounds.size.height / 2) * self.view.contentScaleFactor / (self.view.bounds.size.height / 2);
    
    if (NULL == _vertexBuffer) {
        _vertexBuffer = malloc(vertexMax * 2 * sizeof(CGFloat));
    }
    count = MAX(ceilf(sqrtf(powf(end.x - start.x, 2.0) + powf(end.y - start.y, 2.0)) / kBrushPixelStep), 1);
    for (i = 0; i < count; i++) {
        if (_vertexCount == vertexMax) {
            vertexMax *= 2;
            _vertexBuffer = realloc(_vertexBuffer, vertexMax * 2 * sizeof(CGFloat));
        }
        _vertexBuffer[2 * _vertexCount + 0] = start.x + (end.x - start.x) * (CGFloat)i / (CGFloat)count;
        _vertexBuffer[2 * _vertexCount + 1] = start.y + (end.y - start.y) * (CGFloat)i / (CGFloat)count;
        _vertexCount++;
    }
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glVertexPointer(2, GL_FLOAT, 0, _vertexBuffer);
    glDrawArrays(GL_POINTS, 0, _vertexCount);
    
}

#pragma mark - handle touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch * touch in touches) {
        _firstTouch = YES;
       	// Convert touch point from UIView referential to OpenGL one (upside-down flip) 
        _location = [touch locationInView:self.view];
        _location.y = self.view.bounds.size.height - _location.y;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{    
    for (UITouch * touch in touches) {
        if (_firstTouch) {
            _firstTouch = NO;
            _previousLocation = [touch locationInView:self.view];
            _previousLocation.y = self.view.bounds.size.height - _previousLocation.y;
        } else{
            _location = [touch locationInView:self.view];
            _location.y = self.view.bounds.size.height - _location.y;
            _previousLocation = [touch locationInView:self.view];
            _previousLocation.y = self.view.bounds.size.height - _previousLocation.y;
        }
    }
    
    [self update];
    //This will call glkView:drawInRect
    [self.view setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch * touch in touches) {
        if (_firstTouch) {
            _firstTouch = NO;
            _previousLocation = [touch locationInView:self.view];
            _previousLocation.y = self.view.bounds.size.height - _previousLocation.y;
        }
    }
    [self update];
    [self.view setNeedsDisplay];
}
#pragma mark - rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

//
//  LlkViewController.m
//  PTC
//
//  Created by snake on 12-1-10.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "LlkViewController.h"
#import "Pairs.h"


#define DEFAULT_DURATION 1.0
@interface LlkViewController()

@property (nonatomic, strong) UIManagedDocument *LlkDatabase;
@property (nonatomic, strong) NSArray *pairsArray;
@property (nonatomic, strong) UIButton *pressedButton;

@end


@implementation LlkViewController
@synthesize button1 = _button1;
@synthesize button2 = _button2;
@synthesize button3 = _button3;
@synthesize button4 = _button4;
@synthesize button5 = _button5;
@synthesize button6 = _button6;
@synthesize pressedButton = _pressedButton;

@synthesize LlkDatabase = _LlkDatabase;
@synthesize pairsArray = _pairsArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - FetchRequest
- (void)setupFetchRequest
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Pairs"];
    
    // Create sort description array
    NSSortDescriptor *description1 = [NSSortDescriptor sortDescriptorWithKey:@"word" ascending:YES];
    NSSortDescriptor *description2 = [NSSortDescriptor sortDescriptorWithKey:@"antonym" ascending:YES];
    NSArray *sortDescriptions = [NSArray arrayWithObjects:description1, description2, nil];
    fetchRequest.sortDescriptors = sortDescriptions;    
    
    NSError *error;
    self.pairsArray = [self.LlkDatabase.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"ExcuteFetchRequest error! Error is %@", error);
    }
}

- (void)setupButton
{
    // TODO: random value
    NSArray *buttonsArray = [NSArray arrayWithObjects:self.button1, self.button2, self.button3,self.button4, self.button5, self.button6, nil];
    NSMutableArray *buttonsMutableArray = [NSMutableArray arrayWithCapacity:[buttonsArray count]];
    [buttonsMutableArray addObjectsFromArray:buttonsArray];
    
    
    NSInteger tagForPairs = 1;  // To identify pairs.
    
    for (Pairs *pairs in self.pairsArray) {
        // Setup buttons contain word.
        NSInteger indexOfWord = arc4random() % [buttonsMutableArray count];
        UIButton *buttonForWord = [buttonsMutableArray objectAtIndex:indexOfWord];
        
        [buttonForWord setTitle:pairs.word forState:UIControlStateNormal];
        [buttonForWord setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        buttonForWord.tag =tagForPairs;
        
        if (buttonsMutableArray) {
            [buttonsMutableArray removeObjectAtIndex:indexOfWord];
        }
        
        // Setup buttons contain antonym.
        NSInteger indexOfAntonym = arc4random() % [buttonsMutableArray count];
        UIButton *buttonForAntonym = [buttonsMutableArray objectAtIndex:indexOfAntonym];
        
        buttonForAntonym.tag = tagForPairs;
        [buttonForAntonym setTitle:pairs.antonym forState:UIControlStateNormal];
        [buttonForAntonym setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        if (buttonsMutableArray) {
            [buttonsMutableArray removeObjectAtIndex:indexOfAntonym];
        }
        
        tagForPairs++;
    }
}

- (void)useDocument
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.LlkDatabase.fileURL path]]) {
        // create a new file managed by UIManagedDocument.
        [self.LlkDatabase saveToURL:self.LlkDatabase.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if (success) {
                [self setupFetchRequest];
                [self setupButton];
            }
            if (!success) {
                NSLog(@"Create database fail!");
            }
        }];
    }
    else if(UIDocumentStateClosed == self.LlkDatabase.documentState){
        // opent it
        [self.LlkDatabase openWithCompletionHandler:^(BOOL success){
            if (success) {
                [self setupFetchRequest];
                [self setupButton];
            } 
        }];
    }
    else if(UIDocumentStateNormal == self.LlkDatabase.documentState){
        // already be opened, just use it
        [self setupFetchRequest];
        [self setupButton];
    }
}

- (void)setLlkDatabase:(UIManagedDocument *)LlkDatabase
{
    if (_LlkDatabase != LlkDatabase) {
        _LlkDatabase = LlkDatabase;
        [self useDocument];
    }
}


#pragma button pressed

- (void)removeButtonPairs:(UIButton *)sender
{
    for (UIView * view in self.view.subviews) {
        if (view.tag == self.pressedButton.tag) {
            [sender setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
            [self.pressedButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
            CGAffineTransform transform = view.transform;
            if (CGAffineTransformIsIdentity(transform)) {
                UIViewAnimationOptions options = UIViewAnimationOptionCurveLinear;
                [UIView animateWithDuration:DEFAULT_DURATION/3 delay:0 options:options animations:^{
                    view.transform = CGAffineTransformRotate(CGAffineTransformScale(transform, 0.7, 0.7), 2*M_PI/3);
                }completion:^(BOOL finished) {
                    if (finished) {
                        [UIView animateWithDuration:DEFAULT_DURATION/3 delay:0 options:options animations:^{
                            view.transform = CGAffineTransformRotate(CGAffineTransformScale(transform, 0.4, 0.4), -2*M_PI/3);
                        } completion:^(BOOL finished) {
                            if (finished) {
                                [UIView animateWithDuration:DEFAULT_DURATION/3 delay:0 options:options animations:^{
                                    view.transform = CGAffineTransformScale(transform, 0.1, 0.1);
                                } completion:^(BOOL finished) {
                                    if (finished) {
                                        [view removeFromSuperview];
                                    }
                                }];
                            }
                        }];
                    }
                }];
            } 
        }
    }
}

- (IBAction)buttonPressed:(UIButton *)sender {
    [sender setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    if (sender != self.pressedButton) {
        if (sender.tag == self.pressedButton.tag) {
            [self removeButtonPairs:sender];
        }
        else{
            // restore self.pressedbutton
            [self.pressedButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }
    }    
    
    self.pressedButton = sender;
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.LlkDatabase) {
        NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *databaseURL = [documentsURL URLByAppendingPathComponent:@"Llk Database"];
        // Setter will create a database in "<Documents Directory>/Llk Database"
        self.LlkDatabase = [[UIManagedDocument alloc] initWithFileURL:databaseURL];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"a"]]];
}


- (void)viewDidUnload
{
    [self setButton1:nil];
    [self setButton2:nil];
    [self setButton3:nil];
    [self setButton4:nil];
    [self setButton5:nil];
    [self setButton6:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

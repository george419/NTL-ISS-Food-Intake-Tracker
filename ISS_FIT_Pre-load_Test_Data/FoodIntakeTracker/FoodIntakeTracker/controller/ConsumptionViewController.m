// Copyright (c) 2013 TopCoder. All rights reserved.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//
//  ConsumptionViewController.m
//  FoodIntakeTracker
//
//  Created by lofzcx 06/12/2013
//

#import "ConsumptionViewController.h"
#import "CustomTabBarViewController.h"
#import "SummaryFoodTableCell.h"
#import "PopoverBackgroundView.h"
#import "AddFoodViewController.h"
#import "CalendarViewController.h"
#import "FoodDetailViewController.h"
#import "VoiceSearchViewController.h"
#import "SelectConsumptionViewController.h"
#import "Helper.h"
#import "AppDelegate.h"
#import "SpeechRecognitionServiceImpl.h"
#import "FoodConsumptionRecordServiceImpl.h"
#import "FoodProductServiceImpl.h"
#import "Settings.h"
#import "BNPieChart.h"
#import "BNColor.h"

#define MAX_CALORIES 2800
#define MAX_SODIUM 160
#define MAX_FLUID 3

#define PROTEIN_CALORIES_FACTOR 4.0
#define CARB_CALORIES_FACTOR 4.0
#define FAT_CALORIES_FACTOR 9.0

#define PROGRESSBAR_WIDTH 168

@implementation DateListView

/**
 * handles action for date item button click.
 * @param sender the date item button.
 */
-(void)buttonClick:(id)sender{
    UIButton *btn = (UIButton *)sender;
    if(btn.tag == activeTag){
        return;
    }
    NSDate *date = [NSDate dateWithTimeInterval:(DAY_SECONDS * (btn.tag - activeTag))
                                      sinceDate:self.currentDate];
    self.currentDate = date;
    if(self.delegate && [self.delegate respondsToSelector:@selector(clickDate:)]){
        [self.delegate clickDate:date];
    }
    [self setNeedsDisplay];
}

/**
 * overwrite this method to generate date item and bind actions.
 * @param rect the rect needs to be re-draw.
 */
-(void)drawRect:(CGRect)rect{
    int daySeconds = 60 * 60 * 24;
    if(self.currentDate == nil){
        self.currentDate = [NSDate date];
    }
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    gregorian.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSDateComponents *info = [gregorian components:(NSYearCalendarUnit |
                                                    NSMonthCalendarUnit |
                                                    NSDayCalendarUnit |
                                                    NSWeekdayCalendarUnit)
                                          fromDate:self.currentDate];
    
    NSDate *startDate = [NSDate dateWithTimeInterval:(-1 * daySeconds * ((info.weekday + 7 - 1) % 7))
                                           sinceDate:self.currentDate];
    for(int i = 0; i < 7; i++){
        UIButton *btn = (UIButton *)[self viewWithTag:(101 + i)];
        [btn addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        UILabel *lblDay = (UILabel *)[self viewWithTag:(201 + i)];
        UILabel *lblDayName = (UILabel *)[self viewWithTag:(301 + i)];
        NSDate *date = [NSDate dateWithTimeInterval:(daySeconds * i) sinceDate:startDate];
        NSDateComponents *tmp = [gregorian components:(NSYearCalendarUnit |
                                                       NSMonthCalendarUnit |
                                                       NSDayCalendarUnit |
                                                       NSWeekdayCalendarUnit)
                                             fromDate:date];
        
        NSUInteger dayOfYear = [gregorian ordinalityOfUnit:NSDayCalendarUnit
                                                    inUnit:NSYearCalendarUnit
                                                   forDate:date];
        
        lblDay.text = [NSString stringWithFormat:@"%.2d", dayOfYear];
        if(tmp.weekday == info.weekday){
            activeTag = btn.tag;
            [btn setSelected:YES];
            lblDay.textColor = lblDayName.textColor = [UIColor colorWithRed:0.2 green:0.43 blue:0.62 alpha:1];
        }
        else{
            [btn setSelected:NO];
            lblDay.textColor = lblDayName.textColor = [UIColor colorWithRed:0.32 green:0.32 blue:0.32 alpha:1];
        }
    }
    
}

@end

@implementation CustomProgressView

@synthesize currentProgress = _currentProgress;

/**
 * setting the current progress value and reflesh the view.
 * @param currentProgress should be 0 to 1. The current progress.
 */
- (void)setCurrentProgress:(float)currentProgress{
    if(currentProgress > 1){
        _currentProgress = 1;
    }
    else if(currentProgress < 0){
        _currentProgress = 0;
    }
    else{
        _currentProgress = currentProgress;
    }
    [self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
}

/**
 * overwrite this method the layout the progress view.
 * @param rect the frame size.
 */
- (void)drawRect:(CGRect)rect{
    float w = self.progressView.frame.size.width;
    float h = self.progressView.frame.size.height;
    float x = self.progressView.frame.origin.x;
    float y = self.progressView.frame.origin.y;
    
    CGSize size = [self.lblCurrent.text sizeWithFont:self.lblCurrent.font
                                   constrainedToSize:CGSizeMake(MAXFLOAT, self.frame.size.height)];
    
    self.lblCurrent.frame = CGRectMake(self.lblCurrent.frame.origin.x,
                                       self.lblCurrent.frame.origin.y,
                                       size.width + 5,
                                       self.lblCurrent.frame.size.height);
    
    self.lblTotal.frame = CGRectMake(self.lblCurrent.frame.origin.x + size.width + 5,
                                     self.lblTotal.frame.origin.y,
                                     self.lblTotal.frame.size.width,
                                     self.lblTotal.frame.size.height);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if(_currentProgress == 1){
        CGContextSetFillColorWithColor(context, self.fullColor.CGColor);
        CGContextFillRect(context, CGRectMake(x + 1, y + 1, w - 2, h - 2));
        CGContextStrokePath(context);
    }
    else{
        CGContextDrawImage(context, CGRectMake(x, y, w, h), self.backgoundImage.CGImage);
        
        
        UIGraphicsBeginImageContext(CGSizeMake(w - 2, h - 2));
        [self.progressImage drawInRect:CGRectMake(0, 0, w - 2, h - 2)];
        
        CGContextClearRect (UIGraphicsGetCurrentContext(), CGRectMake((w - 2) * _currentProgress, 0,
                                                                      (w - 2) * (1 - _currentProgress), h - 2));
        
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        CGContextDrawImage(context, CGRectMake(x + 1, y + 1, (w - 2), h - 2), img.CGImage);
    }
    
}

@end

@interface ConsumptionViewController (){
    /* the food items */
    NSMutableArray *foodItems;
    /* the selected food items */
    NSMutableArray *selectedItems;
    /* the copied food items */
    NSMutableArray *copyItems;
    /* the content offset - F2Finish change */
    NSMutableDictionary *contentOffset;
    
    /* the add food view controller */
    AddFoodViewController *_addFood;
    /* the cover when some pop up is shown */
    UIView *clearCover;
    /* the calendar view controller */
    CalendarViewController *caledar;
    /* the detail view controller */
    FoodDetailViewController *foodDetail;
    /* the voice search controller */
    VoiceSearchViewController *voiceSearch;
    /* the select consumption view controller */
    SelectConsumptionViewController *selectConsumption;
    /* whether the open ear is listening */
    bool listening;
}

@end

@implementation ConsumptionViewController

/**
 * called when view will appear.
 * just load foods here.
 * @param animated If YES, the view is being added to the window using an animation.
 */
- (void)viewWillAppear:(BOOL)animated{
    if(foodItems.count == 0){
        NSDate *selectDate = self.dateListView.currentDate;
        if (!selectDate) {
            selectDate = [NSDate date];
        }
        [self loadFoodItemsForDate:selectDate];
    }
    
    self.customTabBarController.tabView.hidden = NO;
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    NSMutableString *str = [[NSMutableString alloc] init];
    [str appendString:@"summary    for"];
    if(appDelegate.loggedInUser.fullName.length > 0){
        NSArray *names = [appDelegate.loggedInUser.fullName componentsSeparatedByString:@" "];
        // F2Finish change - Display name
        if (names.count == 1) {
            [str appendFormat:@"    %@", names[0]];
        } else if (names.count == 2) {
            [str appendFormat:@"    %@   %@", names[0], names[1]];
        }
    }
    CGSize size1 = [str sizeWithFont:self.lblHeaderTitle.font constrainedToSize:self.lblHeaderTitle.frame.size];
    [str appendString:@"           daily    intake    report"];
    self.lblHeaderTitle.text = str;
    self.imgHeaderLine.frame = CGRectMake(self.lblHeaderTitle.frame.origin.x + size1.width + 10, 10, 2, 41);
    
    [super viewWillAppear:animated];
    
}

/**
 * initilize some default values when view loaded.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.lblHeaderTitle.font = [UIFont fontWithName:@"Bebas" size:24];
    
    selectedItems = [[NSMutableArray alloc] init];
    copyItems = [[NSMutableArray alloc] init];
    
    // F2Finish change
    contentOffset = [[NSMutableDictionary alloc] init];
    
    self.lblFooterTitle.font = [UIFont fontWithName:@"Bebas" size:20];
    self.lblMonth.font = [UIFont fontWithName:@"Bebas" size:16];
    
    self.caloriesProgess.backgoundImage = [UIImage imageNamed:@"bg-progress.png"];
    self.sodiumProgress.backgoundImage = [UIImage imageNamed:@"bg-progress.png"];
    self.fluidProgress.backgoundImage = [UIImage imageNamed:@"bg-progress.png"];
    self.proteinProgess.backgoundImage = [UIImage imageNamed:@"bg-progress.png"];
    self.carbProgress.backgoundImage = [UIImage imageNamed:@"bg-progress.png"];
    self.fatProgress.backgoundImage = [UIImage imageNamed:@"bg-progress.png"];
    
    self.caloriesProgess.fullColor = [UIColor greenColor];
    self.sodiumProgress.fullColor = [UIColor redColor];
    self.fluidProgress.fullColor = [UIColor greenColor];
    self.proteinProgess.fullColor = [UIColor redColor];
    self.carbProgress.fullColor = [UIColor redColor];
    self.fatProgress.fullColor = [UIColor redColor];
    
    self.caloriesProgess.progressImage = [UIImage imageNamed:@"bg-progress-red.png"];
    self.sodiumProgress.progressImage = [UIImage imageNamed:@"bg-progress-green.png"];
    self.fluidProgress.progressImage = [UIImage imageNamed:@"bg-progress-red.png"];
    self.proteinProgess.progressImage = [UIImage imageNamed:@"bg-progress-green.png"];
    self.carbProgress.progressImage = [UIImage imageNamed:@"bg-progress-green.png"];
    self.fatProgress.progressImage = [UIImage imageNamed:@"bg-progress-green.png"];

    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    if (appDelegate.loggedInUser) {
        self.caloriesProgess.lblTotal.text =
        [NSString stringWithFormat:@"/ %@ kcal", appDelegate.loggedInUser.dailyTargetEnergy];
        self.sodiumProgress.lblTotal.text =
        [NSString stringWithFormat:@"/ %@ mg", appDelegate.loggedInUser.dailyTargetSodium];
        self.fluidProgress.lblTotal.text =
        [NSString stringWithFormat:@"/ %@ liters", appDelegate.loggedInUser.dailyTargetFluid];
    }
    else {
        self.caloriesProgess.lblTotal.text = [NSString stringWithFormat:@"/ %d kcal", MAX_CALORIES];
        self.sodiumProgress.lblTotal.text = [NSString stringWithFormat:@"/ %d mg", MAX_SODIUM];
        self.fluidProgress.lblTotal.text = [NSString stringWithFormat:@"/ %d liters", MAX_FLUID];
    }
    
    listening = NO;
    self.dateListView.currentDate = [NSDate date];
    self.dateListView.delegate = self;
    
    self.bottomScrollView.contentSize = CGSizeMake(1536, 125);
    
    self.lblDeletePopupTitle.font = [UIFont fontWithName:@"Bebas" size:20];
    self.lblCopyPopupTitle.font = [UIFont fontWithName:@"Bebas" size:20];
    self.lblPastePopupTitle.font = [UIFont fontWithName:@"Bebas" size:20];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(consumptionUpdated)
                                                 name:ConsumptionUpdatedEvent object:nil];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    gregorian.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSDateComponents *info = [gregorian components:(NSYearCalendarUnit |
                                                    NSMonthCalendarUnit |
                                                    NSDayCalendarUnit |
                                                    NSWeekdayCalendarUnit)
                                          fromDate:[NSDate date]];
    
    self.lblMonth.text = [Helper monthName:info.month];
    self.lblYear.text = [NSString stringWithFormat:@"GMT %d", info.year];

    // Initialize OpenEars
    self.pocketsphinxController = [[PocketsphinxController alloc] init];
    self.pocketsphinxController.returnNbest = FALSE;
    self.openEarsEventsObserver = [[OpenEarsEventsObserver alloc] init];
    [self.openEarsEventsObserver setDelegate:self];
    // Retrieve language model paths
    SpeechRecognitionServiceImpl *srService = appDelegate.speechRecognitionService;

    [self redrawPieChartWithProtein:0.333 carb:0.333 fat:0.334];
    
    NSError *error;
    self.lmPaths = [srService getGeneralLanguageModelPaths:&error];
    if ([Helper displayError:error]) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:AutoLogoutRenewEvent object:nil];
}

/**
 * release some value by setting nil.
 */
- (void)viewDidUnload {
    [self setBtnDelete:nil];
    [self setBtnCopy:nil];
    [self setBtnPaste:nil];
    [self setBtnSelect:nil];
    [self setBtnVoice:nil];
    [self setBtnPhoto:nil];
    [self setBtnAddFood:nil];
    [self setCaloriesProgess:nil];
    [self setSodiumProgress:nil];
    [self setFluidProgress:nil];
    [self setProteinProgess:nil];
    [self setCarbProgress:nil];
    [self setFatProgress:nil];
    [self setLblFooterTitle:nil];
    [self setLblFooterNote:nil];
    [self setBtnMonth:nil];
    [super viewDidUnload];
}

/**
 * update progress in the bottom info bar.
 */
- (void)updateProgress{
    int caloriesTotal = 0;
    int sodiumTotal = 0;
    float fluidTotal = 0;
    int proteinTotal = 0;
    int carbTotal = 0;
    int fatTotal = 0;
    for (FoodConsumptionRecord *item in self.foodConsumptionRecords) {
        caloriesTotal += [item.foodProduct.energy intValue] * [item.quantity floatValue];
        sodiumTotal += [item.foodProduct.sodium intValue] * [item.quantity floatValue];
        fluidTotal += [item.foodProduct.fluid floatValue] * [item.quantity floatValue];
        proteinTotal += [item.foodProduct.protein floatValue] * [item.quantity floatValue];
        carbTotal += [item.foodProduct.carb floatValue] * [item.quantity floatValue];
        fatTotal += [item.foodProduct.fat floatValue] * [item.quantity floatValue];
    }
    
    self.caloriesProgess.lblCurrent.text = [NSString stringWithFormat:@"%d", caloriesTotal];
    self.sodiumProgress.lblCurrent.text = [NSString stringWithFormat:@"%d", sodiumTotal];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setPositiveFormat:@"#.##"];
    self.fluidProgress.lblCurrent.text = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:fluidTotal]];
    
    self.proteinProgess.lblCurrent.text = [NSString stringWithFormat:@"%d grams eaten", proteinTotal];
    self.carbProgress.lblCurrent.text = [NSString stringWithFormat:@"%d grams eaten", carbTotal];
    self.fatProgress.lblCurrent.text = [NSString stringWithFormat:@"%d grams eaten", fatTotal];

    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    
    float caloriesProgessPercentage = caloriesTotal * 1.0f / [appDelegate.loggedInUser.dailyTargetEnergy intValue];
    float sodiumProgressPercentage = sodiumTotal * 1.0f / [appDelegate.loggedInUser.dailyTargetSodium intValue];
    float fluidProgressPercentage = fluidTotal * 1.0f / [appDelegate.loggedInUser.dailyTargetFluid intValue];
    
    self.caloriesProgess.currentProgress = caloriesProgessPercentage;
    self.sodiumProgress.currentProgress = sodiumProgressPercentage;
    self.fluidProgress.currentProgress = fluidProgressPercentage;
    
    int maxConsumption = proteinTotal;
    if (carbTotal > maxConsumption) {
        maxConsumption = carbTotal;
    }
    if (fatTotal > maxConsumption) {
        maxConsumption = fatTotal;
    }
    
    self.proteinProgess.currentProgress = 1.0;
    self.carbProgress.currentProgress =  1.0;
    self.fatProgress.currentProgress =  1.0;

    CGRect proteinProgressFrame = self.proteinProgess.progressView.frame;
    CGRect carbProgressFrame = self.carbProgress.progressView.frame;
    CGRect fatProgressFrame = self.fatProgress.progressView.frame;
    
    if (maxConsumption > 0) {
        proteinProgressFrame.size.width = (int)(proteinTotal * 1.0f / maxConsumption * PROGRESSBAR_WIDTH);
        carbProgressFrame.size.width = (int)(carbTotal * 1.0f / maxConsumption * PROGRESSBAR_WIDTH);
        fatProgressFrame.size.width = (int)(fatTotal * 1.0f / maxConsumption * PROGRESSBAR_WIDTH);
    }
    else {
        proteinProgressFrame.size.width = 0;
        carbProgressFrame.size.width = 0;
        fatProgressFrame.size.width = 0;
    }
    
    self.proteinProgess.progressView.frame = proteinProgressFrame;
    self.carbProgress.progressView.frame = carbProgressFrame;
    self.fatProgress.progressView.frame = fatProgressFrame;
    
    float proteinCalories = proteinTotal * PROTEIN_CALORIES_FACTOR;
    float carbCalories = carbTotal * CARB_CALORIES_FACTOR;
    float fatCalories = fatTotal * FAT_CALORIES_FACTOR;
    float calories = proteinCalories + carbCalories + fatCalories;
    if (calories > 0) {
        proteinCalories = proteinCalories / calories;
        carbCalories = carbCalories / calories;
        fatCalories = fatCalories / calories;
        [self redrawPieChartWithProtein:proteinCalories carb:carbCalories fat:fatCalories];
    }
    else {
        [self redrawPieChartWithProtein:0.333 carb:0.333 fat:0.334];
    }
    
    self.proteinPercentageLabel.text = [NSString stringWithFormat:@"%.0f%% of Calories",
                                            floor(proteinCalories * 100)];
    self.carbPercentageLabel.text = [NSString stringWithFormat:@"%.0f%% of Calories",
                                           floor(carbCalories * 100)];
    self.fatPercentageLabel.text = [NSString stringWithFormat:@"%.0f%% of Calories",
                                          floor(fatCalories * 100)];

    self.caloriesProgess.lblPercent.text = [NSString stringWithFormat:@"%.0f%%",
                                            floor(caloriesProgessPercentage  * 100)];
    self.sodiumProgress.lblPercent.text = [NSString stringWithFormat:@"%.0f%%",
                                           floor(sodiumProgressPercentage * 100)];
    self.fluidProgress.lblPercent.text = [NSString stringWithFormat:@"%.0f%%",
                                          floor(fluidProgressPercentage * 100)];
}

/**
 * load food items by specify date.
 * @param date The date of foods want to load.
 */
- (void)loadFoodItemsForDate:(NSDate *)date{
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    if (!appDelegate.loggedInUser) {
        return;
    }
    FoodConsumptionRecordServiceImpl *recordService = appDelegate.foodConsumptionRecordService;

    NSError *error;
    NSArray *records = [recordService getFoodConsumptionRecords:appDelegate.loggedInUser date:date error:&error];
    if ([Helper displayError:error]) return;
    self.foodConsumptionRecords = [NSMutableArray arrayWithArray:records];
    
    [self.foodTableView reloadData];
}

/**
 * action for check box button click. Add item to array or remove it. Update button status.
 * @param sender the check box button.
 */
- (void)foodSelect:(id)sender{
    UIButton *btn = (UIButton *)sender;
    int row = btn.tag;
    FoodConsumptionRecord *item = [self.foodConsumptionRecords objectAtIndex:row];
    if([selectedItems containsObject:item]){
        [selectedItems removeObject:item];
        [btn setSelected:NO];
    }
    else{
        [selectedItems addObject:item];
        [btn setSelected:YES];
    }
    if(selectedItems.count == 0){
        [self.btnCopy setEnabled:NO];
        [self.btnDelete setEnabled:NO];
    }
    else{
        [self.btnCopy setEnabled:YES];
        [self.btnDelete setEnabled:YES];
    }
}

/**
 * Called when the consumption is updated.
 */
- (void) consumptionUpdated {
    [self updateProgress];
}

/*!
 Redraw the pie chart
 */
- (void) redrawPieChartWithProtein:(float)proteinRatio carb:(float)carbRatio fat:(float)fatRatio {
    if (self.pieChart) {
        [self.pieChart removeFromSuperview];
        self.pieChart = nil;
    }
    self.pieChart = [[BNPieChart alloc] initWithFrame:CGRectMake(470, 0, 130, 130)];
    [self.pieChart addSlicePortion:proteinRatio withName:@"Protein"];
    [self.pieChart addSlicePortion:carbRatio withName:@"Carb"];
    [self.pieChart addSlicePortion:fatRatio withName:@"Fat"];
    NSArray *colors = @[[BNColor colorWithRed:1.0 green:0.0 blue:0.0],
                        [BNColor colorWithRed:0.66 green:0.36 blue:0.0],
                        [BNColor colorWithRed:0.882 green:0.757 blue:0.384]];
    self.pieChart.colors = colors;
    [self.pieChart showLabels:NO];
    [self.progressView2 addSubview:self.pieChart];
}

#pragma mark - add food

/**
 * handle action for save button in add food view. Save food to list and reload table.
 */
- (void)addFoodDoneButtonClick{
    // Validate the quantity
    if (![Helper checkIsNumber:_addFood.txtQuantity.text]) {
        [Helper showAlert:@"Error" message:@"The quantity has to be a number."];
        return;
    }
    if ([_addFood.txtQuantity.text floatValue] > 10.0) {
        [Helper showAlert:@"Error" message:@"The quantity should be at most 10."];
        return;
    }
    
    // Validate the food name
    _addFood.txtFood.text = [_addFood.txtFood.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![Helper checkStringIsValid:_addFood.txtFood.text]) {
        [Helper showAlert:@"Error" message:@"The food name cannot be empty."];
        return;
    }
    
    if (![Helper checkIsNumber:_addFood.txtQuantity.text]) {
        [Helper showAlert:@"Error" message:@"The quantity has to be a number."];
        return;
    }
    
    _addFood.txtComment.text = [_addFood.txtComment.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    FoodConsumptionRecordServiceImpl *recordService = appDelegate.foodConsumptionRecordService;
    FoodProductServiceImpl *foodProductService = appDelegate.foodProductService;
    NSError *error;
    if (self.foodConsumptionRecordToAdd) {
        FoodProduct *foodProduct = [foodProductService getFoodProductByName:appDelegate.loggedInUser
                                                                       name:_addFood.txtFood.text
                                                                      error:&error];
        error = nil;
        
        if (!foodProduct) {
            if (self.adhocFoodProductToAdd) {
                self.foodConsumptionRecordToAdd.foodProduct = self.adhocFoodProductToAdd;
                [foodProductService addAdhocFoodProduct:appDelegate.loggedInUser
                                                product:self.adhocFoodProductToAdd
                                                  error:&error];
                if ([Helper displayError:error]) return;
                
                self.foodConsumptionRecordToAdd.foodProduct.name = _addFood.txtFood.text;
                self.foodConsumptionRecordToAdd.foodProduct.quantity =
                [NSNumber numberWithFloat:_addFood.txtQuantity.text.floatValue];
                self.foodConsumptionRecordToAdd.quantity = self.foodConsumptionRecordToAdd.foodProduct.quantity;
            }
        }
            
        self.foodConsumptionRecordToAdd.quantity = [NSNumber numberWithFloat:_addFood.txtQuantity.text.floatValue];
        self.foodConsumptionRecordToAdd.comment = _addFood.txtComment.text;
        
        NSString *time = _addFood.timeLabel.text;
        NSCalendar *calendar = [NSCalendar currentCalendar];
        [calendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        NSDateComponents *components = [calendar components:(NSYearCalendarUnit |
                                                             NSMonthCalendarUnit |
                                                             NSDayCalendarUnit |
                                                             NSHourCalendarUnit |
                                                             NSMinuteCalendarUnit)
                                                   fromDate:self.dateListView.currentDate];
        [components setCalendar:calendar];
        components.hour = [[time substringToIndex:2] intValue];
        components.minute = [[time substringFromIndex:3] intValue];
        self.foodConsumptionRecordToAdd.timestamp = [components date];
        
        [recordService addFoodConsumptionRecord:appDelegate.loggedInUser
                                         record:self.foodConsumptionRecordToAdd
                                          error:&error];
        if ([Helper displayError:error]) return;
        if (foodProduct) {
            // The food product already exists
            self.foodConsumptionRecordToAdd.foodProduct = foodProduct;
            [recordService saveFoodConsumptionRecord:self.foodConsumptionRecordToAdd error:&error];
            if ([Helper displayError:error]) return;
        }
        
        [self.foodConsumptionRecords addObject:self.foodConsumptionRecordToAdd];
        self.adhocFoodProductToAdd = nil;
        self.foodConsumptionRecordToAdd = nil;
        [self.foodTableView reloadData];
        [_addFood.view removeFromSuperview];
        [clearCover removeFromSuperview];
        _addFood = nil;
        clearCover = nil;
        
        [self.btnAddFood setSelected:NO];
    }
    [self updateProgress];
    [self stopCommentDictation];
}
/**
 * handle action for cancel button in add food view. Just hide the add food view.
 */
- (void)addFoodCancelButtonClick{
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    FoodConsumptionRecordServiceImpl *recordService = appDelegate.foodConsumptionRecordService;
    FoodProductServiceImpl *foodProductService = appDelegate.foodProductService;
    
    NSError *error;
    if (self.foodConsumptionRecordToAdd) {
        [recordService deleteFoodConsumptionRecord:self.foodConsumptionRecordToAdd error:&error];
        if ([Helper displayError:error]) return;
        self.foodConsumptionRecordToAdd = nil;
    }
    if (self.adhocFoodProductToAdd) {
        [foodProductService deleteAdhocFoodProduct:self.adhocFoodProductToAdd error:&error];
        if ([Helper displayError:error]) return;
        self.adhocFoodProductToAdd = nil;
    }
    
    [_addFood.view removeFromSuperview];
    [clearCover removeFromSuperview];
    _addFood = nil;
    clearCover = nil;
    
    [self.btnAddFood setSelected:NO];
    [self stopCommentDictation];
}
/**
 * handle action for add button click. Pop add food view and bind button action.
 * @param sender the button.
 */
- (IBAction)showAddFoodPopover:(id)sender{
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    FoodConsumptionRecordServiceImpl *recordService = appDelegate.foodConsumptionRecordService;
    FoodProductServiceImpl *foodProductService = appDelegate.foodProductService;
    NSError *error;
    self.adhocFoodProductToAdd = [foodProductService buildAdhocFoodProduct:&error];
    if ([Helper displayError:error]) return;
    self.foodConsumptionRecordToAdd = [recordService buildFoodConsumptionRecord:&error];
    if ([Helper displayError:error]) return;
    
    [self.btnAddFood setSelected:YES];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:self.view.frame];
    [btn addTarget:self action:@selector(addFoodCancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    btn.backgroundColor = [UIColor clearColor];
    clearCover = btn;
    [self.view addSubview:clearCover];
    
    _addFood = [self.storyboard instantiateViewControllerWithIdentifier:@"AddFoodView"];
    [self.view addSubview:_addFood.view];
    _addFood.view.frame = CGRectMake(0, 154, 768, 192);
    
    [_addFood.btnDone addTarget:self action:@selector(addFoodDoneButtonClick)
               forControlEvents:UIControlEventTouchUpInside];
    [_addFood.btnCancel addTarget:self action:@selector(addFoodCancelButtonClick)
                 forControlEvents:UIControlEventTouchUpInside];
    [_addFood.btnVoice addTarget:self action:@selector(startCommentDictation:)
                 forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - food Details
/**
 * hide food detail view.
 */
- (void)hideFoodDetail{
    [clearCover removeFromSuperview];
    clearCover = nil;
    [foodDetail.view removeFromSuperview];
    foodDetail = nil;
    [self updateProgress];
    [self stopCommentDictation];
}

/**
 * handle action for save button in detail view. save values in food detail and reload data.
 */
- (void)saveFoodDetail{
    // Validate the quantity
    if (![Helper checkIsNumber:foodDetail.txtQuantity.text]) {
        [Helper showAlert:@"Error" message:@"The quantity has to be a number."];
        return;
    }
    if ([foodDetail.txtQuantity.text floatValue] > 10.0) {
        [Helper showAlert:@"Error" message:@"The quantity should be at most 10."];
        return;
    }
    
    foodDetail.txtComment.text = [foodDetail.txtComment.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    FoodConsumptionRecordServiceImpl *recordService = appDelegate.foodConsumptionRecordService;
    NSError *error;
    
    foodDetail.foodConsumptionRecord.quantity = [NSNumber numberWithFloat:foodDetail.txtQuantity.text.floatValue];
    foodDetail.foodConsumptionRecord.comment = foodDetail.txtComment.text;
    
    NSString *timeString = foodDetail.lblTime.text;
    // set date
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    NSDateComponents *components = [calendar components:(NSYearCalendarUnit |
                                                         NSMonthCalendarUnit |
                                                         NSDayCalendarUnit |
                                                         NSHourCalendarUnit |
                                                         NSMinuteCalendarUnit)
                                               fromDate:self.dateListView.currentDate];
    [components setCalendar:calendar];
    components.hour = [[timeString substringToIndex:2] intValue];
    components.minute = [[timeString substringFromIndex:3] intValue];
    components.second = (int)round([foodDetail.foodConsumptionRecord.timestamp timeIntervalSince1970]) % 60;
    foodDetail.foodConsumptionRecord.timestamp = [components date];
    
    [recordService saveFoodConsumptionRecord:foodDetail.foodConsumptionRecord error:&error];
    if ([Helper displayError:error]) return;
    
    [self.foodTableView reloadData];
    [self updateProgress];
    [clearCover removeFromSuperview];
    clearCover = nil;
    [foodDetail.view removeFromSuperview];
    foodDetail = nil;
    [self stopCommentDictation];
}

/**
 * This method will show food consumption record details.
 * @param record the FoodConsumptionRecord.
 */
- (void)showFoodDetails:(FoodConsumptionRecord *)record{
    foodDetail = [self.storyboard instantiateViewControllerWithIdentifier:@"FoodDetailView"];
    foodDetail.foodConsumptionRecord = record;
    
    clearCover = [[UIView alloc] initWithFrame:self.view.frame];
    clearCover.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.75];
    [self.view addSubview:clearCover];
    
    foodDetail.view.frame = CGRectMake(88, 293, 592, 417);
    [self.view addSubview:foodDetail.view];
    [foodDetail.btnCancel addTarget:self
                             action:@selector(hideFoodDetail)
                   forControlEvents:UIControlEventTouchUpInside];
    
    [foodDetail.btnSave addTarget:self
                           action:@selector(saveFoodDetail)
                 forControlEvents:UIControlEventTouchUpInside];
    
    [foodDetail.btnVoice addTarget:self
                           action:@selector(startCommentDictation:)
                 forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Calendar
/**
 * handle action for date click in date list view.
 * @param date the selected date.
 */
- (void)clickDate:(NSDate *)date{
    [self loadFoodItemsForDate:date];
}

/**
 * CalendarViewDelegate method. Called when select a date in calendar view.
 * @param date the selected data.
 */
- (void)calendarDidSelect:(NSDate *)date{
    self.dateListView.currentDate = date;
    [self.dateListView setNeedsDisplay];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    gregorian.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSDateComponents *info = [gregorian components:(NSYearCalendarUnit |
                                                    NSMonthCalendarUnit |
                                                    NSDayCalendarUnit |
                                                    NSWeekdayCalendarUnit)
                                          fromDate:self.dateListView.currentDate];
    
    self.lblMonth.text = [Helper monthName:info.month];
    self.lblYear.text = [NSString stringWithFormat:@"GMT %d", info.year];
    [self.btnMonth setSelected:NO];
    
    [self loadFoodItemsForDate:date];
}

/**
 * handle action for month button click. Showing calendar pop over.
 * @param sender the button.
 */
- (IBAction)showMonthPopover:(id)sender {
    UIButton *btn = (UIButton *)sender;
    [self.btnMonth setSelected:YES];
    CalendarViewController *calendar = [self.storyboard instantiateViewControllerWithIdentifier:@"CalendarView"];
    calendar.delegate = self;
    UIPopoverController *popController = [[UIPopoverController alloc] initWithContentViewController:calendar];
    popController.popoverBackgroundViewClass = [PopoverBackgroundView class];
    popController.popoverContentSize = CGSizeMake(367, 438);
    popController.delegate = self;
    calendar.popController = popController;
    calendar.listView.selectedDate = self.dateListView.currentDate;
    [calendar setMonth:self.dateListView.currentDate];
    CGRect popoverRect = CGRectMake(btn.bounds.origin.x,
                                    btn.bounds.origin.y,
                                    1,
                                    43);
    
    [popController presentPopoverFromRect:popoverRect
                                   inView:btn
                 permittedArrowDirections:UIPopoverArrowDirectionUp
                                 animated:NO];
}

#pragma mark - copy, delete, past
/**
 * handle action for copy button.
 * @param sender the button.
 */
- (IBAction)copySelected:(id)sender{
    [copyItems removeAllObjects];
    [copyItems addObjectsFromArray:selectedItems];
    [selectedItems removeAllObjects];
    [self.foodTableView reloadData];
    [self.btnCopy setEnabled:NO];
    [self.btnDelete setEnabled:NO];
    [self.btnPaste setEnabled:YES];
    [self hideCopyPop:nil];
}
/**
 * This method will paste selected records.
 * @param sender the button.
 */
- (IBAction)pasteSelected:(id)sender{
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    FoodConsumptionRecordServiceImpl *recordService = appDelegate.foodConsumptionRecordService;
    NSError *error;
    for (FoodConsumptionRecord *record in copyItems) {
        FoodConsumptionRecord *copyRecord = [recordService copyFoodConsumptionRecord:record
                                                                           copyToDay:self.dateListView.currentDate
                                                                               error:&error];
        if ([Helper displayError:error]) return;
        [self.foodConsumptionRecords addObject:copyRecord];
    }
    [copyItems removeAllObjects];
    [self.foodTableView reloadData];
    [self updateProgress];
    [self.btnPaste setEnabled:NO];
    [self hidePastePop:nil];
}
/**
 * handle action for delete button. Just pop over delete confirm dialog.
 * @param sender the button.
 */
- (IBAction)showDeletePop:(id)sender{
    
    UIButton *btn = [[UIButton alloc] initWithFrame:self.view.frame];
    [btn addTarget:self action:@selector(hideDeletePop:) forControlEvents:UIControlEventTouchUpInside];
    btn.backgroundColor = [UIColor clearColor];
    clearCover = btn;
    [self.view addSubview:clearCover];
    
    [self.view bringSubviewToFront:self.deletePopup];
    self.deletePopup.hidden = NO;
    [self.btnDelete setSelected:YES];
}
/**
 * handle action for hiding delete confirm dialog.
 * @param sender the button.
 */
- (IBAction)hideDeletePop:(id)sender{
    
    [clearCover removeFromSuperview];
    clearCover = nil;
    [self.btnDelete setSelected:NO];
    
    self.deletePopup.hidden = YES;
}
/**
 * This method will delete selected records.
 * @param sender the button.
 */
- (IBAction)deleteSelected:(id)sender{
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    FoodConsumptionRecordServiceImpl *recordService = appDelegate.foodConsumptionRecordService;
    NSError *error;
    for (FoodConsumptionRecord *record in selectedItems) {
        // F2Finish change
        [contentOffset removeObjectForKey:record.objectID];
        
        [self.foodConsumptionRecords removeObject:record];
        [recordService deleteFoodConsumptionRecord:record error:&error];
        if ([Helper displayError:error]) return;
    }
    [self.foodTableView reloadData];
    [self updateProgress];
    [self hideDeletePop:nil];
}

/**
 * handle action for copy button. Just pop over copy confirm dialog.
 * @param sender the button.
 */
- (IBAction)showCopyPop:(id)sender{
    
    UIButton *btn = [[UIButton alloc] initWithFrame:self.view.frame];
    [btn addTarget:self action:@selector(hideCopyPop:) forControlEvents:UIControlEventTouchUpInside];
    btn.backgroundColor = [UIColor clearColor];
    clearCover = btn;
    [self.view addSubview:clearCover];
    
    [self.view bringSubviewToFront:self.consumptionCopyPopup];
    self.consumptionCopyPopup.hidden = NO;
    [self.btnCopy setSelected:YES];
}
/**
 * handle action for hiding copy confirm dialog.
 * @param sender the button.
 */
- (IBAction)hideCopyPop:(id)sender{
    
    [clearCover removeFromSuperview];
    clearCover = nil;
    [self.btnCopy setSelected:NO];
    
    self.consumptionCopyPopup.hidden = YES;
}

/**
 * handle action for paste button. Just pop over paste confirm dialog.
 * @param sender the button.
 */
- (IBAction)showPastePop:(id)sender{
    
    UIButton *btn = [[UIButton alloc] initWithFrame:self.view.frame];
    [btn addTarget:self action:@selector(hideCopyPop:) forControlEvents:UIControlEventTouchUpInside];
    btn.backgroundColor = [UIColor clearColor];
    clearCover = btn;
    [self.view addSubview:clearCover];
    
    [self.view bringSubviewToFront:self.pastePopup];
    self.pastePopup.hidden = NO;
    [self.btnPaste setSelected:YES];
}
/**
 * handle action for hiding paste confirm dialog.
 * @param sender the button.
 */
- (IBAction)hidePastePop:(id)sender{
    
    [clearCover removeFromSuperview];
    clearCover = nil;
    [self.btnPaste setSelected:NO];
    
    self.pastePopup.hidden = YES;
}

/**
 * handle action for delete a single row.
 * @param sender the button.
 */
- (void)deleteItem:(id)sender{
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    FoodConsumptionRecordServiceImpl *recordService = appDelegate.foodConsumptionRecordService;
    NSError *error;
    
    UIButton *btn = (UIButton *)sender;
    int row = btn.tag;
    SummaryFoodTableCell *cell = (SummaryFoodTableCell *)[self.foodTableView cellForRowAtIndexPath:
                                                          [NSIndexPath indexPathForRow:row
                                                                             inSection:0]];
    [cell setEditing:NO animated:YES];
    if (cell.btnDone == btn) {
        // F2Finish change
        [contentOffset removeObjectForKey:cell.foodConsumptionRecord.objectID];
        
        [self.foodConsumptionRecords removeObjectAtIndex:row];
        [recordService deleteFoodConsumptionRecord:cell.foodConsumptionRecord error:&error];
        if ([Helper displayError:error]) return;
    }
    [self.foodTableView reloadData];
    [self updateProgress];
}

#pragma mark - photo option
/**
 * handle action for photo button click. Showing photo option pop.
 * @param sender the button.
 */
- (IBAction)showOptionPopup:(id)sender{
    [self.btnPhoto setSelected:YES];
    UIButton *btn = [[UIButton alloc] initWithFrame:self.view.frame];
    [btn addTarget:self action:@selector(hideOptionPopup:) forControlEvents:UIControlEventTouchUpInside];
    btn.backgroundColor = [UIColor clearColor];
    clearCover = btn;
    [self.view addSubview:clearCover];
    
    [self.view bringSubviewToFront:self.optionPopup];
    self.optionPopup.hidden = NO;
}
/**
 * hide photo option pop.
 * @param sender the button.
 */
- (IBAction)hideOptionPopup:(id)sender{
    [clearCover removeFromSuperview];
    clearCover = nil;
    self.optionPopup.hidden = YES;
    [self.btnPhoto setSelected:NO];
}

/**
 * set the custom tabbar view controller here.
 * @param segue The segue object containing information about the view controllers involved in the segue.
 * @param sender The object that initiated the segue.
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.destinationViewController respondsToSelector:@selector(setCustomTabBarController:)]){
        [segue.destinationViewController setCustomTabBarController:self.customTabBarController];
    }
}
#pragma mark - voice search
/**
 * handle action for voice button. Showing voice search view.
 * @param sender the button.
 */
- (IBAction)showVoice:(id)sender{
    UIButton *btn = [[UIButton alloc] initWithFrame:self.view.frame];
    //[btn addTarget:self action:@selector(hideVoice:) forControlEvents:UIControlEventTouchUpInside];
    btn.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.75];
    clearCover = btn;
    [self.view addSubview:clearCover];
    
    voiceSearch = [self.storyboard instantiateViewControllerWithIdentifier:@"VoiceSearchView"];
    voiceSearch.view.frame = CGRectMake(173, 203, 422, 598);
    [self.view addSubview:voiceSearch.view];
    
    [voiceSearch.btnCancel addTarget:self
                              action:@selector(hideVoice:)
                    forControlEvents:UIControlEventTouchUpInside];
    [voiceSearch.btnDone addTarget:self
                            action:@selector(hideVoice:)
                  forControlEvents:UIControlEventTouchUpInside];
    
    [voiceSearch.btnAddToConsumption addTarget:self
                                        action:@selector(hideVoice:)
                              forControlEvents:UIControlEventTouchUpInside];
}
/**
 * This method will add consumption records for selected food products.
 * @param sender the button.
 */
- (void)hideVoice:(id)sender{
    if ([voiceSearch.selectedFoodProducts count] > 0) {
        AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
        FoodConsumptionRecordServiceImpl *recordService = appDelegate.foodConsumptionRecordService;
        NSError *error;
        for (FoodProduct *product in voiceSearch.selectedFoodProducts) {
            FoodConsumptionRecord *record = [recordService buildFoodConsumptionRecord:&error];
            if ([Helper displayError:error]) return;
            record.quantity = @1;
            record.foodProduct.fluid = product.fluid;
            record.foodProduct.sodium = product.sodium;
            record.foodProduct.energy = product.energy;
            record.foodProduct.protein = product.protein;
            record.foodProduct.carb = product.carb;
            record.foodProduct.fat = product.fat;
            
            NSCalendar *calendar = [NSCalendar currentCalendar];
            [calendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
            NSDateComponents *components = [calendar components:(NSYearCalendarUnit |
                                                                 NSMonthCalendarUnit |
                                                                 NSDayCalendarUnit |
                                                                 NSHourCalendarUnit |
                                                                 NSMinuteCalendarUnit)
                                                       fromDate:self.dateListView.currentDate];
            [components setCalendar:calendar];
            
            NSDateComponents *currentDateComponents = [calendar components:(NSHourCalendarUnit |
                                                                            NSMinuteCalendarUnit)
                                                                  fromDate:record.timestamp];
            components.hour = [currentDateComponents hour];
            components.minute = [currentDateComponents minute];
            record.timestamp = [components date];

            [recordService addFoodConsumptionRecord:appDelegate.loggedInUser record:record error:&error];
            record.foodProduct = product;
            [recordService saveFoodConsumptionRecord:record error:&error];
            
            if ([Helper displayError:error]) return;
            [self.foodConsumptionRecords addObject:record];
        }
        [voiceSearch.selectedFoodProducts removeAllObjects];
        [self.foodTableView reloadData];
        [self updateProgress];
    }
    [clearCover removeFromSuperview];
    clearCover = nil;
    
    [voiceSearch.view removeFromSuperview];
    voiceSearch = nil;
}

#pragma mark - select consumption
/**
 * animation delegate method. Called when animation ends. Remove some hidden view here.
 * @param animationID An NSString containing the identifier.
 * @param finished An NSNumber object containing a Boolean value.
 * The value is YES if the animation ran to completion before it stopped or NO if it did not.
 * @param context This is the context data passed to the beginAnimations:context: method.
 */
- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context{
    if([animationID isEqualToString:@"hideSelectConsumption"]){
        [selectConsumption.view removeFromSuperview];
        selectConsumption = nil;
    }
}

/**
 * hide the select consumption view.
 * @param sender the button or nil.
 */
- (void)hideSelectConsumption:(id)sender{
    if(selectConsumption != nil){
        if ([selectConsumption.selectFoods count]> 0) {
            AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
            FoodConsumptionRecordServiceImpl *recordService = appDelegate.foodConsumptionRecordService;
            NSError *error;
            for (FoodProduct *product in selectConsumption.selectFoods) {
                FoodConsumptionRecord *record = [recordService buildFoodConsumptionRecord:&error];
                if ([Helper displayError:error]) return;
                record.quantity = @1;
                record.fluid = product.fluid;
                record.sodium = product.sodium;
                record.energy = product.energy;
                record.protein = product.protein;
                record.carb = product.carb;
                record.fat = product.fat;
                record.timestamp = [Helper convertDateTimeToDate:self.dateListView.currentDate time:[NSDate date]];
                
                [recordService addFoodConsumptionRecord:appDelegate.loggedInUser record:record error:&error];
                record.foodProduct = product;
                [recordService saveFoodConsumptionRecord:record error:&error];
                
                if ([Helper displayError:error]) return;
                [self.foodConsumptionRecords addObject:record];
            }
            [selectConsumption.selectFoods removeAllObjects];
            [self.foodTableView reloadData];
            [self updateProgress];
        }
        [self.navigationController popViewControllerAnimated:YES];
        [self.customTabBarController setConsumptionActive];
    }
}

/**
 * This method will be called when the "mic" icon is clicked to turn on the comment dictation.
 * @param sender the button.
 */
- (IBAction)startCommentDictation:(id)sender {
    if (self.commentToUpdate) {
        _addFood.commentInstructionLabel.text = @"";
        foodDetail.commentInstructionLabel.text = @"";
        // Stop commenting
        [self stopCommentDictation];
    }
    else {
        // start listening for speech
        _addFood.commentInstructionLabel.text = @"Initializing...";
        foodDetail.commentInstructionLabel.text = @"Initializing...";
        listening = YES;
        [self.pocketsphinxController startListeningWithLanguageModelAtPath:[self.lmPaths valueForKey:@"LMPath"]
                                                          dictionaryAtPath:[self.lmPaths valueForKey:@"DictionaryPath"]
                                                       languageModelIsJSGF:FALSE];
        UIButton *button = (UIButton *)sender;
        if ([button isEqual:foodDetail.btnVoice]) {
            self.commentToUpdate = foodDetail.txtComment;
        }
        else if ([button isEqual:_addFood.btnVoice]) {
            self.commentToUpdate = _addFood.txtComment;
        }
    }
}

/**
 * This method will be called when the "mic" icon is clicked to turn off the comment dictation.
 */
- (void)stopCommentDictation {
    // Stop listening for speech
    _addFood.commentInstructionLabel.text = @"";
    foodDetail.commentInstructionLabel.text = @"";
    if (listening) {
        [self.pocketsphinxController stopListening];
    }
    self.commentToUpdate = nil;
}

/**
 * This method will be called when a hypothesis is recognized.
 * @param hypothesis the hypothesis
 * @param recognitionScore the score
 * @param utteranceID the utterance ID
 */
- (void)pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis
                        recognitionScore:(NSString *)recognitionScore
                             utteranceID:(NSString *)utteranceID {
    if (self.commentToUpdate) {
        NSLog(@"Recognized: %@", [hypothesis lowercaseString]);
        self.commentToUpdate.text =
        [[self.commentToUpdate.text stringByAppendingString:@" "]
         stringByAppendingString:[hypothesis lowercaseString]];
    }
}

// An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx is now listening for speech.
- (void) pocketsphinxDidStartListening {
	NSLog(@"Pocketsphinx is now listening.");
    _addFood.commentInstructionLabel.text = @"Speak now, please tap the Mic icon to stop";
    foodDetail.commentInstructionLabel.text = @"Speak now, please tap the Mic icon to stop";
}

- (void) pocketsphinxDidDetectFinishedSpeech {
    _addFood.commentInstructionLabel.text = @"Processing...";
    foodDetail.commentInstructionLabel.text = @"Processing...";
}

- (void) pocketsphinxDidStopListening {
	NSLog(@"Pocketsphinx has stopped listening.");
    listening = NO;
}

- (void) pocketsphinxDidStartCalibration {
	NSLog(@"Pocketsphinx calibration has started.");
}

/**
 * handle action for showing select consumption view.
 * @param sender the button.
 */
- (IBAction)showSelectConsumption:(id)sender {
    self.customTabBarController.imgConsumption.image = [UIImage imageNamed:@"icon-consumption"];
    [self.customTabBarController.btnConsumption setImage:nil forState:UIControlStateNormal];
    self.customTabBarController.activeTab = 0;
    selectConsumption = [self.storyboard instantiateViewControllerWithIdentifier:@"SelectConsumptionView"];
    [self.navigationController pushViewController:selectConsumption animated:YES];
    [self performSelector:@selector(bindSelectionConsumptionBackButton) withObject:nil afterDelay:0.1];
}

- (void) bindSelectionConsumptionBackButton {
    [selectConsumption.btnBack addTarget:self
                                  action:@selector(hideSelectConsumption:)
                        forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - UIPopover Delegate Methods
/**
 * UIPopoverDelegate methods. Called when popover is hidden.
 * @param popoverController the hidden Popover.
 */
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    if ([popoverController.contentViewController isKindOfClass:[CalendarViewController class]]) {
        [self.btnMonth setSelected:NO];
    }
}

#pragma mark - UITableView Delegate Methods
/**
 * returns the row number of table in the section.
 * @param tableView the table requesting the row number.
 * @param section the section of the table.
 * @return the number of fooditems.
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    [selectedItems removeAllObjects];
    if(selectedItems.count == 0){
        [self.btnCopy setEnabled:NO];
        [self.btnDelete setEnabled:NO];
    }
    else{
        [self.btnCopy setEnabled:YES];
        [self.btnDelete setEnabled:YES];
    }
    if(copyItems.count == 0){
        [self.btnCopy setEnabled:NO];
    }
    else{
        [self.btnCopy setEnabled:YES];
    }
    [self updateProgress];
    return self.foodConsumptionRecords.count;
}

/**
 * tells the table what the cell will be like. Update cell content here.
 * @param tableView the table view the cell in.
 * @param indexPath the position the cell in the table.
 * @return an updated cell.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *SummaryFoodTableCellIdentifier = @"SummaryFoodTableCellIdentifier";
    SummaryFoodTableCell *cell = [tableView dequeueReusableCellWithIdentifier:SummaryFoodTableCellIdentifier];
    int row = indexPath.row;
    cell.btnCheck.tag = row;
    cell.btnDone.tag = row;
    cell.btnUndo.tag = row;
    [cell.btnDone addTarget:self action:@selector(deleteItem:) forControlEvents:UIControlEventTouchUpInside];
    [cell.btnUndo addTarget:self action:@selector(deleteItem:) forControlEvents:UIControlEventTouchUpInside];
    [cell.btnCheck addTarget:self action:@selector(foodSelect:) forControlEvents:UIControlEventTouchUpInside];
    FoodConsumptionRecord *item = [self.foodConsumptionRecords objectAtIndex:row];
    cell.foodConsumptionRecord = item;
    if([selectedItems containsObject:item]){
        [cell.btnCheck setSelected:YES];
    }
    else{
        [cell.btnCheck setSelected:NO];
    }
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setPositiveFormat:@"#.##"];
    cell.lblQuantity.text = [numberFormatter stringFromNumber:item.quantity];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    NSDateComponents *components = [calendar components:(NSHourCalendarUnit |
                                                         NSMinuteCalendarUnit)
                                               fromDate:item.timestamp];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    
    cell.lblTime.text = [NSString stringWithFormat:@"%.2d:%.2d", hour, minute];
    cell.lblName.text = item.foodProduct.name;
    if(item.foodProduct.energy.intValue == 0 && item.foodProduct.sodium.intValue == 0 &&
       item.foodProduct.fluid.intValue == 0){
        cell.btnNonNutrient.hidden = NO;
        cell.nutrientView.hidden = YES;
    }
    else{
        cell.btnNonNutrient.hidden = YES;
        cell.nutrientView.hidden = NO;
        cell.lblCalories.text = [NSString stringWithFormat:@"%@", item.foodProduct.energy];
        cell.lblSodium.text = [NSString stringWithFormat:@"%@", item.foodProduct.sodium];
        cell.lblFluid.text = [numberFormatter stringFromNumber:item.foodProduct.fluid];
        cell.lblProtein.text = [NSString stringWithFormat:@"%@", item.foodProduct.protein];
        cell.lblCarb.text = [NSString stringWithFormat:@"%@", item.foodProduct.carb];
        cell.lblFat.text = [NSString stringWithFormat:@"%@", item.foodProduct.fat];
    }
    
    // F2Finish change
    cell.nutrientScrollView.tag = row;
    if ([contentOffset objectForKey:item.objectID]) {
        NSValue *value = [contentOffset objectForKey:item.objectID];
        cell.nutrientScrollView.contentOffset = [value CGPointValue];
    } else {
        cell.nutrientScrollView.contentOffset = CGPointZero;
    }
    
    if(item.comment.length > 0){
        cell.btnComment.hidden = NO;
    }
    else{
        cell.btnComment.hidden = YES;
    }
    if(cell.editing){
        cell.deleteView.hidden = NO;
    }
    else{
        cell.deleteView.hidden = YES;
    }
    [cell setNeedsDisplay];
    return cell;
}

/**
 * action for row selected. Call show food details to showing the detail view.
 * @param tableView the table informing the delegate about the new row selection.
 * @param indexPath the index path of the selected row.
 * @return the SummaryFoodTableCell.
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    SummaryFoodTableCell *cell = (SummaryFoodTableCell *)[tableView cellForRowAtIndexPath:indexPath];
    if(cell.editing){
        return;
    }
    int row = indexPath.row;
    FoodConsumptionRecord *item = [self.foodConsumptionRecords objectAtIndex:row];
    [self showFoodDetails:item];
}

/**
 * tells the table if the row of indexpath could be eidt or not.
 * @param tableView The table-view object requesting this information.
 * @param indexPath An index path locating a row in tableView.
 * @return Always return YES here.
 */
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}
/**
 * update the cell editing value here. Always return UITableViewCellEditingStyleNone to 
 * disable showing delete button.
 * @param tableView The table-view object requesting this information.
 * @param indexPath An index path locating a row in tableView.
 */
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    SummaryFoodTableCell *cell = (SummaryFoodTableCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell setEditing:!cell.editing animated:YES];
    return  UITableViewCellEditingStyleNone;
}

/**
 * just implement this method to enable table enter edit mode.
 * @param tableView The table-view object requesting this information.
 * @param indexPath An index path locating a row in tableView.
 * @param editingStyle The eidting style.
 */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

// F2Finish change - add delegate
#pragma mark - UIScrollView delegate

/**
 * detect a scroll in UIScrollView.
 * @param scrollView The scroll-view object in which the scrolling occurred.
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    FoodConsumptionRecord *item = [self.foodConsumptionRecords objectAtIndex:scrollView.tag];
    CGPoint point = scrollView.contentOffset;
    NSValue *value = [NSValue valueWithCGPoint:point];
    [contentOffset setObject:value forKey:item.objectID];
}

@end

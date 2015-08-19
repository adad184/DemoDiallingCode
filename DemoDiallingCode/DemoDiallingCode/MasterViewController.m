//
//  MasterViewController.m
//  DemoDiallingCode
//
//  Created by Ralph Li on 8/17/15.
//  Copyright (c) 2015 LJC. All rights reserved.
//

#import "MasterViewController.h"
#import "MMCountry.h"

@interface MasterViewController ()

@property NSMutableArray *objects;
@property NSMutableDictionary *dicCode;

@end

@implementation MasterViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    
    [self readData];
}

- (void)readData {
    
    
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"diallingcode" ofType:@"json"]];
    NSError *error = nil;
    
    NSArray *arrayCode = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if ( error ) {
        
        return;
    }
    NSLog(@"%@", arrayCode);
    
    
    //读取文件
    NSMutableDictionary *dicCode = [@{} mutableCopy];
    
    for ( NSDictionary *item in arrayCode )
    {
        MMCountry *c = [MMCountry new];
        
        c.code      = item[@"code"];
        c.dial_code = item[@"dial_code"];
        
        [dicCode setObject:c forKey:c.code];
    }
    
    //获取国家名
    NSLocale *locale = [NSLocale currentLocale];
    NSArray *countryArray = [NSLocale ISOCountryCodes];
    
    NSMutableDictionary *dicCountry = [@{} mutableCopy];
    
    for (NSString *countryCode in countryArray) {
        
        if ( dicCode[countryCode] )
        {
            MMCountry *c = dicCode[countryCode];
            
            c.name = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];
            if ( [c.name isEqualToString:@"台湾"] )
            {
                c.name = @"中国台湾";
            }
            
            c.latin = [self latinize:c.name];
            
            [dicCountry setObject:c forKey:c.code];
        }
        else
        {
            NSLog(@"++ %@ %@",[locale displayNameForKey:NSLocaleCountryCode value:countryCode],countryCode);
        }
    }
    
    //归类
    NSMutableDictionary *dicSort = [@{} mutableCopy];
    
    for ( MMCountry *c in dicCountry.allValues )
    {
        NSString *indexKey = @"";
        
        if ( c.latin.length > 0 )
        {
            indexKey = [[c.latin substringToIndex:1] uppercaseString];
            
            char c = [indexKey characterAtIndex:0];
            
            if ( ( c < 'A') || ( c > 'Z' ) )
            {
                continue;
            }
        }
        else
        {
            continue;
        }
        
        NSMutableArray *array = dicSort[indexKey];
        
        if ( !array )
        {
            array = [NSMutableArray array];
            
            dicSort[indexKey] = array;
        }
        
        [array addObject:c];
    }
    
    //排序
    
    for ( NSString *key in dicSort.allKeys )
    {
        NSArray *array = dicSort[key];
        
        array = [array sortedArrayUsingComparator:^NSComparisonResult(MMCountry *obj1, MMCountry *obj2) {
            
            return [obj1.name localizedStandardCompare:obj2.name];
        }];
        
        //            array = [array sortedArrayUsingComparator:^NSComparisonResult(CSCountry *obj1, CSCountry *obj2) {
        //
        //                return obj1.sortKey > obj2.sortKey;
        //            }];
        
        dicSort[key] = array;
    }
    
    self.dicCode = dicSort;
    
    
    [self.tableView reloadData];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
    if (!self.objects) {
        self.objects = [[NSMutableArray alloc] init];
    }
    [self.objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 26;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSArray *array = self.dicCode[[NSString stringWithFormat:@"%c",(char)('A'+section)]];
    
    return array.count;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSMutableArray *indexArray = [@[] mutableCopy];
    
    for ( int i = 0 ; i < 26 ; ++i )
    {
        NSString *index = [NSString stringWithFormat:@"%c",(char)('A'+i)];
        NSArray *array = self.dicCode[index];
        
        if ( array.count > 0 )
        {
            [indexArray addObject:index];
        }
    }
    
    return indexArray;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ( tableView != self.tableView )
    {
        return nil;
    }
    
    UILabel *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"section"];
    
    if ( !header )
    {
        header = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 30)];
        header.textAlignment = NSTextAlignmentLeft;
        header.textColor = [UIColor blackColor];
        header.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
        header.font = [UIFont boldSystemFontOfSize:14];
    }
    
    header.text = [NSString stringWithFormat:@"　%c",(char)('A'+section)];
    
    return header;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    char firstChar = [title characterAtIndex:0];
    return firstChar - 'A';
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    
    NSArray *array = self.dicCode[[NSString stringWithFormat:@"%c",(char)('A'+indexPath.section)]];
    
    MMCountry *c = array[indexPath.row];
    
    cell.textLabel.text = c.name;
    cell.detailTextLabel.text = c.dial_code;
    
    return cell;
}

- (NSString*)latinize:(NSString*)str
{
    NSMutableString *source = [str mutableCopy];
    
    CFStringTransform((__bridge CFMutableStringRef)source, NULL, kCFStringTransformToLatin, NO);
    //    CFStringTransform((__bridge CFMutableStringRef)source, NULL, kCFStringTransformMandarinLatin, NO);
    
    CFStringTransform((__bridge CFMutableStringRef)source, NULL, kCFStringTransformStripDiacritics, NO);
    
    return source;
}



@end

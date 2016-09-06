//
//  ViewController.m
//  TestRealm
//
//  Created by Philip.Lee on 9/2/16.
//  Copyright © 2016 Philip.Lee. All rights reserved.
//

#import "ViewController.h"
#import <Realm/Realm.h>
#import <AFNetworking.h>
#import "PLLatestNewsCell.h"
#import "PLStory.h"
#import <UIImageView+WebCache.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *data;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak __typeof(&*self) weakSelf = self;
    [self fetchDataWith:^(BOOL success){

        [weakSelf.tableView reloadData];
        
        RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
        config.schemaVersion = 5;
        
        config.migrationBlock = ^(RLMMigration *migration, uint64_t oldSchemaVersion) {
            if (oldSchemaVersion < 3) {
                [migration enumerateObjects:PLStory.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                    if (oldSchemaVersion < 3) {
                        // combine name fields into a single field
                        newObject[@"image"] = oldObject[@"images"];
                        newObject[@"gaPrefix"] = oldObject[@"ga_prefix"];
                    }
                }];
            }
            // 版本4时，删除了 字段 gaPrefix
            if (oldSchemaVersion < 5) {
                [migration enumerateObjects:PLStory.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                    if ([oldObject[@"uid"] longValue] == 8762336) {
                        PLFollower *follower = [PLFollower new];
                        follower.name = @"---";
                        [newObject[@"followers"] addObject:follower];
                    }
                }];
            }
            NSLog(@"Migration complete.");
        };
        [RLMRealmConfiguration setDefaultConfiguration:config];
        
        for (PLStory *story in weakSelf.data) {
            RLMRealm *realm = [RLMRealm defaultRealm];
            
            __weak RLMRealm *rlm = realm;
            [realm transactionWithBlock:^{
                [rlm addOrUpdateObject:story];
            }];
        }
        
        // 10s后 更新数据
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            RLMResults *res = [PLStory allObjects];
            NSMutableArray *arr = [@[] mutableCopy];
            for (PLStory *story in res) {
                if ([story.title containsString:@"知乎"]) {
                    [res.realm transactionWithBlock:^{
                        story.title = @"------changed-------";
                    }];
                }
                [arr addObject:story];
            }
            weakSelf.data = arr;
            [weakSelf.tableView reloadData];
            NSLog(@"------%ld", arr.count);
        });
        
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PLLatestNewsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PLLatestNewsCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    PLStory *story = _data[indexPath.row];
    cell.titleLabel.text = story.title;
    
    NSString *imgUrl = nil;
    if ([story.image isKindOfClass:NSArray.class]) {
        NSArray *imgs = (NSArray *)story.image;
        if (imgs.count > 0) {
            imgUrl = [imgs firstObject];
        }
    } else {
        imgUrl = story.image;
    }
    [cell.imgView sd_setImageWithURL:[NSURL URLWithString:imgUrl]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return .1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return .1;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor clearColor];
    
    return view;
}

-(void)fetchDataWith:(void (^)(BOOL success))completion
{
    NSString *url = @"http://news-at.zhihu.com/api/4/news/latest";
    [[AFHTTPSessionManager manager] GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *data = responseObject;
        if (![data isKindOfClass:NSDictionary.class]) {
            data = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
        }
        
        NSMutableArray *arr = [NSMutableArray array];
        for (NSDictionary *dic in data[@"top_stories"]) {
            PLStory *story = [PLStory new];
            story.uid = [dic[@"id"] longValue];
            story.title = dic[@"title"];
            story.image = dic[@"image"];
            [arr addObject:story];
        }
        self.data = arr;
        NSLog(@"----%@", data);
        
        if (completion) {
            completion(YES);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"----error");
    }];
}

@end

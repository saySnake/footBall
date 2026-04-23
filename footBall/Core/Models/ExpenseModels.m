#import "ExpenseModels.h"

static NSString *PNStringFromId(id o) {
    if ([o isKindOfClass:NSString.class]) {
        return [(NSString *)o stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if ([o isKindOfClass:NSNumber.class]) {
        return [(NSNumber *)o stringValue];
    }
    return nil;
}

/// 上传时存的是 objectKey，列表里若只返回 key，需拼成可访问的公网地址（与 FileRequest 的 bucket/region 一致）
static NSString *PNExpenseAbsoluteImageURL(NSString *s) {
    if (s.length == 0) return nil;
    NSString *t = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (t.length == 0) return nil;
    if ([t hasPrefix:@"http://"] || [t hasPrefix:@"https://"]) {
        return t;
    }
    if ([t hasPrefix:@"//"]) {
        return [NSString stringWithFormat:@"https:%@", t];
    }
    static NSString *const kBase = @"https://passnomad.oss-cn-beijing.aliyuncs.com";
    NSCharacterSet *pathAllowed = [NSCharacterSet URLPathAllowedCharacterSet];
    NSString *enc = [t stringByAddingPercentEncodingWithAllowedCharacters:pathAllowed];
    if (enc.length == 0) {
        enc = t;
    }
    return [NSString stringWithFormat:@"%@/%@", kBase, enc];
}

@implementation PNExpense
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{@"expenseId": @[@"id", @"expenseId", @"expense_id"],
             @"userId": @[@"userId", @"uid", @"user_id"],
             @"matchRecordId": @[@"matchRecordId", @"matchId", @"match_record_id", @"recordId", @"record_id"],
             @"itemName": @[@"itemName", @"title", @"name", @"item", @"remark", @"description", @"consumeName", @"productName", @"goodsName", @"subject", @"summary", @"expenseTitle", @"label", @"content"],
             @"amount": @[@"amount", @"money", @"price", @"totalAmount", @"total", @"payAmount", @"pay_amount"],
             @"expenseDate": @[@"expenseDate", @"date", @"consumeDate", @"bizDate", @"consume_date", @"expense_date"],
             @"createTime": @[@"createTime", @"createdAt", @"gmtCreate", @"createTimeStr", @"created_time", @"gmt_create"],
             @"photos": @[@"photos", @"photoUrls", @"images", @"picUrls", @"fileUrls", @"uploadUrls", @"pictures"],
             @"logoUrl": @[@"logoUrl", @"logo", @"teamLogo", @"iconUrl", @"coverUrl", @"imageUrl", @"avatar", @"headImg", @"cover", @"image", @"imgUrl", @"img"]};
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    if (self.itemName.length == 0) {
        id matchObj = dic[@"match"] ?: dic[@"matchInfo"] ?: dic[@"matchRecord"] ?: dic[@"matchVO"];
        if ([matchObj isKindOfClass:NSDictionary.class]) {
            NSDictionary *m = (NSDictionary *)matchObj;
            NSString *n = PNStringFromId(m[@"matchName"] ?: m[@"name"] ?: m[@"title"] ?: m[@"homeTeamName"]);
            if (n.length) {
                self.itemName = n;
            }
        }
    }
    if (self.itemName.length == 0) {
        NSArray<NSString *> *keys = @[
            @"itemName", @"title", @"name", @"consumeName", @"productName", @"goodsName",
            @"subject", @"summary", @"expenseTitle", @"label", @"remark", @"content", @"description"
        ];
        for (NSString *k in keys) {
            NSString *s = PNStringFromId(dic[k]);
            if (s.length) {
                self.itemName = s;
                break;
            }
        }
    }
    if ([self.photos isKindOfClass:NSArray.class]) {
        NSMutableArray<NSString *> *out = [NSMutableArray array];
        for (id p in (NSArray *)self.photos) {
            if ([p isKindOfClass:NSString.class] && [((NSString *)p) length] > 0) {
                [out addObject:(NSString *)p];
            } else if ([p isKindOfClass:NSDictionary.class]) {
                NSString *u = PNStringFromId(((NSDictionary *)p)[@"url"] ?: ((NSDictionary *)p)[@"key"] ?: ((NSDictionary *)p)[@"objectKey"] ?: ((NSDictionary *)p)[@"path"]);
                if (u.length) {
                    [out addObject:u];
                }
            }
        }
        self.photos = out;
    } else {
        self.photos = @[];
    }
    if (self.photos.count == 0) {
        NSString *one = PNStringFromId(dic[@"photo"] ?: dic[@"photoUrl"] ?: dic[@"pic"] ?: dic[@"image"]);
        if (one.length) {
            self.photos = @[one];
        }
    }
    NSString *cand = self.logoUrl;
    if (cand.length == 0 && self.photos.count > 0) {
        cand = self.photos.firstObject;
    }
    if (cand.length) {
        NSString *abs = PNExpenseAbsoluteImageURL(cand);
        if (abs.length) {
            self.logoUrl = abs;
        }
    }
    return YES;
}
@end

@implementation PNExpensePage
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{@"list": @[@"list", @"records", @"rows", @"items", @"content"],
             @"pageNum": @[@"pageNum", @"current", @"page", @"pageNo"],
             @"pageSize": @[@"pageSize", @"size", @"limit"],
             @"total": @[@"total", @"count", @"totalCount"]};
}
+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    return @{@"list": PNExpense.class};
}
@end

@implementation PNExpenseSummary
@end

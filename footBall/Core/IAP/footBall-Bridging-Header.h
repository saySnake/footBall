//
//  footBall-Bridging-Header.h
//  footBall
//
//  OC → Swift 混编桥接头文件。
//  StoreKit 2 是 Swift-only API（iOS 15+），通过此桥接让 Swift wrapper 能调用
//  现有 OC 网络层（MembershipRequest / AuthManager）。
//
//  注意：此文件路径需在 Build Settings → Swift Compiler - Objective-C Bridging Header
//  配置为 `footBall/Core/IAP/footBall-Bridging-Header.h`。
//
//  重要：Swift 编译器编译 bridging header 时不会加载 OC 的 prefix header
//  （footBall-Prefix.pch 里的 #import 不会生效），因此这里必须显式 import
//  所有传递依赖中需要的框架与项目头，否则会报 "expected a type" /
//  "no type or protocol named 'YYModel'"，并最终导致 SwiftGeneratePch 失败。
//

// 第三方框架：User.h 遵循 <YYModel>，必须在被间接 import 之前包含
#import <YYModel/YYModel.h>

// 项目头：补齐 APISuccessBlock / APIFailureBlock / HTTPResponse 等类型定义
#import "APIManager.h"

// 桥接目标
#import "MembershipRequest.h"
#import "AuthManager.h"

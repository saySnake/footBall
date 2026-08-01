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

#import "MembershipRequest.h"
#import "AuthManager.h"

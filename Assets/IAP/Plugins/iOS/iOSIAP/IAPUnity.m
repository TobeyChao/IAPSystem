#import "IAPManager.h"

#import <Foundation/Foundation.h>

#if defined(__cplusplus)

extern "C" {

#endif

// 判定商品是否有效
bool IsProductAvailable()
{
    return [[IAPManager shareInstance] CanMakePayment];
}

// 请求获得商品信息
void RequestProductInfo(char* p)
{
    NSString* list = [NSString stringWithUTF8String:p];
    [[IAPManager shareInstance] requestProductData:list];
}

// 购买商品
void BuyProduct(char* p)
{
    [[IAPManager shareInstance] buyRequest:[NSString stringWithUTF8String:p]];
}

// 处理一些未完成支付
void HandlePaymentQueue()
{
    [[IAPManager shareInstance] handlePaymentQueue];
}

#if defined(__cplusplus)
}
#endif
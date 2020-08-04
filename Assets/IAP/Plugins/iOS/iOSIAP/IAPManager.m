#import "IAPManager.h"

static IAPManager* instance = nil;

@implementation IAPManager

+(id)shareInstance
{
    if (instance == nil)
    {
        instance = [[[self class] alloc] init];
        [instance attachObserver];
    }
    return instance;
}

// 处理一些未完成的支付
-(void)handlePaymentQueue
{
    NSArray* transactions = [SKPaymentQueue defaultQueue].transactions;
    if (transactions.count > 0)
    {
        // NSLog(@"transactions.count = %lu", (unsigned long)transactions.count);
        for(SKPaymentTransaction* transaction in transactions)
        {
            if (transaction.transactionState == SKPaymentTransactionStatePurchased)
            {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
        }
    }

}

-(void) attachObserver
{
    NSLog(@"attachObserver");
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

-(BOOL) CanMakePayment
{

    return [SKPaymentQueue canMakePayments];
}

-(void) requestProductData:(NSString* )productIdentifiers
{
    NSArray* idArray = [productIdentifiers componentsSeparatedByString:@"\t"];
    NSSet* idSet = [NSSet setWithArray:idArray];
    [self sendRequest:idSet];
}

-(void) sendRequest:(NSSet* )idSet
{
    SKProductsRequest* request = [[SKProductsRequest alloc] initWithProductIdentifiers:idSet];
    request.delegate = self;
    [request start];
}

-(void) productsRequest:(SKProductsRequest*)request didReceiveResponse:(SKProductsResponse*)response
{
    NSArray* products = response.products;

    for (SKProduct* p in products)
    {
        NSLog(@"Valid product id: %@", p.productIdentifier);
        UnitySendMessage("IAPMgr", "AddProduct", [[self productInfo:p] UTF8String]);
    }
    for (NSString* invalidProductId in response.invalidProductIdentifiers)
    {
        NSLog(@"Invalid product id: %@", invalidProductId);
    }
    // [request autorelease];
}

-(void) buyRequest:(NSString*)productIdentifier
{
    SKPayment* payment = [SKPayment paymentWithProductIdentifier:productIdentifier];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

-(NSString*) productInfo:(SKProduct*)product
{
    NSArray* info = [NSArray arrayWithObjects:
                     product.localizedTitle,
                     product.localizedDescription,
                     product.productIdentifier,
                     product.priceLocale.currencyCode,
                     product.price,
                     nil];
    return [info componentsJoinedByString:@","];
}

// 处理支付队列
-(void) paymentQueue:(SKPaymentQueue*)queue updatedTransactions:(NSArray*)transactions
{
    for (SKPaymentTransaction* transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

-(void) provideContent:(SKPaymentTransaction *)transaction
{
    UnitySendMessage("IAPMgr", "ProvideContent", [[self transactionInfo:transaction] UTF8String]);
}

// 支付动作转字符串
-(NSString*) transactionInfo:(SKPaymentTransaction*)transaction
{
    NSArray* info = [NSArray arrayWithObjects:transaction.payment.productIdentifier,
                     [NSString stringWithFormat:@"%d",transaction.transactionState],
                     [transaction.transactionReceipt base64Encoding],
                     transaction.transactionIdentifier,
                     nil];
    
    return [info componentsJoinedByString:@","];

}

// 支付完成回调
-(void) completeTransaction:(SKPaymentTransaction*)transaction
{
    NSLog(@"Complete transaction: transactionIdentifier = %@\n", transaction.transactionIdentifier);
    [self provideContent:transaction];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    // 直接调用Unity
    NSLog([self transactionInfo:transaction]);
    UnitySendMessage("IAPMgr", "BuyProductSucessCallBack", [[self transactionInfo:transaction] UTF8String]);
}

 

// 支付失败回调
-(void) failedTransaction:(SKPaymentTransaction*)transaction
{
    NSLog(@"Failed transaction: %@", transaction.transactionIdentifier);
    [self provideContent:transaction];
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"!Cancelled");
    }
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    UnitySendMessage("IAPMgr", "BuyProductFailedCallBack", [[self transactionInfo:transaction] UTF8String]);
}


-(void) restoreTransaction:(SKPaymentTransaction*) transaction
{
    NSLog(@"Restore transaction: %@", transaction.transactionIdentifier);
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}
@end

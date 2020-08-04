using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using System;
using System.Runtime.Serialization.Formatters.Binary;
using System.IO;

class Product
{
    public Product(string id, string currencyCode, double price)
    {
        ProductId = id;
        CurrencyCode = currencyCode;
        Price = price;
    }

    public string ProductId { get; }

    public string CurrencyCode { get; }

    public double Price { get; }
}

public class IAPMgr : SingletonComponent<IAPMgr>
{
    private Dictionary<string, Product> productInfo = new Dictionary<string, Product>();
    public List<string> productInfoPreRequest = new List<string>();

    public event Action<string[]> OnBuyProductSucess;
    public event Action<string[]> OnBuyProductFailed;

    public void Start()
    {
        StartCoroutine(InitProductInfo());
    }

    private IEnumerator InitProductInfo()
    {
        yield return new WaitForSeconds(2.0f);
        RequestALLProductInfo();
    }

    /// <summary>
    /// 刷新product列表
    /// </summary>
    /// <param name="str">
    /// 逗号分隔
    /// 0：名称
    /// 1：描述
    /// 2id
    /// 3：3位货币代码
    /// 4：价格
    /// </param>
    void AddProduct(string str)
    {
        string[] sArray = Regex.Split(str, ",", RegexOptions.IgnoreCase);
        productInfo.Add(sArray[2], new Product(sArray[2], sArray[3], double.Parse(sArray[4])));
    }

    //获取商品回执
    void ProvideContent(string s)
    {
        Debug.Log("[MsgFrom ios]proivideContent");
    }

    public bool IsProductVailable()
    {
#if UNITY_IOS && !UNITY_EDITOR
        return IsProductAvailable();
#else
        return false;
#endif
    }

    public void RequestALLProductInfo()
    {
#if UNITY_IOS && !UNITY_EDITOR
        if (IsProductAvailable())
        {
            foreach (string item in productInfoPreRequest)
            {
                RequestProductInfo(item);
            }
        }
#endif
    }

    /// <summary>
    /// 请求购买
    /// </summary>
    /// <param name="productID">Product identifier.</param>
    public void RequestBuyProduct(string productID)
    {
#if UNITY_IOS && !UNITY_EDITOR
        BuyProduct(productID);
#endif
    }

    /// <summary>
    /// 购买商品成功的回调
    /// </summary>
    /// <param name="str">String.</param>
    public void BuyProductSucessCallBack(string str)
    {
        /*
         * sArray[0]    //商品ID
         * sArray[0]    //订单状态，一般用不到
         * sArray[2]    //购买回执
         * sArray[3]    //订单ID
        */
        string[] sArray = Regex.Split(str, ",", RegexOptions.IgnoreCase);
        OnBuyProductSucess(sArray);
    }
    /// <summary>
    /// 购买商品失败调回调
    /// </summary>
    /// <param name="str">String.</param>
    public void BuyProductFailedCallBack(string str)
    {
        /*
         * sArray[0]    //商品ID
         * sArray[0]    //订单状态，一般用不到
         * sArray[2]    //购买回执
         * sArray[3]    //订单ID
        */
        string[] sArray = Regex.Split(str, ",", RegexOptions.IgnoreCase);
        OnBuyProductFailed(sArray);
    }

#if UNITY_IOS && !UNITY_EDITOR
    //此函数暂时没有使用
    [DllImport("__Internal")]
    private static extern void HandlePaymentQueue();//处理一些未完成支付

    [DllImport("__Internal")]
    private static extern bool IsProductAvailable();//判断是否可以购买

    [DllImport("__Internal")]
    private static extern void RequestProductInfo(string s);//获取商品信息

    [DllImport("__Internal")]
    private static extern void BuyProduct(string s);//购买商品
#endif
}
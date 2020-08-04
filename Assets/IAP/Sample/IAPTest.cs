using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class IAPTest : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        if (IAPMgr.Instance)
        {
            IAPMgr.Instance.OnBuyProductSucess += Instance_OnBuyProductSucess;
        }
    }

    private void Instance_OnBuyProductSucess(string[] obj)
    {
        throw new System.NotImplementedException();
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}

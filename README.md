# delhyperv
使用powershell 關閉hyper-v 且清空檔案

## VMFunctions.ps1 
共同呼叫程序，主要目的在於停用 hyper-v 內的VM，且進行實體檔案的刪除。

## local.bat
可放於開機啟動，來進行驗證是否密碼正確；不正確將重要的VM進行移除作業，降低資料被偷走的風險。

## local02.ps1
主要程式。
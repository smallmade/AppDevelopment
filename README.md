# AppDevelopment — 傘形站點

這裡放的是**已上架或準備上架的應用程式各自的支援頁與隱私頁**。
App Store Connect 的 Support URL 與 Privacy Policy URL 是必填欄位，
而一個 404 的隱私政策是會被拒審的 —— 這個站台存在的唯一理由就是讓那兩個 URL 回 200。

## 目錄長什麼樣

```
AppDevelopment/
  apps.json            ← 清單。加一個 App 就是在這裡加一筆
  index.html           ← 由 apps.json 產生，不要手改
  tools/
    generate-hub.swift ← 產生器
    hub.css.html       ← 共用版式
  flameone/            ← 一個 App 一個資料夾，資料夾名就是 slug
    index.html  support.html  privacy.html
  .nojekyll            ← 讓 GitHub Pages 原樣送檔，不跑 Jekyll
```

## 兩支閘門

```bash
swiftc -O -o /tmp/generate-hub tools/generate-hub.swift && /tmp/generate-hub  # 產生首頁，順便確認頁面都在
bash tools/checklinks.sh                                                      # 站內所有相對連結都指向存在的檔案
```

兩支都帶已知會失敗的樣本 —— 一個只會說「全部正常」的檢查，
和一個根本沒掃到任何東西的檢查，輸出長得一樣。

## 加一個 App

1. 建 `<slug>/` 資料夾，放進 `index.html`、`support.html`、`privacy.html` 三張。
2. 在 `apps.json` 的 `apps` 陣列加一筆。
3. 重新產生首頁：

   ```bash
   swiftc -O -o /tmp/generate-hub tools/generate-hub.swift && /tmp/generate-hub
   ```

產生器會**先檢查每一個被列出的 App 的三張頁面是不是真的在**，缺一張就拒絕產生並列出缺的是哪些。
一個連到 404 的首頁比沒有首頁更糟。

## slug 一旦送審就固定了

`slug` 是資料夾名，因此也是 ASC 記錄下來的 URL 的一部分。
某個 App 送審之後再改它的 slug，會讓 ASC 裡已經填好的兩個 URL 失效。

## 與既有的 smallmade.github.io 根站台是什麼關係

**兩者各自獨立，這裡不影響那裡。**

根站台 `https://smallmade.github.io/` 上已經有七個 App 的頁面上線
（gas-dynamics、mechanicsone、passthrough、plot4mac、structuremechone、texone、thermodynamics）。
那個站台的完整來源不在本機 —— 本機 `GasDynamicsCalculator/site/` 只有其中四個，
少了 mechanicsone、structuremechone 與 thermodynamics。
**所以不要拿本機那份去覆蓋根站台**：那會讓三個已上架 App 的隱私政策 404。

本站是新建的、獨立的一個站台，路徑上多一層 `/AppDevelopment/`。

## 發布

尚未發布。要上線需要三步，**都是對外操作**：

1. 在 GitHub 建立倉庫 `smallmade/AppDevelopment`。
2. 把本目錄推上去（本目錄已是一個本機 git 倉庫，只差 remote 與 push）。
3. 在倉庫的 Settings → Pages 選擇從 `main` 分支的根目錄發布。

完成後這兩個 URL 應該回 200：

- `https://smallmade.github.io/AppDevelopment/flameone/support.html`
- `https://smallmade.github.io/AppDevelopment/flameone/privacy.html`

**上線後要實際打開這兩個 URL 確認回 200 再填進 ASC**，不要憑推論。

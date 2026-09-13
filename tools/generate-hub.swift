// generate-hub.swift — 由 apps.json 產生傘形站點的首頁。
//
// **為什麼要由清單產生，而不是手寫 index.html：**
// 本系列已經被「手寫的登記表」咬過不只一次 —— 每一份「哪些東西算數」的手寫集合
// 都掉過東西，而掉的那一項不會有任何跡象。首頁列出哪些 App、連到哪些 URL，
// 正是這種集合。加一個 App 就是在 apps.json 加一筆，然後重跑這支程式。
//
// 同時檢查**每一個被列出的 App，它的資料夾與兩個必填頁面是不是真的在**。
// 一個連到 404 隱私政策的首頁比沒有首頁更糟：ASC 那兩個 URL 是必填，
// 而一個 404 的隱私政策是會被拒審的。
import Foundation

struct App: Decodable {
    let slug: String
    let name: String
    let tagline: String
    let platforms: String
    let status: String
}
struct Site: Decodable { let title: String; let lede: String; let contact: String }
struct Manifest: Decodable { let site: Site; let apps: [App] }

func escape(_ s: String) -> String {
    s.replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
guard let data = try? Data(contentsOf: root.appendingPathComponent("apps.json")),
      let manifest = try? JSONDecoder().decode(Manifest.self, from: data) else {
    FileHandle.standardError.write(Data("generate-hub: 讀不到或解析不了 apps.json\n".utf8))
    exit(2)
}
guard let css = try? String(contentsOf: root.appendingPathComponent("tools/hub.css.html"),
                            encoding: .utf8) else {
    FileHandle.standardError.write(Data("generate-hub: 讀不到 tools/hub.css.html\n".utf8))
    exit(2)
}

// 先驗證，再產生。順序反過來的話，壞掉的首頁已經寫出去了。
var missing: [String] = []
for app in manifest.apps {
    for page in ["support.html", "privacy.html", "index.html"] {
        let path = root.appendingPathComponent(app.slug).appendingPathComponent(page)
        if !FileManager.default.fileExists(atPath: path.path) {
            missing.append("\(app.slug)/\(page)")
        }
    }
}
guard missing.isEmpty else {
    FileHandle.standardError.write(Data("generate-hub: 以下頁面不存在，首頁會連到 404：\n".utf8))
    for m in missing { FileHandle.standardError.write(Data("  \(m)\n".utf8)) }
    exit(3)
}

var items = ""
for app in manifest.apps {
    let soon = app.status == "not-yet-submitted" ? " class=\"soon\"" : ""
    let note = app.status == "not-yet-submitted"
        ? "<p class=\"meta\">Not yet on the App Store.</p>" : ""
    items += """
    <li\(soon)><h2><a href="\(app.slug)/index.html">\(escape(app.name))</a></h2>\
    <p>\(escape(app.tagline))</p>\
    <p class="meta">\(escape(app.platforms))</p>\(note)\
    <p class="links"><a href="\(app.slug)/support.html">Support</a>\
    <a href="\(app.slug)/privacy.html">Privacy policy</a></p></li>

    """
}

let html = """
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>\(escape(manifest.site.title))</title>
<meta name="description" content="Support and privacy for the applications published here.">
\(css)</head>
<body>
<div class="wrap">

<header>
  <h1>\(escape(manifest.site.title))</h1>
  <p class="lede">\(escape(manifest.site.lede))</p>
</header>

<ul class="apps">
\(items)</ul>

<footer>
<p>Questions: <a href="mailto:\(manifest.site.contact)">\(manifest.site.contact)</a></p>
<p>This page is generated from <code>apps.json</code>; do not edit it by hand.</p>
</footer>

</div>
</body>
</html>

"""

let out = root.appendingPathComponent("index.html")
try! html.write(to: out, atomically: true, encoding: .utf8)
print("index.html ← apps.json（\(manifest.apps.count) 個 App，每個的三個頁面都確認存在）")

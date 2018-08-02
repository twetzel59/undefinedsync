import os, webview

let wv = newWebView("Sync", "file://" & getCurrentDir() & "/web/index.html")

try:
    wv.run()
finally:
    wv.exit()

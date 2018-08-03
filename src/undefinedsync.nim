import os, webview

proc doDownload() = 
    echo "Download"

proc doUpload() =
    echo "Upload"

proc main() =
    let wv = newWebView("Sync", "file://" & getCurrentDir() & "/web/index.html", resizable = false)

    wv.bindProcs("api"):
        proc download() = doDownload()
        proc upload() = doUpload()

    try:
        wv.run()
    finally:
        wv.exit()

when isMainModule:
    main()

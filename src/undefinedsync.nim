import std / os
import webview

type
  MessageKind = enum
    mkExitSuccess,
    mkExitFailure
  
  Message = object
    case kind: MessageKind:
    of mkExitFailure:
      exceptionMsg: string
    else:
      discard

proc initMessageExitSuccess(): Message =
  Message(kind: mkExitSuccess)
proc initMessageExitFailure(exceptionMsg: string): Message =
  Message(kind: mkExitFailure, exceptionMsg: exceptionMsg)

const inetError = (
  title: "Network Error",
  msg: "Sync thinks that you are not connected to the Internet. Check your network and proxy.")

var wv: Webview
var chan: Channel[Message]

proc loop(wv: Webview; blocking: bool): bool =
  wv.loop(blocking.cint).bool

#proc checkInternet(): bool =
#  false

proc begin() {.thread, raises: [].} =
  try:
    #for i in 0..100000:
    #  echo "hi"
    #  if i == 1000:
    #    raise newException(ValueError, "Test exception")
    chan.send(initMessageExitSuccess())
  except:
    try:
      chan.send(initMessageExitFailure(getCurrentExceptionMsg()))
    except:
      echo "Error sending exception message over channel. This is a bug!"

proc doDownload() =
  discard

proc doUpload() =
  discard

proc main() =
  try:
    wv = newWebView("Sync", "file://" & getCurrentDir() & "/web/index.html", resizable = false)

    wv.bindProcs("api"):
      proc download() = doDownload()
      proc upload() = doUpload()

    chan.open()

    var work: Thread[void]
    createThread[void](work, begin)

    var counter = 0
    while not wv.loop(false):
      echo counter
      if counter == 100000:
        echo "test"
        break
      inc counter

    joinThread(work)
  finally:
    let info = chan.tryRecv()
    if info.dataAvailable:
      case info.msg.kind:
      of mkExitSuccess:
        discard
      of mkExitFailure:
        let errBody = "The worker thread crashed! Exception message: " &
          info.msg.exceptionMsg
        echo errBody

    chan.close()
    wv.exit()
    echo "Cleaning Up"

when isMainModule:
  main()

import std / [ os, threadpool ]
import webview

type
  MessageKind = enum
    mkInetOk,
    mkInetErr,
    mkExitFailure
  
  Message = object
    case kind: MessageKind:
    of mkExitFailure:
      exceptionMsg: string
    else:
      discard

proc initMessageInetOk(): Message =
  Message(kind: mkInetOk)
proc initMessageInetErr(): Message =
  Message(kind: mkInetErr)
proc initMessageExitFailure(exceptionMsg: string): Message =
  Message(kind: mkExitFailure, exceptionMsg: exceptionMsg)

const serverReply = "undefinedSync_proto0"
const inetError = (
  title: "Network Error",
  msg: "Sync thinks that you are not connected to the Internet. Check your network and proxy.")

var wv: Webview
var chan: Channel[Message]

proc loop(wv: Webview; blocking: bool): bool =
  wv.loop(blocking.cint).bool

template workerErrHandler(body: untyped): untyped =
  try:
    body
  except:
    try:
      chan.send(initMessageExitFailure(getCurrentExceptionMsg()))
    except:
      echo "Error sending exception message over channel. This is a bug!"

proc checkInternet() {.raises: [].} =
  workerErrHandler:
    sleep(4000)
    chan.send(initMessageInetErr())

proc doDownload() =
  discard

proc doUpload() =
  discard

proc main() =
  wv = newWebView("Sync", "file://" & getCurrentDir() & "/web/index.html", resizable = false)
  chan.open()

  try:
    wv.bindProcs("api"):
      proc download() = doDownload()
      proc upload() = doUpload()

    spawn checkInternet()

    while not wv.loop(true):
      let info = chan.tryRecv()
      if info.dataAvailable:
        case info.msg.kind:
        of mkInetOk:
          break
        of mkInetErr:
          echo inetError.msg
          wv.error(inetError.title, inetError.msg)
          break
        of mkExitFailure:
          let errBody = "The worker thread crashed! Exception message: " &
            info.msg.exceptionMsg
          echo errBody
          wv.error("Exception", errBody)
          break
  finally:
    chan.close()
    wv.exit()
    echo "Cleaning Up"

when isMainModule:
  main()

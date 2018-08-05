import std / [ os, threadpool ]
import webview

type
  MessageKind = enum ## Indicates the type of message
    mkInetOk,        ## sent over the channel.
    mkInetErr,
    mkExitFailure
  
  Message = object ## A complete message.
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

const serverReply = "undefinedSync_proto0" ## The reply the server should send if it 
                                           ## is compatible.
const inetError = (
  title: "Network Error",
  msg: "Sync thinks that you are not connected to the Internet. Check your network and proxy.")

var wv: Webview
var chan: Channel[Message]

proc loop(wv: Webview; blocking: bool): bool =
  ## Wraps the C loop function with proper Booleans.
  wv.loop(blocking.cint).bool

template helperErrHandler(body: untyped): untyped =
  ## Handle exceptions properly in a helper thread.
  ## Any error message will be sent over the channel.
  ## **Exceptions that escape into this template
  ## display a dialog and then crash the process**.
  try:
    body
  except:
    try:
      chan.send(initMessageExitFailure(getCurrentExceptionMsg()))
    except:
      echo "Error sending exception message over channel. This is a bug!"

proc checkInternet() {.raises: [].} =
  ## Checks the connection to the Internet by pinging
  ## a site that should always be online.
  helperErrHandler:
    sleep(4000)
    chan.send(initMessageInetErr())

proc doDownload() =
  discard

proc doUpload() =
  discard

proc main() =
  # Init the GUI.
  wv = newWebView("Sync", "file://" & getCurrentDir() & "/web/index.html", resizable = false)
  # Prepare for multithreaded communications.
  chan.open()

  try:
    # Attach Nim callbacks to the HTML5 Events in the GUI.
    # See the "on*" event attributes in the HTML source.
    wv.bindProcs("api"):
      proc download() = doDownload()
      proc upload() = doUpload()

    # The first helper checks the Internet connection.
    spawn checkInternet()

    # Loop until the user exits or the loop is broken.
    while not wv.loop(true):
      # The channel controls the delivery of information
      # from the helpers to the main thread.
      let info = chan.tryRecv()
      if info.dataAvailable:
        case info.msg.kind:
        of mkInetOk:
          # The Internet connection test succeeded.
          # Proceed with execution.
          break
        of mkInetErr:
          # The Internet connection test failed.
          # Break and quit.
          echo inetError.msg
          wv.error(inetError.title, inetError.msg)
          break
        of mkExitFailure:
          # A helper threw an exception.
          # Print the error, display a dialog, and break the loop.
          let errBody = "The worker thread crashed! Exception message: " &
            info.msg.exceptionMsg
          echo errBody
          wv.error("Exception", errBody)
          break
  finally:
    # Clean up native resources.
    echo "Cleaning Up"
    chan.close()
    wv.exit()
    echo "Goodbye"

when isMainModule:
  main()

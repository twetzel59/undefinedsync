import std / [ httpclient, os, strutils, threadpool ]
from net import TimeoutError
import webview

type
  WebviewEvalError = object of Exception ## An error that can occur on Windows
                                         ## when eval encounters an internal
                                         ## implementation-specific issue.

  MessageKind = enum ## Indicates the type of message
    mkServerOk,      ## sent over the channel.
    mkServerTimeout,
    mkServerWrongProtocol,
    mkServerError,
    mkExitFailure
  
  Message = object ## A complete message.
    case kind: MessageKind:
    of mkExitFailure:
      exceptionMsg: string
    of mkServerError:
      serverErrorMsg: string
    else:
      discard

const server = "https://undefinedsync.000webhostapp.com" ## The URL of the central
                                                         ## checkout control server.

const serverReply = "undefinedSync_proto0" ## The reply the server should send if it 
                                           ## is compatible.

const serverError = "undefinedSync_error0;" ## The server's reply should start with this
                                            ## string if an error occurred. More information
                                            ## can follow in the response after the semicolon.
const serverErrorSplitChar = ';' ## The character to split the server's error reply with.
                                 ## The second string resulting from the split will contain
                                 ## any additional error information the server replied with.

const timeoutNotice = (
  title: "Network Error",
  msg: "Sync thinks that you are not connected to the server." &
    " Check your network and proxy or contact a server admin.")

const wrongProtoNotice = (
  title: "Protocol Error",
  msg: "Sync determined that the central server is malfunctioning" &
    " or does not support this version of Sync. Please contact a server admin."
)

const serverErrorNotice = (
  title: "Server Error",
  msg: "Sync connected to the central server, but the server" &
    " encountered an error. Please contact a server admin. Server response: "
)

const timeoutMillis = 4096 ## Time before the HTTP retrieval gives up (milliseconds).

var wv: Webview
var chan: Channel[Message]

proc loopWrapper(wv: Webview; blocking: bool): bool =
  ## Wraps the C loop function with proper Booleans.
  webview.loop(wv, blocking.cint).bool

proc evalWrapper(wv: Webview, javascriptCode: string) {.raises: [WebviewEvalError].} =
  ## Wraps the C eval function to handle return value
  ## that only matters on Windows.
  if webview.eval(wv, javascriptCode) == -1:
    raise newException(WebviewEvalError, "The Webview C library returned -1. This indicates a bug or OOM.")

template helperErrHandler(body: untyped): untyped =
  ## Handle exceptions properly in a helper thread.
  ## Any error message will be sent over the channel.
  ## **Exceptions that escape into this template
  ## display a dialog and then crash the process**.
  try:
    body
  except:
    try:
      chan.send(Message(kind: mkExitFailure, exceptionMsg: getCurrentExceptionMsg()))
    except:
      echo "Error sending exception message over channel. This is a bug!"

proc checkServer() {.raises: [].} =
  ## Checks the connection to the server by pinging
  ## it and checking the reply
  helperErrHandler:
    try:
      let client = newHttpClient(timeout = timeoutMillis)
      let content = client.getContent(server & "/ping.php")
      
      if content == serverReply:
        chan.send(Message(kind: mkServerOk))
      else:
        if content.startsWith(serverError):
          let pieces = content.split(serverErrorSplitChar)
          let errorMsg = serverErrorNotice.msg & pieces[1]

          chan.send(Message(kind: mkServerError, serverErrorMsg: errorMsg))
        else:
          chan.send(Message(kind: mkServerWrongProtocol))
    except TimeoutError:
      chan.send(Message(kind: mkServerTimeout))

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

    # The first helper checks the connection to the server.
    spawn checkServer()

    # Loop until the user exits or the loop is broken.
    while not wv.loopWrapper(true):
      # The channel controls the delivery of information
      # from the helpers to the main thread.
      let info = chan.tryRecv()
      if info.dataAvailable:
        case info.msg.kind:
        of mkServerOk:
          # The server connection test succeeded.
          # Proceed with execution.
          wv.evalWrapper("displayMain();")
        of mkServerTimeout:
          # The server connection test failed.
          # Break and quit.
          echo timeoutNotice.msg
          wv.error(timeoutNotice.title, timeoutNotice.msg)
          break
        of mkServerWrongProtocol:
          # The server did not return the magic
          # string stored in the const serverReply.
          # It is considered incompatible.
          # Break and quit.
          echo wrongProtoNotice.msg
          wv.error(wrongProtoNotice.title, wrongProtoNotice.msg)
          break
        of mkServerError:
          # The server encountered an error
          # processing our request.
          # Report the server's error message
          # to the user, then break and quit.
          echo info.msg.serverErrorMsg
          wv.error(serverErrorNotice.title, info.msg.serverErrorMsg)
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

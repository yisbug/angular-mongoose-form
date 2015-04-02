# 当前js路径
js = document.scripts
filePath = js[js.length-1].src
checkBrowser = ->
    doCheck = ->
        agent = navigator.userAgent
        return if not /MSIE [6|7|8]{1}\.0/.test agent
        window.location.href = filePath.replace /browser\.js$/ig,'update.html'
    win = window
    eventName = 'load'
    if win.addEventListener
        win.addEventListener eventName,doCheck,false
    else if win.attachEvent
        win.attachEvent 'on'+eventName,doCheck
    else
        win['on'+eventName]=doCheck

checkBrowser()
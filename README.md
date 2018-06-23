# clockbot

**This is just an experiment so please don't actually use it for anything!**

This repo illustrates how to make a really simple Slack bot using [ArgyleKit](https://github.com/boundsj/ArgyleKit)

```Swift
let rtm = SlackRTMClient(token: token)
rtm.start()
rtm.on(event: .message) { (rtm, response) in
    guard response.json.contains("time"), let channel = response.channel else {
        return
    }
    rtm.sendMessage(channel: channel, text: "Hello, it is \(Date().description)")
}
```

![example](https://s3.amazonaws.com/rebounds.argyle/Screenshot+2018-06-23+16.53.11.png)

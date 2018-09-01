import Foundation
import ArgyleKit

guard let token = ProcessInfo.processInfo.environment["token"] else {
    fatalError("Could not find a token!")
}

let rtm = SlackRTMClient(token: token)

rtm.on(event: .message) { (rtm, response) in
    guard response.json.contains("time"), let channel = response.channel else {
        return
    }
    rtm.sendMessage(channel: channel, text: "Hello, it is \(Date().description)")
}

rtm.start()

dispatchMain()

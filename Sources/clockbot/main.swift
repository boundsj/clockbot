import Foundation
import WebSocket

class HTTPService {

    class func connect(token: String, completion: @escaping (_ websocketString: String) -> () ) {
        let url = URL(string: "https://slack.com/api/rtm.connect?token=\(token)")!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                fatalError()
            }

            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String : Any] else {
                    fatalError()
                }

                guard let websocketURLString = json["url"] as? String else {
                    fatalError()
                }

                completion(websocketURLString)
            } catch {
                fatalError()
            }

        }
        task.resume()
    }

}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
        let idx2 = index(startIndex, offsetBy: min(self.count, range.upperBound))
        return String(self[idx1..<idx2])
    }
}

var messageId = 1
let worker = MultiThreadedEventLoopGroup(numberOfThreads: 1)

guard let token = ProcessInfo.processInfo.environment["token"] else {
    fatalError("Could not find a token!")
}

HTTPService.connect(token: token) { websocketString in
    print("Connecting with: \(websocketString)")

    let socket = "/websocket/"
    var hostname = websocketString.components(separatedBy: socket)[0]
    hostname = hostname[6..<hostname.count]
    let path = websocketString.components(separatedBy: socket)[1]

    let ws = try! HTTPClient.webSocket(scheme: .wss,
                                       hostname: hostname,
                                       path: "\(socket)\(path)",
                                       on: worker).wait()

    ws.onText { wsIn, text in
        print(text)
        if text == "{\"type\": \"hello\"}" { return }

        if text.contains("time") {
            var response: Dictionary = [String: Any]()
            response["type"] = "message"
            response["channel"] = "C03BMRQLA"
            response["text"] = "Hello, it is \(Date().description)"
            response["id"] = messageId
            
            let responseJSON = try! JSONSerialization.data(withJSONObject: response)
            let string = String(data: responseJSON, encoding: String.Encoding.utf8)!
            print("=====> sending: \(string)")
            wsIn.send(text: string) 
            messageId = messageId + 1
        }
    }

    ws.onCloseCode { code in
        print("code: \(code)")
    }

    ws.onError { (_, error) in
        print(error)
    }
}

dispatchMain()

//ws.close(code: .normalClosure)

//let promise = worker.eventLoop.newPromise(String.self)
//promise.succeed(result: text)

//var loopUntil = Date(timeIntervalSinceNow: 0.1)
//while true && RunLoop.current.run(mode: .defaultRunLoopMode, before: loopUntil) {
//    loopUntil = Date(timeIntervalSinceNow: 0.1)
//}

import Foundation
import WebSocket

// Bot library

class HTTPService {

    static let rtmConnectURLTemplate = "https://slack.com/api/rtm.connect?token=%@"

    class func connect(token: String, completion: @escaping (_ websocketString: String) -> () ) {
        let urlString = String(format: rtmConnectURLTemplate, token)
        let url = URL(string: urlString)!
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

public class SlackRTMClient {

    let token: String

    private var messageId = 1
    private let worker = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private var websocket: WebSocket?

    init(token: String) {
        self.token = token
    }

    func start() {

        HTTPService.connect(token: token) { websocketString in
            print("Connecting with: \(websocketString)")

            // Parse the host and path for connection received from rtm connect
            let socket = "/websocket/"
            var hostname = websocketString.components(separatedBy: socket)[0]
            hostname = hostname[6..<hostname.count]
            let path = websocketString.components(separatedBy: socket)[1]

            do {
                self.websocket = try HTTPClient.webSocket(scheme: .wss,
                                                          hostname: hostname,
                                                          path: "\(socket)\(path)",
                                                          on: self.worker).wait()
            } catch {
                fatalError("Unexpected error when creating websocket")
            }

            guard let websocket = self.websocket else {
                fatalError("Websocket is not available!")
            }

            websocket.onText { ws, text in
                print(text)
                if text == "{\"type\": \"hello\"}" { return }

                if text.contains("time") {
                    var response: Dictionary = [String: Any]()
                    response["type"] = "message"
                    response["channel"] = "C03BMRQLA"
                    response["text"] = "Hello, it is \(Date().description)"
                    response["id"] = self.messageId

                    let responseJSON = try! JSONSerialization.data(withJSONObject: response)
                    let string = String(data: responseJSON, encoding: String.Encoding.utf8)!
                    print("=====> sending: \(string)")
                    ws.send(text: string)
                    self.messageId += 1
                }
            }

            websocket.onCloseCode { code in
                print("code: \(code)")
            }

            websocket.onError { (_, error) in
                print(error)
            }
        }

    }
}

extension String {

    subscript(_ range: CountableRange<Int>) -> String {
        let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
        let idx2 = index(startIndex, offsetBy: min(self.count, range.upperBound))
        return String(self[idx1..<idx2])
    }

}

/// Bot

guard let token = ProcessInfo.processInfo.environment["token"] else {
    fatalError("Could not find a token!")
}

let rtm = SlackRTMClient(token: token)
rtm.start()
dispatchMain()

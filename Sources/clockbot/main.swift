import Foundation
import WebSocket

// Bot library

public typealias eventHandler = (String) -> Void

public enum EventType: String {
    case connect = "hello"
    case unknown
}

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

struct RTMResponse: Decodable {
    var type: String
    var eventType: EventType {
        get {
            return eventTypeFromType()
        }
    }

    private func eventTypeFromType() -> EventType {
        switch type {
        case "hello":
            return .connect
        default:
            return .unknown
        }
    }
}


public class SlackRTMClient {

    let token: String

    private var messageId = 1
    private let worker = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private var websocket: WebSocket?
    private var eventHandlers = [EventType: eventHandler]()

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

                do {
                    let data = text.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                    let rtmResponse = try JSONDecoder().decode(RTMResponse.self, from: data)
                    if let handler = self.eventHandlers[rtmResponse.eventType] {
                        handler(text)
                    }
                } catch {
                    print("Could not parse json from RTM")
                    return
                }

                if text == "{\"type\": \"hello\"}" { return }
            }

            websocket.onCloseCode { code in
                print("code: \(code)")
            }

            websocket.onError { (_, error) in
                print(error)
            }
        }
    }

    func on(event: EventType, handler: @escaping eventHandler) {
        eventHandlers[event] = handler
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
rtm.on(event: .connect) { (text) in
    print("=====> We've got \(text)")
}

dispatchMain()

//
//  AmbassadorTestCase.swift
//  Ambassador-iOS
//
//  Created by Ankit Goel on 6/7/18.
//  Copyright © 2018 Fang-Pen Lin. All rights reserved.
//

import Foundation
import Embassy

class AmbassadorTestCase: XCTestCase {
    var router: Router!
    var eventLoop: EventLoop!
    var server: HTTPServer!
    var eventLoopThreadCondition: NSCondition!
    var eventLoopThread: Thread!

    override func setUp() {
        super.setUp()
        self.startServer()
    }

    override func tearDown() {
        super.tearDown()
        self.terminateServer()
    }

    func startServer() {
        eventLoop = try! SelectorEventLoop(selector: try! KqueueSelector())
        router = DefaultRouter()
        server = DefaultHTTPServer(eventLoop: eventLoop, port: 8080, app: router.app)

        try! server.start()

        eventLoopThreadCondition = NSCondition()
        eventLoopThread = Thread(target: self, selector: #selector(runEventLoop), object: nil)
        eventLoopThread.start()
    }

    func terminateServer() {
        server.stopAndWait()
        eventLoopThreadCondition.lock()
        eventLoop.stop()
        while eventLoop.running {
            if !eventLoopThreadCondition.wait(until: Date().addingTimeInterval(10)) {
                fatalError("Join eventLoopThread timeout")
            }
        }
    }

    @objc func runEventLoop() {
        eventLoop.runForever()
        eventLoopThreadCondition.lock()
        eventLoopThreadCondition.signal()
        eventLoopThreadCondition.unlock()
    }
}


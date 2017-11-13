//
//  ViewController.swift
//  PubNubSample
//
//  Created by QBurst on 11/07/17.
//  Copyright © 2017 QBurst. All rights reserved.
//

import UIKit
import PubNub

fileprivate let publishKey = "pub-c-6855b23d-e5d1-49f5-b5ce-dd394a8f77d1"
fileprivate let subscribeKey = "sub-c-5dcca50c-653f-11e7-8fcc-0619f8945a4f"

class ViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    var client : PubNub?
    var timer : Timer?
    // this queue below is only for scheduling publishes
    // it won't share resources with anything else and is concurrent
    // so that there will be no delay in scheduling publishes
    let publishQueue = DispatchQueue(label: "PublishQueue", qos: .userInitiated, attributes: [.concurrent])
    // this queue below is only for callbacks
    // it is concurrent so callbacks won't be delayed
    // and is separate from the publish queue so as not to delay either
    let callbackQueue = DispatchQueue(label: "PubNubCallbackQueue", qos: .userInitiated, attributes: [.concurrent])
    
    
    @IBAction func publish(_ sender: Any) {

      let publishStep0 = Date()
       DispatchQueue.main.async {
            let publishStep1 = Date()
            let publishText = self.textField.text ?? "default"
            self.publishQueue.async {
                let publishStep2 = Date()
                self.client?.publish(publishText, toChannel: "my_channel1",
                                     compressed: false, withCompletion: { (status) in
                                        let publishStep3 = Date()
                                        print("****** \(#function) publish steps ******")
                                        print("Step 1: \(#function) => Tap Button: \(publishStep0.stringFormat)")
                                        print("Step 1: \(#function) => Get Text from TextField \(publishStep1.stringFormat)")
                                        print("Step 2: \(#function) => Initiate Publish \(publishStep2.stringFormat)")
                                        print("Step 3: \(#function) => Receive Publish Callback \(publishStep3.stringFormat)")
                                        print("****************************************")
                                        let diff = publishStep3.timeIntervalSince(publishStep2)
                                        print("Step 4: \(#function) => time difference \(diff)")
                                        DispatchQueue.main.async {
                                            self.timeLabel.text = String(diff)
                                        }
                                        if !status.isError {
                                        }
                                        else{
                                            
                                        }
                })
            }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let config = PNConfiguration(publishKey: publishKey, subscribeKey: subscribeKey)
        config.stripMobilePayload = false
        self.client = PubNub.clientWithConfiguration(config, callbackQueue: callbackQueue)
        self.client?.logger.enabled = true
        self.client?.logger.setLogLevel(PNLogLevel.PNVerboseLogLevel.rawValue)
        self.client?.addListener(self)
        self.client?.subscribeToChannels(["my_channel1"], withPresence: false)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Since pubnub client is in View controller, We have used NotificationCenter to get the callback of "UIApplicationDidBecomeActive"
    func establishSSL(){
        DispatchQueue.concurrentPerform(iterations: 10) { (_) in
            self.client?.publish("Establish all 3 ssl connections", toChannel: "AnyChannel", withCompletion: { (status) in
                print("We just published with:")
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(establishSSL), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }

}

// MARK: - PNObjectEventListener
extension ViewController: PNObjectEventListener {
    
    func client(_ client: PubNub, didReceive status: PNStatus) {
        print("Status \(status.category.rawValue)")
    }
    
    func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        
        DispatchQueue.main.async {
            print("$$$$$$$$$$$$$$$$ Message received $$$$$$$$$$$$$$$$")
            //print("message: \(message.debugDescription)")
            print("time: \(Date().stringFormat)")
            print("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")

            let currentText = self.label.text ?? ""
            let appendingText = message.data.message ?? "No text in message"
            self.label.text = currentText.appending(",\(appendingText)")
            self.label.setNeedsLayout()
        }
        
    }
    
    func client(_ client: PubNub, didReceivePresenceEvent event: PNPresenceEventResult) {
        // This most likely won't be used here, but in any relevant view controllers
    }
    
    
}

extension Date {
    
    static var formatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSSSz"
        return dateFormatter
    } ()
    
    var stringFormat: String {
        return Date.formatter.string(from: self)
    }
    
}





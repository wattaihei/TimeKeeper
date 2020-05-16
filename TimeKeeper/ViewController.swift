//
//  ViewController.swift
//  Test2
//
//  Created by 渡辺泰平 on 2020/04/05.
//  Copyright © 2020 渡辺泰平. All rights reserved.
//

import UIKit
import RealmSwift


class ViewController: UIViewController {
    var startTime : Double = Double()
    var tmpTime : Double = Double()
    var deltaTime : Double = Double()
    var timer = Timer()
    var mustStart : Bool = true
    
    //var realmData = RealmTime()
    
    override func viewDidLoad(){
        super.viewDidLoad()
        //if let fileURL = Realm.Configuration.defaultConfiguration.fileURL {
            //try! FileManager.default.removeItem(at: fileURL)
        //}
        mustStart = isStart()
        if (!mustStart){
            timer = Timer.scheduledTimer(timeInterval: 1/100, target: self, selector: #selector(stopwatch), userInfo: nil, repeats: true)
        }
        reloadButton()
    }
    
    func reloadText(){
        let hour = Int(deltaTime) / 3600
        let min = Int(deltaTime)%3600 / 60
        let sec = Int(deltaTime) % 60
        let hourText = String(format: "%02d", hour)
        let minText = String(format: "%02d", min)
        let secText = String(format: "%02d", sec)
        label.text = hourText + ":" + minText + ":" + secText
    }
    
    func reloadButton(){
        var image = UIImage(systemName: "stop.circle.fill")
        if (mustStart){
            image = UIImage(systemName: "play.circle.fill")
        }
        let state = UIControl.State.normal
        ButtonImage.setBackgroundImage(image, for: state)
    }
    
    @objc func stopwatch(){
        tmpTime = NSDate.timeIntervalSinceReferenceDate
        deltaTime = tmpTime - startTime
        reloadText()
    }
    
    func isStart() -> Bool{
        let realm = try! Realm()
        let realmTable = realm.objects(RealmTime.self).sorted(byKeyPath: "StartTime")
        if (realmTable.count == 0){
            return true
        }
        let lastData = realmTable.last!
        if (lastData.EndTime > 1.0){
            return true
        }
        startTime = lastData.StartTime
        return false
    }
    

    @IBOutlet weak var ButtonImage: UIButton!
    @IBOutlet weak var label: UILabel!

    
    @IBAction func button(_ sender: Any) {
        if (mustStart){
            startTime = NSDate.timeIntervalSinceReferenceDate
            timer = Timer.scheduledTimer(timeInterval: 1/100, target: self, selector: #selector(stopwatch), userInfo: nil, repeats: true)
            let newRow = RealmTime()
            newRow.StartTime = startTime
            //print(newRow)
            let realm = try! Realm()
            print(realm.objects(RealmTime.self))
            try! realm.write{
                realm.add(newRow)
            }
            mustStart = false
            reloadButton()
        } else {
            timer.invalidate()
            
            let realm = try! Realm()
            let lastRow = realm.objects(RealmTime.self).sorted(byKeyPath: "StartTime").last!
            
            // 日毎に分割
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.locale = Locale(identifier: "ja_JP")
            var todayStart = formatter.date(from: formatter.string(from: Date(timeIntervalSinceReferenceDate: tmpTime)))!.timeIntervalSinceReferenceDate
            var recordingTime = tmpTime
            while (todayStart > lastRow.StartTime){
                let newRow = RealmTime()
                newRow.EndTime = recordingTime
                newRow.StartTime = todayStart
                try! realm.write{
                    realm.add(newRow)
                }
                recordingTime = todayStart - 1
                todayStart -= 60*60*24
            }
            try! realm.write{
                lastRow.EndTime = recordingTime;
            }
            mustStart = true
            reloadButton()
        }
    }
}

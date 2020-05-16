//
//  DataViewController.swift
//  Test2
//
//  Created by 渡辺泰平 on 2020/04/07.
//  Copyright © 2020 渡辺泰平. All rights reserved.
//

import UIKit
import Charts
import RealmSwift

class DataViewController : UIViewController, UITabBarDelegate {
    var chart: CombinedChartView!
    var lineDataSet: LineChartDataSet!
    var bubbleDataSet: BubbleChartDataSet!
    var labelString: String = ""
    var formatArray : [String] = Array()
    
    var length : Int = 7
    var page : Int = 0
    var datakind : Int = 0
    
    func hiddenItems(isHidden : Bool){
        pageStepper.isHidden = isHidden
        Switch.isHidden = isHidden
        TabBar.isHidden = isHidden
    }
    
    @IBOutlet weak var GraphView: LineChartView!
    
    @IBOutlet weak var Switch: UISegmentedControl!
    @IBAction func SwitchAction(_ sender: UISegmentedControl) {
        //hiddenItems(isHidden: true)
        let entries = createEntries()
        generateLineData(entries: entries)
        //hiddenItems(isHidden: false)
    }
    
    
    @IBAction func pageIncrementer(_ sender: UIStepper) {
        //hiddenItems(isHidden: true)
        page = Int(sender.value)
        let entries = createEntries()
        generateLineData(entries: entries)
        //hiddenItems(isHidden: false)
    }
    @IBOutlet weak var pageStepper: UIStepper!
    
    @IBOutlet weak var TabBar: UITabBar!
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        switch item.tag{
        case 0:
            length = 7
            page = 0
            pageStepper.value = 0
            datakind = 0
            let entries = createEntries()
            generateLineData(entries: entries)
        case 1:
            length = 5
            page = 0
            pageStepper.value = 0
            datakind = 1
            let entries = createEntries()
            generateLineData(entries: entries)
        case 2:
            length = 6
            page = 0
            pageStepper.value = 0
            datakind = 2
            let entries = createEntries()
            generateLineData(entries: entries)
        case 3:
            length = 5
            page = 0
            pageStepper.value = 0
            datakind = 3
            let entries = createEntries()
            generateLineData(entries: entries)
        default : return
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TabBar.delegate = self
        TabBar.selectedItem = TabBar.items![0]
        let entries = createEntries()
        generateLineData(entries: entries)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let entries = createEntries()
        generateLineData(entries: entries)
    }
    
    func defineYmax(entries : [ChartDataEntry], Interval : Int) -> Double {
        var ymax : Double = 0
        for entry in entries {
            if (entry.y > ymax){
                ymax = entry.y
            }
        }
        return Double((Int(ymax+Double(Interval)-1)/Interval+1)*Interval)
    }
    
    func generateLineData(entries: [ChartDataEntry]){

        var lineData : [LineChartDataSet] = Array()
        lineDataSet = LineChartDataSet(entries)
        lineDataSet.valueFormatter = LineChartValueFormatter()
        lineDataSet.valueFont = UIFont.systemFont(ofSize: 11)
        lineData.append(lineDataSet)
        // 前のlabelが残ってるとエラーになる
        GraphView.xAxis.valueFormatter = nil
        
        // Draw
        GraphView.data = LineChartData(dataSets: lineData)
        GraphView.rightAxis.enabled = false
        GraphView.leftAxis.labelFont = UIFont.systemFont(ofSize: 11)
        GraphView.leftAxis.drawGridLinesEnabled = true
        GraphView.leftAxis.axisMinimum = 0
        GraphView.leftAxis.axisMaximum = defineYmax(entries: entries, Interval: 6)
        GraphView.leftAxis.granularityEnabled = true
        GraphView.leftAxis.granularity = 1.0
        GraphView.leftAxis.labelCount = 7
        GraphView.leftAxis.valueFormatter = LineChartYFormatter()

        GraphView.xAxis.labelCount = entries.count - 1
        GraphView.xAxis.axisMaximum = Double(entries.count-1) + 0.4
        GraphView.xAxis.axisMinimum = -0.4
        GraphView.xAxis.granularity = 1.0
        GraphView.xAxis.granularityEnabled = true
        GraphView.xAxis.labelPosition = .bottom
        GraphView.xAxis.labelFont = UIFont.systemFont(ofSize: 11)
        
        let lineXformatter = LineChartXFormatter()
        lineXformatter.FormatArray = self.formatArray
        GraphView.xAxis.valueFormatter = lineXformatter
        
        GraphView.legend.enabled = false
    }

    func searchRealm(StartTime : Double, EndTime : Double) -> Double {
        let realm = try! Realm()
        let realmData = realm.objects(RealmTime.self).filter("EndTime >= " + String(StartTime) + "AND StartTime <= " + String(EndTime))
        var sumTime : Double = 0
        for row in realmData{
            sumTime += min(row.EndTime, EndTime) - max(row.StartTime, StartTime)
        }
        return sumTime
    }
    
    func createEntries() -> [ChartDataEntry]{
        let funcprob : [(Int) -> Double] = [generateDay, generateWeek, generateMonth, generateYear]
        let generatefunc = funcprob[datakind]
        var sumTime : Double
        var entries : [ChartDataEntry] = Array()
        self.formatArray = Array()
        for i in 0..<length{
            // labelString はStartに合わせる
            var end = generatefunc(length-1-i-1-page*length)
            let start = generatefunc(length-1-i-page*length)
            self.formatArray.append(labelString)

            sumTime = searchRealm(StartTime: start, EndTime: end)
            
            // Mean表示用
            if (Switch.selectedSegmentIndex == 1){
                if (i == length-1){
                    end = generateDay(delta: 0) + 60*60*24
                }
                let days = (end - start)/(60*60*24)
                sumTime /= days
            }
            entries.append(ChartDataEntry(x: Double(i), y: sumTime/3600))

        }
        return entries
    }
    
    
    
    func generateDay(delta: Int) -> Double {
        let nowTimestamp = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "ja_JP")
        let timestamp = Date(timeInterval: -Double(delta*60*60*24), since: nowTimestamp)
        let retString = formatter.string(from: timestamp)
        
        let labelformatter = DateFormatter()
        labelformatter.locale = Locale(identifier: "ja_JP")
        labelformatter.dateFormat = "M/d(EE)"
        labelString = labelformatter.string(from: timestamp)
        
        let today = formatter.date(from: retString)
        return today!.timeIntervalSinceReferenceDate
    }
    
    func generateWeek(delta: Int) -> Double {
        let nowTimestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEEEE", options: 0, locale: Locale(identifier: "ja_JP"))
        formatter.locale = Locale(identifier: "ja_JP")
        let weekString = formatter.string(from: nowTimestamp)
        
        let weeks = ["月","火","水","木","金","土","日"]
        //print(weekString)
        let weekindex = weeks.firstIndex(of: weekString)!
        //print(weekindex)
        
        let timestamp = Date(timeInterval: Double(-60*60*24*(weekindex+delta*7)), since: nowTimestamp)
        let labelformatter = DateFormatter()
        labelformatter.locale = Locale(identifier: "ja_JP")
        labelformatter.dateFormat = "M/d"
        labelString = labelformatter.string(from: timestamp) + "~"
        
        formatter.dateStyle = .full
        let retString = formatter.string(from: timestamp)
        let retDay = formatter.date(from: retString)
        return retDay!.timeIntervalSinceReferenceDate
    }
    
    func generateMonth(delta: Int) -> Double {
        let nowTimestamp = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyy", options: 0, locale: Locale(identifier: "ja_JP"))
        let yearString = formatter.string(from: nowTimestamp)
        
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MM", options: 0, locale: Locale(identifier: "ja_JP"))
        let monthString = formatter.string(from: nowTimestamp)
        
        var year = Int(yearString.prefix(4))!
        var month = Int(monthString.prefix(2))! - delta
        
        var deltayear = (month - 1)/12
        if ((month-1)%12 < 0){
            deltayear -= 1
        }
        month -= deltayear*12
        year += deltayear
        
        labelString = String(year) + "/" + String(month)

        let todayString = String(format: "%04d", year) + "/" + String(format: "%02d", month) + "/" + "01"
        
        formatter.dateFormat = "yyyy/MM/dd"
        let today = formatter.date(from: todayString)
        return today!.timeIntervalSinceReferenceDate
    }
    
    func generateYear(delta: Int) -> Double{
        let nowTimestamp = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyy", options: 0, locale: Locale(identifier: "ja_JP"))
        let yearString = formatter.string(from: nowTimestamp)
        let year = Int(yearString.prefix(4))! - delta
        
        let todayString = String(format: "%04d", year) + "/01/01"
        
        labelString = String(format: "%04d", year)
        
        formatter.dateFormat = "yyyy/MM/dd"
        let today = formatter.date(from: todayString)
        return today!.timeIntervalSinceReferenceDate
    }
    
}


public class LineChartValueFormatter: NSObject, IValueFormatter{
    public func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String{
        let hour = Int(entry.y)
        let minute = Int((entry.y - Double(hour))*60)
        return String(hour) + " h " + String(minute) + " m"
    }
}

public class LineChartYFormatter: NSObject, IAxisValueFormatter{
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return String(Int(value)) + "h"
    }
}

public class LineChartXFormatter: NSObject, IAxisValueFormatter{
    var FormatArray : [String] = Array()
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return self.FormatArray[Int(value)]
    }
}

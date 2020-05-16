//
//  DataStoreController.swift
//  TimeKeeper
//
//  Created by 渡辺泰平 on 2020/05/02.
//  Copyright © 2020 渡辺泰平. All rights reserved.
//

import UIKit
import RealmSwift

// データ描画部
class DataStoreController : UITableViewController {
    let maxCell : Int = 30
    var cellViewArray : [String] = Array()
    var realmIndex : Int = 0
    var deletingdayLabel : String = ""
    var deletingtimeLabel : String = ""
    
    
    override func viewDidLoad(){
        super.viewDidLoad()
        generateCellViewArray()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        generateCellViewArray()
        self.tableView.reloadData()
    }
    
    
    
    // 描画部
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellViewArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得する
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath)
        // セルに表示する値を設定する
        cell.textLabel!.text = cellViewArray[indexPath.row]
        return cell
    }
    
    
    
    // 直近maxcell個のデータ取得
    func generateCellViewArray () {
        cellViewArray = Array()
        let realm = try! Realm()
        let realmTable = realm.objects(RealmTime.self).sorted(byKeyPath: "StartTime")
        let realmData = realmTable.suffix(maxCell)
        for row in realmData.reversed() {
            if (row.EndTime < 1.0){
                continue
            }
            cellViewArray.append(RealmToString(realmRow: row))
        }
    }
    
    func RealmToString(realmRow : RealmTime) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 (EE)"
        formatter.locale = Locale(identifier: "ja_JP")
        let startDayString = formatter.string(from: Date(timeIntervalSinceReferenceDate: realmRow.StartTime))
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let startTimeString = formatter.string(from: Date(timeIntervalSinceReferenceDate: realmRow.StartTime))
        let endTimeString = formatter.string(from: Date(timeIntervalSinceReferenceDate: realmRow.EndTime))
        deletingdayLabel = startDayString
        deletingtimeLabel = startTimeString + " ~ " + endTimeString
        return deletingdayLabel + " " + deletingtimeLabel
    }
    
    // cellが押されたときの遷移
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let realm = try! Realm()
        let realmTable = realm.objects(RealmTime.self).sorted(byKeyPath: "StartTime")
        
        realmIndex = realmTable.count - indexPath.row - 1
        if (realmTable.last!.EndTime < 1.0){
            realmIndex -= 1
        }
        RealmToString(realmRow: realmTable[realmIndex])
        // Segueを使った画面遷移を行う関数
        performSegue(withIdentifier: "DeleteSegue", sender: nil)
    }
    
    // 遷移先にデータを渡す
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DeleteSegue" {
            let vc = segue.destination as! DeleteDataController
            vc.realmIndex = realmIndex
            vc.deletingdayLabel = deletingdayLabel
            vc.deletingtimeLabel = deletingtimeLabel
        }
    }
    
}

// データ削除部
class DeleteDataController : UIViewController {
    
    var realmIndex : Int = 0
    var deletingdayLabel : String = ""
    var deletingtimeLabel : String = ""
    
    @IBOutlet weak var DayLabel: UILabel!
    @IBOutlet weak var TimeLabel: UILabel!
    
    @IBOutlet weak var askquery: UILabel!
    override func viewDidLoad(){
        super.viewDidLoad()
        DayLabel.text = deletingdayLabel
        TimeLabel.text = deletingtimeLabel
        askquery.text = "このデータを削除しますか？"
    }
    
    @IBAction func deleteButton(_ sender: Any) {
        let realm = try! Realm()
        let realmTable = realm.objects(RealmTime.self).sorted(byKeyPath: "StartTime")
        let realmData = realmTable[realmIndex]
        try! realm.write{
            realm.delete(realmData)
        }
        // モーダル遷移したときViewLoadしてくれない
        //let nav = self.presentingViewController as! UINavigationController
        //let vc = nav.viewControllers.last! as! DataStoreController
        //vc.viewDidLoad()

        self.navigationController?.popViewController(animated: true)
        //self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func BackButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
        //self.dismiss(animated: true, completion: nil)
    }
    
}

// データ追加部
class AddDataController : UIViewController{
    
    var FormatHidden : Bool = true
    var isStart : Bool = true
    let defaultDate : Date = Date(timeIntervalSinceReferenceDate: 0)
    var InputStartTime : Date = Date()
    var InputEndTime : Date = Date()
    
    
    @IBOutlet weak var StartTextField: UITextField!
    @IBOutlet weak var EndTextField: UITextField!
    @IBOutlet weak var ErrorMessage: UILabel!
    var DatePicker : UIDatePicker = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DatePicker.datePickerMode = UIDatePicker.Mode.dateAndTime
        DatePicker.locale = Locale(identifier: "ja_JP")
        DatePicker.minuteInterval = 5

        StartTextField.inputView = DatePicker
        StartTextField.inputAccessoryView = generateToolBar(isStart: true)
        EndTextField.inputView = DatePicker
        EndTextField.inputAccessoryView = generateToolBar(isStart: false)
        InputStartTime = defaultDate
        InputEndTime = defaultDate
        ErrorMessage.isHidden = true
    }
    
    // toolBarのActionをフィールドによって変える
    func generateToolBar(isStart : Bool) -> UIToolbar {
        let toolBar = UIToolbar(frame: CGRect(x:0, y:0, width: view.frame.size.width, height: 35))
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        var doneItem : UIBarButtonItem
        if (isStart) {
            doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneStart))
        } else {
            doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneEnd))
        }
        toolBar.setItems([spaceItem, doneItem], animated: true)
        return toolBar
    }

    
    // 入力完了
    @objc func doneStart() {
        StartTextField.endEditing(true)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        
        StartTextField.text = formatter.string(from: DatePicker.date)
        InputStartTime = DatePicker.date
    }
    @objc func doneEnd() {
        EndTextField.endEditing(true)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        
        EndTextField.text = formatter.string(from: DatePicker.date)
        InputEndTime = DatePicker.date
    }
    
    // 追加して戻る
    @IBAction func AddAction(_ sender: Any) {
        if (InputStartTime == defaultDate || InputEndTime == defaultDate){
            ErrorMessage.isHidden = false
            ErrorMessage.text = "入力事項が足りません"
        } else if (InputEndTime > Date()) {
            ErrorMessage.isHidden = false
            ErrorMessage.text = "現在より後のデータは追加できません"
        } else if (InputEndTime < InputStartTime) {
            ErrorMessage.isHidden = false
            ErrorMessage.text = "無効なデータです"
        } else {
            let realm = try! Realm()
            let newRow = RealmTime()
            newRow.StartTime = InputStartTime.timeIntervalSinceReferenceDate
            newRow.EndTime = InputEndTime.timeIntervalSinceReferenceDate
            
            // 存在チェック
            let realmData = realm.objects(RealmTime.self).filter("EndTime >= " + String(newRow.StartTime) + "AND StartTime <= " + String(newRow.EndTime))
            if (realmData.count != 0){
                ErrorMessage.text = "重複したデータがあります"
                ErrorMessage.isHidden = false
            } else {
                try! realm.write{
                    realm.add(newRow)
                }
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

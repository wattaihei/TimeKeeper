//
//  RealmTime.swift
//  Test2
//
//  Created by 渡辺泰平 on 2020/04/05.
//  Copyright © 2020 渡辺泰平. All rights reserved.
//

import Foundation
import RealmSwift


class RealmTime : Object {
    @objc dynamic var StartTime : Double = Double()
    @objc dynamic var EndTime : Double = 0.0
}

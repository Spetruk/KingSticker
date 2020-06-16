//
//  Tweak.swift
//  Demo
//
//  Created by Purkylin King on 2020/6/9.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import UIKit

enum TweakType: Int {
    case title
    case toggle
    case slider
    case stepper
}

protocol TweakValueType { }

extension String: TweakValueType { }
extension Bool: TweakValueType { }
extension Double: TweakValueType { }
extension Int: TweakValueType { }

enum TweakValue {
    case title(value: String)
    case toggle(value: Bool)
    case slider(value: Double)
    case stepper(value: Int)
}

protocol Tweakable {
    associatedtype ValueType
    
    var name: String { get }
    var type: TweakType { get }
    var value: ValueType { get set }
}

struct TitleTweak: Tweakable {
    let name: String
    let type: TweakType = .title
    var value: String
}

struct ToggleTweak: Tweakable {
    typealias ValueType = Bool

    let type: TweakType = .toggle
    let name: String
    var value: ValueType
}

struct SliderTweak: Tweakable {
    let type: TweakType = .slider
    let name: String
    var value: Double
    let min: Double
    let max: Double
}

struct StepperTweak: Tweakable {
    let type: TweakType = .stepper
    let name: String
    var value: Int
    let min: Int
    let max: Int
    let step: Int
}

struct AnyTweak<T: TweakValueType>: Tweakable {
    var value: T
    
    var name: String
    var type: TweakType
    
    init<D: Tweakable>(wrappedObject: D) where D.ValueType == T {
        self.value = wrappedObject.value
        self.name = wrappedObject.name
        self.type = wrappedObject.type
    }
}

func t() {
    let obj = AnyTweak(wrappedObject: ToggleTweak(name: "dd", value: true))
    let obj2 = AnyTweak(wrappedObject: TitleTweak(name: "Angel", value: "Haha"))
    let arr = [obj, obj2]
}

struct TweakGroup {
    var name: String
    
    var items: [AnyTweak]
}

class TweakStore {
    public static let shared = TweakStore()
    private init() { }
    
    private(set) var tweaks = [TweakGroup]()
    
    private var tmpTweaks = [TweakGroup]()
    private var defaultItems = [Tweakable]()
    private var defaultSectionName = "Annonymous"
    
    public func add(section: TweakGroup) {
        let names = tmpTweaks.map { $0.name }
        if names.contains(section.name) {
            print("Warnning: The name \(section.name) has exists")
        } else {
            self.tmpTweaks.append(section)
        }
    }
    
    public func add(tweaks: [Tweakable]) {
        for tweak in tweaks {
            let names = defaultItems.map { $0.name }
            if names.contains(tweak.name) {
                print("Warnning: The name \(tweak.name) has exists")
                continue
            } else {
                self.defaultItems.append(tweak)
            }
        }
    }
    
    public func build() {
        if defaultItems.count > 0 {
            tweaks.append(TweakGroup(name: defaultSectionName, items: defaultItems))
        }
        
        tweaks.append(contentsOf: tmpTweaks)
        print("Build tweak finished")
    }
    
    public func resolve<T: Tweakable>(key: String) -> T? {
        let components = key.trimmingCharacters(in: .whitespaces).split(separator: ".").map { String($0) }
        guard components.count > 0 else { fatalError("Invalid key: \(key)") }
        
        var sectionName = defaultSectionName
        var itemName = components[0]
        
        if components.count > 1 {
            sectionName = components[0]
            itemName = components[1]
        }
        
        guard let section = tweaks.first(where: { section -> Bool in
            return section.name == sectionName
        }) else {
            print("Error: Can not find section: \(sectionName)")
            return nil
        }
        
        guard let item = section.items.first(where: { item -> Bool in
            return item.name == itemName
        }) else {
            print("Error: Can not find item: \(itemName)")
            return nil
        }

        return item as? T
    }
}


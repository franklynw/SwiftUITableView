//
//  TableViewContextMenuItem.swift
//  HandyList
//
//  Created by Franklyn Weber on 25/01/2021.
//

import SwiftUI


struct TableViewContextMenuItem: Identifiable {
    
    let id: String
    let title: String
    let iconName: Image.SystemName?
    let shouldAppear: ((String) -> Bool)
    let action: ((String) -> ())?
    
    let itemType: MenuItemType
    
    enum MenuItemType: Equatable {
        case button
        case menu(subMenuItems: (String) -> [TableViewContextMenuItem])
        
        static func == (lhs: MenuItemType, rhs: MenuItemType) -> Bool {
            switch (lhs, rhs) {
            case (.button, .button), (.menu, .menu):
                return true
            default:
                return false
            }
        }
        
        var isButton: Bool {
            if case .button = self {
                return true
            }
            return false
        }
        var isMenu: Bool {
            if case .menu = self {
                return true
            }
            return false
        }
        
        fileprivate func subMenuItems(parentId: String) -> [TableViewContextMenuItem] {
            switch self {
            case .button:
                return []
            case .menu(let subMenuItems):
                return subMenuItems(parentId)
            }
        }
    }
    
    
    init(title: String, iconName: Image.SystemName? = nil, shouldAppear: ((String) -> Bool)? = nil, action: @escaping (String) -> ()) {
        id = UUID().uuidString
        itemType = .button
        self.title = title
        self.iconName = iconName
        self.shouldAppear = shouldAppear ?? { _ in return true }
        self.action = action
    }
    
    init(title: String, iconName: Image.SystemName? = nil, shouldAppear: ((String) -> Bool)? = nil, subMenuItems: @escaping (String) -> [TableViewContextMenuItem]) {
        id = UUID().uuidString
        itemType = .menu(subMenuItems: subMenuItems)
        self.title = title
        self.iconName = iconName
        self.shouldAppear = shouldAppear ?? { _ in return true }
        action = nil
    }
    
    func button(itemId: String) -> AnyView {
        
        if shouldAppear(itemId) == true {
            
            let button = Button(action: {
                self.action?(itemId)
            }) {
                Text(self.title)
                If(self.iconName != nil) {
                    Image(self.iconName!)
                }
            }
            
            return AnyView(button)
        }
        
        return AnyView(EmptyView())
    }
    
    func menu(itemId: String) -> AnyView {
        
        if shouldAppear(itemId) {
            
            let menu = Menu {
                ForEach(self.itemType.subMenuItems(parentId: itemId)) { menuItem in
                    If(menuItem.itemType.isButton) {
                        menuItem.button(itemId: itemId)
                    }
                    If(menuItem.itemType.isMenu) {
                        menuItem.menu(itemId: itemId)
                    }
                }
            } label: {
                Label(self.title, imageSystemName: iconName ?? .chevronRight)
            }
            
            return AnyView(menu)
        }
        
        return AnyView(EmptyView())
    }
}

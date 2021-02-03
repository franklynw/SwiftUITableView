//
//  Handy.TableView+Actions.swift
//  HandyList
//
//  Created by Franklyn Weber on 22/01/2021.
//

import SwiftUI


extension TableView {
    
    private var tableView: TableViewController<V> {
        return tableViewControllerWrapper.tableViewController
    }
    
    func rightBarItem(_ imageName: Image.SystemName, action: @escaping () -> ()) -> Self {
        tableView.setRightItemAction(imageName, action: action)
        return self
    }
    
    func leftBarItem(_ imageName: Image.SystemName, action: @escaping () -> ()) -> Self {
        tableView.setLeftItemAction(imageName, action: action)
        return self
    }
    
    func onTapped(perform action: @escaping (String) -> ()) -> Self {
        tableView.setTappedAction(action)
        return self
    }
    
    func onEdit(perform action: @escaping (String) -> ()) -> Self {
        tableView.setEditAction(action)
        return self
    }
    
    func onDelete(perform action: @escaping (String) -> ()) -> Self {
        tableView.setDeleteAction(action)
        return self
    }
    
    func additionalContextMenuItems(_ items: [TableViewContextMenuItem]) -> Self {
        tableView.setAdditionalContextMenuItems(items)
        return self
    }
    
    func onMove(perform action: @escaping (Int, Int) -> ()) -> Self {
        tableView.setMoveAction(action)
        return self
    }
    
    func titleColor(_ color: Published<UIColor>.Publisher? = nil) -> Self {
        tableView.setTitleColor(color)
        return self
    }
    
    func titleBarColor(_ color: Published<UIColor>.Publisher? = nil) -> Self {
        tableView.setTitleBarColor(color)
        return self
    }
    
    func rowSpacing(_ spacing: CGFloat) -> Self {
        tableView.setSpacing(spacing)
        return self
    }
    
    func rowReorderEnabled(_ enabled: Published<Bool>.Publisher) -> Self {
        tableView.setRowReorderEnabled(enabled)
        return self
    }
    
    func reload(_ reload: Published<Bool>.Publisher, done: (() -> ())? = nil) -> Self {
        tableView.reload(reload, done: done)
        return self
    }
    
    // TODO: in-progress, doesn't work properly yet
    /*
    func titleAction(title: String, action: @escaping () -> ()) -> Self {
        tableView.setTitleAction(title: title, action: action)
        return self
    }
    */
}

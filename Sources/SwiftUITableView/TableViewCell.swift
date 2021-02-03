//
//  TableViewCell.swift
//  HandyList
//
//  Created by Franklyn Weber on 19/01/2021.
//

import SwiftUI


extension TableView {
    
    class TableViewCell<V: TableIdentifiableView>: UITableViewCell {
        
        typealias ItemIdentifier = String
        
        private var itemIdentifier: ItemIdentifier!
        
        
        func configure(with listItemView: V, spacing: CGFloat, tapped: ((ItemIdentifier) -> ())?, edit: ((ItemIdentifier) -> ())?, delete: ((ItemIdentifier) -> ())?, additionalContextMenuItems: [TableViewContextMenuItem]) {
            
            selectionStyle = .none
            
            let viewWithTap = listItemView
                .onTapGesture {
                    tapped?(listItemView.id)
                }
                .contextMenu(menuItems: {
                    
                    If(edit != nil) {
                        Button(action: {
                            edit?(listItemView.id)
                        }, label: {
                            Text(LocalizedStringKey("Edit"))
                            Image(.pencil)
                        })
                    }
                    
                    If(delete != nil) {
                        Button(action: {
                            delete?(listItemView.id)
                        }, label: {
                            Text(LocalizedStringKey("Delete"))
                            Image(.trash)
                        })
                    }
                    
                    ForEach(additionalContextMenuItems) { menuItem in
                        If(menuItem.itemType.isButton) {
                            menuItem.button(itemId: listItemView.id)
                        }
                        If(menuItem.itemType.isMenu) {
                            menuItem.menu(itemId: listItemView.id)
                        }
                    }
                })
            
            let viewController = UIHostingController(rootView: viewWithTap)
            
            guard let view = viewController.view else {
                return
            }
            
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .clear
            
            contentView.subviews.forEach { $0.removeFromSuperview() }
            contentView.addSubview(view)
            
            view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: spacing / 2).isActive = true
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: spacing / -2).isActive = true
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0).isActive = true
        }
    }
}

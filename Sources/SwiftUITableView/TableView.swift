//
//  Handy.TableView.swift
//  HandyList
//
//  Created by Franklyn Weber on 19/01/2021.
//

import SwiftUI


protocol TableItemViewModel: ObservableObject {
    var id: String { get }
}

protocol TableIdentifiableView: View, Hashable {
    associatedtype ViewModelType: TableItemViewModel
    var id: String { get }
    init(viewModel: ViewModelType)
}

    
struct TableView<V: TableIdentifiableView>: UIViewControllerRepresentable {
    
    typealias ViewModelType = V.ViewModelType
    
    let tableViewControllerWrapper: Wrapper<V>
    
    
    init(title: Published<String>.Publisher? = nil, dataSource: Published<[V.ViewModelType]>.Publisher) {
        tableViewControllerWrapper = Wrapper<V>.instantiate(withTitle: title, dataSource: dataSource)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        return tableViewControllerWrapper.viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}

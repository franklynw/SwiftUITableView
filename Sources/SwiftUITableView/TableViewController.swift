//
//  TableViewController.swift
//  HandyList
//
//  Created by Franklyn Weber on 22/01/2021.
//

import SwiftUI
import Combine


extension TableView {
    
    class Wrapper<V: TableIdentifiableView> {
        
        weak var viewController: UIViewController!
        var tableViewController: TableViewController<V> {
            if let navigationController = viewController as? UINavigationController {
                return navigationController.topViewController as! TableViewController<V>
            } else {
                return viewController as! TableViewController<V>
            }
        }
        
        static func instantiate(withTitle title: Published<String>.Publisher?, dataSource: Published<[V.ViewModelType]>.Publisher) -> Wrapper<V> {
            
            let wrapper = Wrapper<V>()
            
            let viewController = TableViewController<V>()
            viewController.tableView.register(TableViewCell<V>.self, forCellReuseIdentifier: "TableViewCell")
            viewController.tableView.separatorStyle = .none
            
            viewController.dataSource = MoveableItemsDataSource(owner: viewController, tableView: viewController.tableView, dataSource: dataSource)
            
            guard let title = title else {
                viewController.view.alpha = 0
                wrapper.viewController = viewController
                return wrapper
            }
            
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.prefersLargeTitles = true
            navigationController.view.alpha = 0
            
            viewController.setTitle(title)
            
            wrapper.viewController = navigationController
            
            return wrapper
        }
    }
}


extension TableView {
    
    class TableViewController<V: TableIdentifiableView>: UITableViewController {
        
        fileprivate var dataSource: MoveableItemsDataSource<V>!
        private var subscriptions = Set<AnyCancellable>()
        
        private var leftItemAction: (() -> ())?
        private var rightItemAction: (() -> ())?
        
        fileprivate var titleActionViewLeadingAnchor: NSLayoutConstraint?
        fileprivate var titleActionViewTrailingAnchor: NSLayoutConstraint?
        fileprivate var largeTitleHeight: CGFloat = 0
        private var titleActionName: String?
        private var titleAction: (() -> ())?
        
        @Published var titleForTitleActionView: String = ""
        
        enum Section {
            case main
        }
        
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // When the viewController first appears, the contentOffset.y of the tableView is initially set to zero
            // Unfortunately this means that the title is the small version, rather than the large title which I want here
            // Pulling the table down works correctly anyway, & the title will grow to the large size,
            // however to get that large size from the start, the only way I could get that to happen was to force
            // the tableView to scroll based on the largeTitle font size. This works well, but it feels hacky
            // Would be nice not to have to do this...
            
            Async.after(0.1) {
                guard let navigationController = self.navigationController else {
                    return
                }
                
                self.largeTitleHeight = navigationController.navigationBar.largeTitleHeight
                self.tableView.setContentOffset(CGPoint(x: 0, y: -self.largeTitleHeight), animated: true)
                
                if self.titleAction != nil {
                    self.addTitleActionView()
                }
            }
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            finishSetup()
        }
        
        func setTitleColor(_ color: Published<UIColor>.Publisher?) {
            
            color?
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: $0]
                    self?.navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor: $0]
                    self?.navigationController?.navigationBar.tintColor = $0
                }
                .store(in: &subscriptions)
        }
        
        func setTitleBarColor(_ color: Published<UIColor>.Publisher?) {
            
            color?
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.navigationController?.navigationBar.standardAppearance.backgroundColor = $0
                }
                .store(in: &subscriptions)
        }
        
        func setSpacing(_ spacing: CGFloat) {
            dataSource.spacing = spacing
        }
        
        func setRightItemAction(_ imageName: Image.SystemName, action: @escaping () -> ()) {
            
            let rightButton = UIBarButtonItem(image: UIImage(imageName), style: .plain, target: self, action: #selector(rightAction))
            
            navigationItem.rightBarButtonItems = [rightButton]
            
            rightItemAction = action
        }
        
        func setLeftItemAction(_ imageName: Image.SystemName, action: @escaping () -> ()) {
            
            let leftButton = UIBarButtonItem(image: UIImage(imageName), style: .plain, target: self, action: #selector(leftAction))
            
            navigationItem.leftBarButtonItems = [leftButton]
            
            leftItemAction = action
        }
        
        func setTappedAction(_ action: @escaping (String) -> ()) {
            dataSource.tappedAction = action
        }
        
        func setEditAction(_ action: @escaping (String) -> ()) {
            dataSource.editAction = action
        }
        
        func setDeleteAction(_ action: @escaping (String) -> ()) {
            dataSource.deleteAction = action
        }
        
        func setTitleAction(title: String, action: @escaping () -> ()) {
            titleActionName = title
            titleAction = action
        }
        
        func setAdditionalContextMenuItems(_ items: [TableViewContextMenuItem]) {
            dataSource.additionalContextMenuItems = items
        }
        
        func setMoveAction(_ action: @escaping ((Int, Int) -> ())) {
            dataSource.moveAction = action
        }
        
        func setRowReorderEnabled(_ enabled: Published<Bool>.Publisher) {
            
            enabled
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.isEditing = $0
                }
                .store(in: &subscriptions)
        }
        
        func reload(_ reload: Published<Bool>.Publisher, done: (() -> ())?) {
            
            reload
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    
                    guard let self = self else {
                        return
                    }
                    
                    if $0 {
                        UIView.transition(with: self.tableView, duration: 0.3, options: .transitionCrossDissolve) {
                            self.tableView.reloadData()
                        } completion: { _ in done?() }
                    }
                }
                .store(in: &subscriptions)
        }
        
        fileprivate func setTitle(_ title: Published<String>.Publisher) {
            
            title
                .receive(on: DispatchQueue.main)
                .sink { [weak self] title in
                    self?.navigationItem.title = title
                }
                .store(in: &subscriptions)
        }
        
        private func finishSetup() {
            
            UIView.animate(withDuration: 0.3) {
                self.view.alpha = 1
                self.navigationController?.view.alpha = 1
            }
            
            tableView.reloadData()
        }
        
        private func addTitleActionView() {
            
            guard let navigationController = navigationController, let titleActionName = titleActionName, let titleAction = titleAction else {
                return
            }
            
            let actionView = Text(titleForTitleActionView)
                .frame(width: view.frame.width, height: 96, alignment: .center)
                .background(Color(.clear))
                .contentShape(Rectangle())
                .contextMenu {
                    Button(titleActionName, action: titleAction)
                }
            let viewController = UIHostingController(rootView: actionView)
            
            guard let uiView = viewController.view else {
                return
            }
            
            uiView.translatesAutoresizingMaskIntoConstraints = false
            uiView.backgroundColor = .clear
            
            let navigationBar = navigationController.navigationBar
            
            navigationBar.addSubview(uiView)
            
            uiView.topAnchor.constraint(equalTo: navigationBar.topAnchor).isActive = true
            uiView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
            
            titleActionViewLeadingAnchor = uiView.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor)
            titleActionViewTrailingAnchor = uiView.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor)
            
            titleActionViewLeadingAnchor?.isActive = true
            titleActionViewTrailingAnchor?.isActive = true
        }
        
        @objc
        private func rightAction() {
            rightItemAction?()
        }
        
        @objc
        private func leftAction() {
            leftItemAction?()
        }
    }
}


extension TableView {
    
    fileprivate class MoveableItemsDataSource<V: TableIdentifiableView>: UITableViewDiffableDataSource<TableViewController<V>.Section, V>, UITableViewDelegate {
        
        private var subscriptions = Set<AnyCancellable>()
        
        private weak var owner: TableViewController<V>!
        
        private var items: [V] = []
        private var textColor: UIColor?
        private var isMovingItem = false
        
        fileprivate var spacing: CGFloat = .zero
        fileprivate var tappedAction: ((String) -> ())?
        fileprivate var editAction: ((String) -> ())?
        fileprivate var deleteAction: ((String) -> ())?
        fileprivate var additionalContextMenuItems: [TableViewContextMenuItem] = []
        fileprivate var moveAction: ((Int, Int) -> ())?
        
        
        init(owner: TableViewController<V>, tableView: UITableView, dataSource: Published<[V.ViewModelType]>.Publisher) {
            
            self.owner = owner
            
            var spacing: (() -> CGFloat)!
            var tapped: (() -> ((String) -> ())?)!
            var edit: (() -> ((String) -> ())?)!
            var delete: (() -> ((String) -> ())?)!
            var additionalContextItems: (() -> [TableViewContextMenuItem])!
            
            super.init(tableView: tableView) { tableView, indexPath, listItem -> TableViewCell<V>? in
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell<V>
                
                cell.configure(with: listItem, spacing: spacing(), tapped: tapped(), edit: edit(), delete: delete(), additionalContextMenuItems: additionalContextItems())
                
                return cell
            }
            
            spacing = { [weak self] in
                guard let self = self else {
                    return .zero
                }
                return self.spacing
            }
            tapped = { [weak self] in
                guard let self = self else {
                    return nil
                }
                return { identifier in
                    guard !self.isMovingItem else {
                        return
                    }
                    self.tappedAction?(identifier)
                    tableView.reloadData()
                }
            }
            edit = { [weak self] in
                guard let self = self, self.editAction != nil else {
                    return nil
                }
                return { identifier in
                    self.editAction?(identifier)
                }
            }
            delete = { [weak self] in
                guard let self = self else {
                    return nil
                }
                return { identifier in
                    self.deleteAction?(identifier)
                }
            }
            additionalContextItems = { [weak self] in
                guard let self = self else {
                    return []
                }
                return self.additionalContextMenuItems
            }
            
            dataSource
                .sink { [weak self] in
                    self?.items = $0.map { V(viewModel: $0) }
                    self?.update()
                }
                .store(in: &subscriptions)
            
            tableView.dataSource = self
            tableView.delegate = self
        }
        
        func update() {
            
            var snapshot = NSDiffableDataSourceSnapshot<TableViewController<V>.Section, V>()
            
            snapshot.appendSections([TableViewController.Section.main])
            snapshot.appendItems(items, toSection: .main)
            
            apply(snapshot)
        }
        
        override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
        override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
            
            isMovingItem = true
            var snapshot = self.snapshot()
            
            if let sourceId = itemIdentifier(for: sourceIndexPath) {
                
                let itemToMove = items.remove(at: sourceIndexPath.row)
                items.insert(itemToMove, at: destinationIndexPath.row)
                moveAction?(sourceIndexPath.row, destinationIndexPath.row)
                
                if let destinationId = itemIdentifier(for: destinationIndexPath) {
                    
                    guard sourceId != destinationId else {
                        isMovingItem = false
                        return
                    }
                    
                    if sourceIndexPath.row > destinationIndexPath.row {
                        snapshot.moveItem(sourceId, beforeItem: destinationId)
                    } else {
                        snapshot.moveItem(sourceId, afterItem: destinationId)
                    }
                    
                } else {
                    
                    // no valid destination, eg. moving to the last row of a section
                    
                    snapshot.deleteItems([sourceId])
                    snapshot.appendItems([sourceId], toSection: snapshot.sectionIdentifiers[destinationIndexPath.section])
                }
            }
            
            // setting animatingDifferences to true makes for some very weird animations when the list is very long 😕
            apply(snapshot, animatingDifferences: false, completion: { [weak self] in
                self?.isMovingItem = false
            })
        }
        
        func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
            return .none
        }
        
        func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
            return false
        }
        
        func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
            
            // NB - only works when tableViewController isEditing is set to false
            
            guard self.deleteAction != nil else {
                return UISwipeActionsConfiguration(actions: [])
            }
            
            let deleteAction = UIContextualAction(style: UIContextualAction.Style.destructive, title: "Delete") { [weak self] _, _, completion in
                
                guard let self = self, let itemId = self.itemIdentifier(for: indexPath) else {
                    return
                }
                
                let deletedItem = self.items.remove(at: indexPath.row)
                self.deleteAction?(deletedItem.id)

                var snapshot = self.snapshot()
                snapshot.deleteItems([itemId])

                self.apply(snapshot, animatingDifferences: true)
                
                completion(true)
            }
            
            return UISwipeActionsConfiguration(actions: [deleteAction])
        }
        
        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            
            let offset = scrollView.contentOffset.y
            let inset = min(max(0, offset + owner.largeTitleHeight), 50)
            
            owner?.titleActionViewLeadingAnchor?.constant = inset
            owner?.titleActionViewTrailingAnchor?.constant = -inset
        }
    }
}


fileprivate extension UINavigationBar {
    
    var largeTitleHeight: CGFloat {
        
        let label = UILabel()
        label.font = UIFont.preferredFont(style: .largeTitle)
        label.text = "Title"
        
        let height = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).height
        let titleHeight = height * 2.395
        
        return titleHeight
    }
}

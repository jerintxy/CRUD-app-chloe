//
//  ListViewController.swift
//  CRUD app
//
//  Created by Chloe Tay on 19/10/26.
//

import UIKit

// MARK: - Modern Diffable Data Source Subclass
class ExcuseDataSource: UITableViewDiffableDataSource<Reason, Excuse> {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // find the Reason enum for this section slot
        let reasonType = snapshot().sectionIdentifiers[section]
        return reasonType.rawValue.capitalized
    }
}

// MARK: - Main View Controller
class ListViewController: UIViewController {

    // MARK: - Properties
    private var dataSource: ExcuseDataSource!
    private let store = ExcuseDataStore.shared
    
    // master copy used to build screen updates
    private var excuses: [Excuse] = []
    
    private let tableView = UITableView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Bobian Log"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        // Load data from storage file on launch
        excuses = store.loadExcuses()
        
        setupNavigationBar()
        setupTableView()
        
        // Save on app close notification setup
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            try? self.store.saveExcuses(self.excuses)
        }
        
        // Initialize the custom Diffable Data Source
        dataSource = ExcuseDataSource(tableView: tableView) { tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ExcuseTableViewCell.identifier,
                for: indexPath
            ) as? ExcuseTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: item)
            return cell
        }

        dataSource.defaultRowAnimation = .fade
        tableView.dataSource = dataSource
        tableView.delegate = self
        
        // Display initial data state immediately
        applySnapshot(animatingDifferences: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh UI state whenever screen returns to view focus
        applySnapshot(animatingDifferences: false)
    }
    
    // MARK: - Layout & Setup
    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        addButton.tintColor = .systemBlue
        navigationItem.rightBarButtonItem = addButton
    }
    
    private func setupTableView() {
        tableView.register(ExcuseTableViewCell.self, forCellReuseIdentifier: ExcuseTableViewCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    // MARK: - Snapshot Update Mechanism
    private func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Reason, Excuse>()

        // Group array items by their enum types
        let grouped = Dictionary(grouping: excuses, by: { $0.reason })

        // Sort sections alphabetically based on raw values
        let sortedTypes = grouped.keys.sorted(by: { $0.rawValue < $1.rawValue })

        // Build snapshot - rebuild modern table sections and rows
        snapshot.appendSections(sortedTypes)
        for type in sortedTypes {
            snapshot.appendItems(grouped[type]!, toSection: type)
        }

        // Safely apply calculations to UI layout
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    // MARK: - Actions
    @objc private func addButtonTapped() {
        let formVC = ExcuseFormViewController()
        formVC.delegate = self // Now valid due to extension conformance lower down
        let navController = UINavigationController(rootViewController: formVC)
        present(navController, animated: true)
    }
}

// MARK: - ExcuseFormViewControllerDelegate Conformance
extension ListViewController: ExcuseFormViewControllerDelegate {

    func didAddExcuse(_ excuse: Excuse) {
        excuses.append(excuse)
        applySnapshot(animatingDifferences: true)
        
        do {
            try store.saveExcuses(excuses)
        } catch {
            print("Could not save list after adding: \(error.localizedDescription)")
        }
    }

    func didUpdateExcuse(_ excuse: Excuse) {
        if let index = excuses.firstIndex(where: { $0.id == excuse.id }) {
            excuses[index] = excuse
            applySnapshot(animatingDifferences: true)
            
            do {
                try store.saveExcuses(excuses)
            } catch {
                print("Could not save list after updating: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - UITableViewDelegate Conformance
extension ListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // pull item safely out of the diffable data source instead of basic array math
        guard let selectedExcuse = dataSource.itemIdentifier(for: indexPath) else { return }
        
        let detailVC = ExcuseDetailViewController(excuse: selectedExcuse)
        detailVC.delegate = self
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    
    // swipe to delete
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return nil }

        let delete = UIContextualAction(style: .destructive, title: "Delete") { _,_,done in
            self.excuses.removeAll { $0.id == item.id }
            try? self.store.saveExcuses(self.excuses)
            self.applySnapshot()
            done(true)
        }

        return UISwipeActionsConfiguration(actions: [delete])
    }
}


//
//  ExcuseDetailViewController.swift
//  CRUD app
//
//  Created by Chloe Tay on 19/10/26.
//

import UIKit



class ExcuseDetailViewController: UITableViewController, ExcuseFormViewControllerDelegate {
    weak var delegate: ExcuseFormViewControllerDelegate?
    
    //MARK: - properties
    private var excuse: Excuse
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    //MARK: initialisers
    init(excuse: Excuse) {
        self.excuse = excuse //store it first
        super.init(style: .insetGrouped) //then let uikit set up the table
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Details"
        navigationItem.largeTitleDisplayMode = .never
        
        //edit button on the top right
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .edit,
            target: self,
            action: #selector(editTapped)
        )
    }

    //MARK: - Actions
    @objc func editTapped(){
        // Pass the excuse -> the form is in "edit" mode.
        let formVC = ExcuseFormViewController(excuse: excuse)
        formVC.delegate = self
        let navController = UINavigationController(rootViewController: formVC)
        present(navController, animated: true)
    }
    
    // MARK: - ExcuseFormViewControllerDelegate

    // Called by the form after editing. The excuse object is already changed,
    // so we just redraw this screen to show the new values.
    func didUpdateExcuse(_ excuse: Excuse) {
        self.excuse = excuse   // 1. Must reassign the stored property first!
        tableView.reloadData()  // 2. Then reload the table to show the new values
        delegate?.didUpdateExcuse(excuse) 
    }
    
    // MARK: - Table view data source
    // Two groups: "Information" and "Stats"
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    // Rows per group: Information has 3 (activity, reason, date), Stats has 1 (validity)
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 3 : 1
    }

    // The grey heading above each group.
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Information" : "Stats"
    }
    
    // Build each row.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // .value1 style = label on the left, value on the right (like the Settings app).
        // The rows are fixed, so we don't need recycling here.
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.selectionStyle = .none   // rows aren't tappable
        
        // Switch on (section, row) together, i.e. "tuple switching".
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "Activity"
            cell.detailTextLabel?.text = excuse.activity
        case (0, 1):
            cell.textLabel?.text = "Reason"
            cell.detailTextLabel?.text = excuse.reason.rawValue
        case (0, 2):
            cell.textLabel?.text = "Date"
            cell.detailTextLabel?.text = Self.dateFormatter.string(from: excuse.date)
        case (1, 0):
            cell.textLabel?.text = "Validity"
            cell.detailTextLabel?.text = "\(excuse.validity)/10"
        default:
            break   // required by Swift: "what if it's none of the above?"
        }
        return cell
    }

}

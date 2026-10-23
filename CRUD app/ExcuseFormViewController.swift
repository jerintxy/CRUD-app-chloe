//
//  ExcuseFormViewController.swift
//  CRUD app
//
//  Created by Chloe Tay on 19/10/26.
//

import UIKit
import Foundation

//define the protocol
protocol ExcuseFormViewControllerDelegate: AnyObject {
    func didAddExcuse(_ excuse: Excuse)      // "a brand new excuse was saved"
    func didUpdateExcuse(_ excuse: Excuse)   // "an existing excuse was changed"
}

// Default (empty) versions of both methods makes them optional: a screen only implements the one it needs
// The list only cares about adding, the detail screen only about updating
extension ExcuseFormViewControllerDelegate {
    func didAddExcuse(_ excuse: Excuse) {}
    func didUpdateExcuse(_ excuse: Excuse) {}
}

class ExcuseFormViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    //MARK: - Properties
    // The excuse being edited
    // nil      -> ADDING a new excuse
    // not nil  -> EDITING that excuse
    private let excuse: Excuse?
    
    private let activityTextField = UITextField() //text box where user types the activity
    private let reasonPicker = UIPickerView() //wheel of excuses
    private let validityStepper = UIStepper() // +- buttons
    private let validityValueLabel = UILabel() //show stepper's number
    private let datePicker = UIDatePicker() //date wheel
    
    // add delegate property
    weak var delegate: ExcuseFormViewControllerDelegate?
    
    //MARK: - initialisers
    // excuse: Excuse? = nil means: you may pass an excuse, or pass nothing (defaults to nil)
    init(excuse: Excuse? = nil) {
        self.excuse = excuse
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //title depends on the mode `excuse == nil` is true when adding.
        title = excuse == nil ? "Add Excuse" : "Edit Excuse"
        
        //cancel on the left
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        //save on the right
        let saveButton = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
        saveButton.tintColor = .systemBlue
        saveButton.style = .prominent
        navigationItem.rightBarButtonItem = saveButton
        
        activityTextField.placeholder = "e.g. what are u avoiding again"   // grey hint text when empty

        // Picker: "I'm in charge of your data" (same idea as tableView.dataSource = self)
        reasonPicker.dataSource = self
        reasonPicker.delegate = self

        // Stepper: whole numbers 1 to 10, starting at 5, changes by 1 per tap.
        validityStepper.minimumValue = 1
        validityStepper.maximumValue = 10
        validityStepper.stepValue = 1
        validityStepper.value = 5
        // When the stepper changes, run stepperChanged so the label updates.
        validityStepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
        validityValueLabel.text = "5"

        // Date picker: wheel style, date only (no time).
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = Date() //the latest selectable date is right now

        configureForEditing()
        
        //dismisses the keyboard after clicking anywhere outside and when scrolling
        tableView.keyboardDismissMode = .onDrag
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    //MARK: - setup
    //if editing, fill the controls with the existing data
    private func configureForEditing(){
        //only runs if excuse is NOT nil
        if let excuse = excuse {
            activityTextField.text = excuse.activity
            
            //find the position of this reason in the list of all reasons, spin the picker to that row
            if let index = Reason.allCases.firstIndex(of: excuse.reason) {
                reasonPicker.selectRow(index, inComponent: 0, animated: false)
            }
            
            validityStepper.value = Double(excuse.validity)   //stepper stores Doubles, our validity is Int
            validityValueLabel.text = "\(excuse.validity)"
            datePicker.date = excuse.date
        }
    }
    
    
    //MARK: - actions
    // close the modal, change nothing
    @objc private func cancelTapped(){
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        let activity = (activityTextField.text ?? "").trimmingCharacters(in: .whitespaces)
        guard !activity.isEmpty else {
            let alert = UIAlertController(title: "Missing Activity", message: "Please enter what you didn't do", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default)) //one button to close it
            present(alert, animated: true)
            return
        }
        
        let reason = Reason.allCases[reasonPicker.selectedRow(inComponent: 0)]
        let validity = Int(validityStepper.value)
        let date = datePicker.date
        
        
        /*
        • The Problem: You couldn't write excuse.activity = activity anymore. The compiler said it was an immutable constant.
        
         • The Reason: With a class, you are passing around a pointer to a single shared box. You can reach inside that box and change things even if the pointer itself is constant (let). With a struct, the object is the value. If you capture a struct using if let excuse = excuse, Swift locks down the entire thing as a constant copy. You cannot change a value type unless it is explicitly marked with var.
        
         • The Fix: We had to rebuild a fresh instance of the struct (let updatedExcuse = Excuse(...)) containing the new information and pass that along instead of altering the old one in place.
         */
        
        if let excuse = excuse {
            let updatedExcuse = Excuse(
                id: excuse.id, // Keep the same ID!
                activity: activity,
                reason: reason,
                validity: validity,
                date: date
            )
            // Hey! I am completely done editing, and here is the final, updated version of the data.
            delegate?.didUpdateExcuse(updatedExcuse)
            
            
            /*
             this is the old version, when using a class
             
            // EDITING: change the existing object's values directly
            // its a class so the list and detail screens see the change too
            excuse.activity = activity
            excuse.reason = reason
            excuse.validity = validity
            excuse.date = date
             
            delegate?.didUpdateExcuse(excuse)   // "?" = only if a delegate exists
             */
        } else {
            // ADDING: build a brand new excuse and hand it over.
            let newExcuse = Excuse(activity: activity, reason: reason, validity: validity, date: date)
            delegate?.didAddExcuse(newExcuse)
        }
        
        dismiss(animated: true)   // close the form
    }
    
    //runs when user taps on the stepper
    @objc private func stepperChanged(){
        //converts the Double to a whole number for display
        validityValueLabel.text = "\(Int(validityStepper.value))"
    }
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Four groups, one per input.
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Each group has exactly one row.
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Activity"
        case 1: return "Reason"
        case 2: return "Validity (legit or not?)"
        default: return "Date"
        }
    }
    
    // The picker and date picker are tall, so those rows need more height.
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 1, 3: return 160    // picker and date picker
        default: return 50       // text field and stepper
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        
        switch indexPath.section {
        case 0:
            addFullWidth(activityTextField, to: cell)
            
        case 1:
            addFullWidth(reasonPicker, to: cell)
            
        case 2:
            // Left: "Validity". Right: the number, then the stepper as the cell's accessory.
            cell.textLabel?.text = "Validity"
            validityValueLabel.sizeToFit()
            cell.accessoryView = validityStepper
            // The number sits left of the stepper, so put it in a stack with it.
            let stack = UIStackView(arrangedSubviews: [validityValueLabel, validityStepper])
            stack.axis = .horizontal
            stack.spacing = 12
            stack.alignment = .center
            stack.frame = CGRect(x: 0, y: 0, width: 140, height: 40)
            cell.accessoryView = stack
            
        default:
            addFullWidth(datePicker, to: cell)
        }
        
        return cell
    }
    
    // Helper: put any control inside a cell and pin it to all four edges.
    // We wrote this once instead of repeating the same constraints three times.
    private func addFullWidth(_ control: UIView, to cell: UITableViewCell) {
        control.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(control)
        NSLayoutConstraint.activate([
            control.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
            control.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -4),
            control.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            control.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16)
        ])
    }
    

    // MARK: - UIPickerViewDataSource
    
    // A picker can have several spinning columns. We want just one.
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // Same "how many rows?" question as a table: one per Reason case.
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Reason.allCases.count
    }
    
    // MARK: - UIPickerViewDelegate
    
    // "What text goes in row N?" -> that reason's display text.
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Reason.allCases[row].rawValue
    }

}

//
//  NodeAddNetworkKeyViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 28/06/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

protocol NetworkKeyDelegate {
    /// This method is called when a new Network Key has been added to the Node.
    func keyAdded()
}

class NodeAddNetworkKeyViewController: ConnectableViewController {
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        connect()
    }
    
    // MARK: - Properties
    
    var node: Node!
    var delegate: NetworkKeyDelegate?
    
    private var keys: [NetworkKey]!
    private var selectedRow: Int?
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "No keys available", message: "Go to Settings to create a new key.", messageImage: #imageLiteral(resourceName: "baseline-key"))
        
        MeshNetworkManager.instance.delegate = self
        
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        keys = meshNetwork.networkKeys.notKnownTo(node: node)
        let areMoreNetKeys = keys.count > 0
        if !areMoreNetKeys {
            tableView.showEmptyView()
        }
        // Initially, no key is checked.
        doneButton.isEnabled = false
    }
    
    override func networkReady(alert: UIAlertController) {
        guard let selectedRow = selectedRow else {
            return
        }
        let selectedNetworkKey = keys[selectedRow]
        alert.message = "Adding Network Key..."
        MeshNetworkManager.instance.send(ConfigNetKeyAdd(networkKey: selectedNetworkKey), to: node)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keys.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let key = keys[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = key.name
        cell.accessoryType = indexPath.row == selectedRow ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var rows: [IndexPath] = []
        if selectedRow != nil {
            rows.append(IndexPath(row: selectedRow!, section: 0))
        }
        rows.append(indexPath)
        selectedRow = indexPath.row
        tableView.reloadRows(at: rows, with: .automatic)
        
        doneButton.isEnabled = true
    }
}

extension NodeAddNetworkKeyViewController: MeshNetworkDelegate {
    
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address) {
        switch message {
        case let status as ConfigNetKeyStatus:
            alert?.dismiss(animated: true)
            
            if status.status == .success {
                dismiss(animated: true)
                delegate?.keyAdded()
            } else {
                presentAlert(title: "Error", message: "\(status.status)")
            }
        default:
            // Ignore
            break
        }
    }
    
}

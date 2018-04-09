//
//  MainViewController.swift
//  Nextrain
//
//  Created by Ariel Elkin on 08/04/2018.
//  Copyright © 2018 ariel. All rights reserved.
//

import UIKit
import SVProgressHUD

class MainViewController: UIViewController {
    
    let fromStationTextField = SearchTextField()
    let toStationTextField = SearchTextField()
    let statusLabel = UILabel()
    let resultsTableView = UITableView(frame: CGRect.zero, style: .plain)
    
    var trains: [Train]? {
        didSet {
            if trains != nil ||
                trains == nil && oldValue != nil {
                resultsTableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Irish Nextrain"
        
        buildUI()
        
        fromStationTextField.userStoppedTypingHandler = userStoppedTyping
        toStationTextField.userStoppedTypingHandler = userStoppedTyping
        
        fromStationTextField.itemSelectionHandler = { result, index in
            self.handleItemSelected(
                textField: self.fromStationTextField,
                resultText: result.first!.title
            )
        }
        toStationTextField.itemSelectionHandler = { result, index in
            self.handleItemSelected(
                textField: self.toStationTextField,
                resultText: result.first!.title
            )
        }
        
        SVProgressHUD.showInfo(withStatus: "Searching available stations...")
        
        APIClient.allStations { (result) in

            switch result {

            case .success(let stations):
                self.fromStationTextField.becomeFirstResponder()
                self.fromStationTextField.filterStrings(stations)
                self.toStationTextField.filterStrings(stations)
                SVProgressHUD.dismiss()

            case .failure(let error):
                // TODO: better error handling
                print("Error: \(error)")
                SVProgressHUD.showError(withStatus: "\(error)")
            }
        }
    }

    func buildUI() {
        
        view.backgroundColor = .white
        
        fromStationTextField.placeholder = "Origin station"
        fromStationTextField.maxNumberOfResults = 5
        fromStationTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fromStationTextField)
        
        toStationTextField.placeholder = "Destination station"
        toStationTextField.maxNumberOfResults = 5
        toStationTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toStationTextField)

        statusLabel.text = "Type the names of the stations you want to travel between."
        statusLabel.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        resultsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "identifier")
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        resultsTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resultsTableView)

        
        [fromStationTextField.topAnchor.constraintEqualToSystemSpacingBelow(view.safeAreaLayoutGuide.topAnchor, multiplier: 1),
         fromStationTextField.heightAnchor.constraint(equalToConstant: 50),
         fromStationTextField.leadingAnchor.constraintEqualToSystemSpacingAfter(view.safeAreaLayoutGuide.leadingAnchor, multiplier: 1),
         view.safeAreaLayoutGuide.trailingAnchor.constraintEqualToSystemSpacingAfter(fromStationTextField.trailingAnchor, multiplier: 1),

         toStationTextField.topAnchor.constraint(equalTo: fromStationTextField.bottomAnchor, constant: 0),
         toStationTextField.heightAnchor.constraint(equalToConstant: 50),
         toStationTextField.leadingAnchor.constraintEqualToSystemSpacingAfter(view.safeAreaLayoutGuide.leadingAnchor, multiplier: 1),
         view.safeAreaLayoutGuide.trailingAnchor.constraintEqualToSystemSpacingAfter(toStationTextField.trailingAnchor, multiplier: 1),

         statusLabel.topAnchor.constraint(equalTo: toStationTextField.bottomAnchor, constant: 0),
         statusLabel.leadingAnchor.constraintEqualToSystemSpacingAfter(view.safeAreaLayoutGuide.leadingAnchor, multiplier: 1),
         view.safeAreaLayoutGuide.trailingAnchor.constraintEqualToSystemSpacingAfter(statusLabel.trailingAnchor, multiplier: 1),
         statusLabel.bottomAnchor.constraint(equalTo: resultsTableView.topAnchor, constant: 0),

         resultsTableView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 0),
         resultsTableView.leftAnchor.constraintEqualToSystemSpacingAfter(view.safeAreaLayoutGuide.leftAnchor, multiplier: 1),
         view.safeAreaLayoutGuide.rightAnchor.constraintEqualToSystemSpacingAfter(resultsTableView.rightAnchor, multiplier: 1),
         resultsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)]
            .forEach { $0.isActive = true }
    }

    func handleItemSelected(textField: SearchTextField, resultText: String) {
        textField.text = resultText

        let otherTextField =
            (textField == fromStationTextField ? toStationTextField : fromStationTextField)

        if otherTextField.text?.isEmpty == true {
            otherTextField.becomeFirstResponder()
        }
        else {
            self.searchTrains(origin: self.fromStationTextField.text!, destination: self.toStationTextField.text!)
        }
    }

    func userStoppedTyping() {
        if fromStationTextField.text?.isEmpty == true || toStationTextField.text?.isEmpty == true {
            trains = nil
            statusLabel.text = nil
        }
    }


    func searchTrains(origin: String, destination: String) {
        SVProgressHUD.showInfo(withStatus: "Searching Trains...")
        
        APIClient.searchTrains(origin: origin, destination: destination) { (result) in

            switch result {

            case .success(let searchResults):
                SVProgressHUD.dismiss()

                switch searchResults {
                case .trainsTerminatingAtDestination(let trains):
                    self.statusLabel.text = "Found these trains terminating at \(destination)"
                    self.trains = trains
                case .trainsTerminatingAtOtherDestination(let trains):
                    self.statusLabel.text = "Found no trains terminating at \(destination). These are the destinations of the next trains through \(origin):"
                    self.trains = trains
                }

            case .failure(let error):
                // TODO: better error handling
                print("Error: \(error)")
                SVProgressHUD.showError(withStatus: "\(error)")
            }
        }
    }
}


extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "identifier")!
        guard let trains = trains else {
            assertionFailure("We shouldn't be dequeuing cells if trains is nil!")
            return UITableViewCell()
        }

        let train = trains[indexPath.item]
        cell.textLabel?.text = "\(train.destination) – due in \(train.dueIn) minutes"
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let trains = trains {
            return trains.count
        }
        return 0
    }
}

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard let train = trains?[indexPath.item] else {
            assertionFailure("we shouldn't be selecting a row with no train associated!")
            return
        }

        let detailVC = TrainDetailViewController(train: train)
        self.navigationController?.pushViewController(detailVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


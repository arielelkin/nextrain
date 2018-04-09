//
//  TrainDetailViewController.swift
//  Nextrain
//
//  Created by Ariel Elkin on 09/04/2018.
//  Copyright © 2018 ariel. All rights reserved.
//

import UIKit

class TrainDetailViewController: UIViewController {

    convenience init(train: Train) {
        self.init(nibName: nil, bundle: nil)

        title = "Train detail"

        view.backgroundColor = .white

        let originLabel = UILabel()
        originLabel.text = "Origin: \(train.origin)"

        let destinationLabel = UILabel()
        destinationLabel.text = "Destination: \(train.destination)"

        let expectedDepartureTimeLabel = UILabel()
        expectedDepartureTimeLabel.text = "Expected departure at: \(train.expectedDepartureTime)"

        let dueInLabel = UILabel()
        dueInLabel.text = "Train due in: \(train.dueIn) minutes"


        [originLabel, destinationLabel, expectedDepartureTimeLabel, dueInLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        // leading and trailing constraints:
        [originLabel, destinationLabel, expectedDepartureTimeLabel, dueInLabel]
            .forEach {
                $0.leadingAnchor.constraintEqualToSystemSpacingAfter(view.safeAreaLayoutGuide.leadingAnchor, multiplier: 1)
                    .isActive = true
                view.safeAreaLayoutGuide.trailingAnchor.constraintEqualToSystemSpacingAfter($0.trailingAnchor, multiplier: 1)
                    .isActive = true
        }

        // top and bottom constraints:
        [originLabel.topAnchor.constraintEqualToSystemSpacingBelow(view.safeAreaLayoutGuide.topAnchor, multiplier: 1),
         originLabel.bottomAnchor.constraint(equalTo: destinationLabel.topAnchor),
         destinationLabel.bottomAnchor.constraint(equalTo: expectedDepartureTimeLabel.topAnchor),
         expectedDepartureTimeLabel.bottomAnchor.constraint(equalTo: dueInLabel.topAnchor),
         dueInLabel.bottomAnchor.constraint(equalTo: view.centerYAnchor),

         originLabel.heightAnchor.constraint(equalTo: destinationLabel.heightAnchor, constant: 0),
         originLabel.heightAnchor.constraint(equalTo: expectedDepartureTimeLabel.heightAnchor, constant: 0),
         originLabel.heightAnchor.constraint(equalTo: dueInLabel.heightAnchor, constant: 0),
         ]
            .forEach { $0.isActive = true }

    }
}

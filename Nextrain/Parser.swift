//
//  Parser.swift
//  Nextrain
//
//  Created by Ariel Elkin on 08/04/2018.
//  Copyright © 2018 ariel. All rights reserved.
//

import Foundation
import SWXMLHash

final class Parser {

    static func parseStationList(data: Data) -> [String] {

        var stationsList = [String]()

        let xml = SWXMLHash.parse(data)

        xml["ArrayOfObjStation"]["objStation"].all.forEach { elem in
            if let station = elem["StationDesc"].element?.text {
                stationsList.append(station)
            }
        }
        return stationsList.sorted()
    }

    static func parseTrainsFromStation(data: Data) -> [Train] {

        var trains = [Train]()

        let xml = SWXMLHash.parse(data)

        xml["ArrayOfObjStationData"]["objStationData"].all.forEach { elem in
            let origin = elem["Origin"].element?.text
            let destination = elem["Destination"].element?.text
            let dueInString = elem["Duein"].element?.text
            let expectedDepartureTime = elem["Expdepart"].element?.text

            if let origin = origin,
                let destination = destination,
                let dueInString = dueInString,
                let dueIn = Int(dueInString),
                let expectedDepartureTime = expectedDepartureTime {
                let train = Train(origin: origin, destination: destination, expectedDepartureTime: expectedDepartureTime, dueIn: dueIn)
                trains.append(train)
            }
        }

        return trains
    }
}

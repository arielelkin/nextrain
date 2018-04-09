//
//  APIClient.swift
//  Nextrain
//
//  Created by Ariel Elkin on 08/04/2018.
//  Copyright © 2018 ariel. All rights reserved.
//

import Foundation

enum APIResult<T, Error> {
    case success(T)
    case failure(Error)
}

// The Irish Rail API doesn't seem to provide a list of
// trains running between two specified stations, only
// all trains running through an origin station. So we'll filter
// that list and either return any trains terminating at the
// specified destination, or all trains from the origin terminating
// at any destination.
enum TrainSearchResult {
    case trainsTerminatingAtDestination([Train])
    case trainsTerminatingAtOtherDestination([Train])
}


// APIClient wraps the Irish Rail API. It coordinates the work
// of Networker and Parser.
final class APIClient {
    static func allStations(completion: @escaping (APIResult<[String], Error>) -> Void) {

        let url = IrishRailAPI.allStationsURL

        let _ = Networker.makeRequest(url) { (networkerResult) in

            let result: APIResult<[String], Error>

            switch networkerResult {

            case .success(_, let data):
                let stationsList = Parser.parseStationList(data: data)
                result = .success(stationsList)

            case .failure(let error):
                result = .failure(error)
            }
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
    }

    static func searchTrains(origin: String, destination: String, completion: @escaping (APIResult<TrainSearchResult, Error>) -> Void) {

        let url = IrishRailAPI.trainsFromStationURL(fromStation: origin)

        let _ = Networker.makeRequest(url) { (networkerResult) in

            let result: APIResult<TrainSearchResult, Error>

            switch networkerResult {

            case .success(_, let data):

                let trainList = Parser.parseTrainsFromStation(data: data)
                    .sorted(by: {$0.dueIn < $1.dueIn } ) // the API's results aren't always sorted by due time!

                let trainsTerminatingAtDestination = trainList.filter { train in
                    train.destination == destination
                }

                let bestResult: TrainSearchResult

                if trainsTerminatingAtDestination.count > 0 {
                    bestResult = .trainsTerminatingAtDestination(trainsTerminatingAtDestination)
                }
                else {
                    bestResult = .trainsTerminatingAtOtherDestination(trainList)
                }

                result = .success(bestResult)

            case .failure(let error):
                result = .failure(error)
            }

            OperationQueue.main.addOperation {
                completion(result)
            }
        }
    }
}

struct IrishRailAPI {
    static let baseURL = URL(string: "http://api.irishrail.ie/realtime/realtime.asmx/")!
    static let allStationsURL = URL(string: "getAllStationsXML", relativeTo: baseURL)!
    static func trainsFromStationURL(fromStation: String) -> URL {
        return URL(
            string: "getStationDataByNameXML?StationDesc=\(fromStation.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)",
            relativeTo: baseURL
            )!
    }
}


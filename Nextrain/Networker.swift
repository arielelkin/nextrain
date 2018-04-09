//
//  Networker.swift
//  Nextrain
//
//  Created by Ariel Elkin on 08/04/2018.
//  Copyright © 2018 ariel. All rights reserved.
//

import UIKit

enum NetworkerResult {
    case success(status: Int, data: Data)
    case failure(error: NetworkerError)
}

enum NetworkerError: Error {
    case networkingFailure(error: Error)
    case noConnection
    case noData
}



extension NetworkerError {

    var localizedTitle: String {
        switch self {
        case .networkingFailure(let error):
            return error.localizedDescription
        case .noConnection:
            return "No internet connection."
        case .noData:
            return "Received no data."
        }
    }
}

/**
 Networker is responsible for configuring an NSURLSession and carrying out network requests. It is API-agnostic.

 */
class Networker {

    fileprivate let session: URLSession
    static var verbose = false
    fileprivate let defaultHeaders: [String: String]?
    fileprivate var requestHeaders = [String: String]()

    init(defaultHeaders: [String: String]? = nil) {
        self.defaultHeaders = defaultHeaders
        let configuration = URLSessionConfiguration.default
        if let headers = defaultHeaders {
            configuration.httpAdditionalHeaders = headers
        }
        session = URLSession(configuration: configuration)
    }


    /**
     Carries out an HTTP request.

     - parameter url: The URL requested.
     - parameter method: The HTTP method to use.
     - parameter additionalHeaders: HTTP headers to add to the request.
     - parameter body: The request's body as a Data object.
     - parameter completion:  A closure returning either the obtained data or an error.

     - returns: An `NSURLSessionDataTask` instance of the corresponding URL request.

     */
    static func makeRequest(
        _ url: URL,
        method: HTTPMethod = .GET,
        additionalHeaders: [String: String]? = nil,
        body: Data? = nil,
        completion: @escaping (_ result: NetworkerResult) -> Void
        ) -> URLSessionDataTask
    {
        let session = URLSession.shared
        return Networker.makeRequest(session, url: url, method: method, additionalHeaders: additionalHeaders, body: body, completion: completion)
    }

    fileprivate static func makeRequest(
        _ session: URLSession,
        url: URL,
        method: HTTPMethod = .GET,
        additionalHeaders: [String: String]? = nil,
        body: Data? = nil,
        completion: @escaping (_ result: NetworkerResult) -> Void
        ) -> URLSessionDataTask
    {

        OperationQueue.main.addOperation {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if let header = additionalHeaders {
            for k in header.keys {
                request.addValue(header[k]!, forHTTPHeaderField: k)
            }
        }

        request.httpBody = body

        if Networker.verbose {
            Swift.print(" ")
            Swift.print("Request \(String(describing: request.httpMethod)) \(request.url!)")
            if let headers = request.allHTTPHeaderFields , !headers.isEmpty {
                Swift.print("\tHeaders")
                for (key, value) in headers  {
                    Swift.print("\t\t\(key): \(value)")
                }
            }

            if let body = body {
                if let jsonString = NSString(data: body, encoding: String.Encoding.utf8.rawValue) {
                    Swift.print("\tBody:")
                    Swift.print(jsonString.components(separatedBy: "\n").map({ "\t\t"+$0 }).joined(separator: "\n"))
                }
            }
            Swift.print(" ")
        }


        let dataTask = session.dataTask(with: request, completionHandler: {
            (data: Data?, response: URLResponse?, dataTaskError: Error?) in

            OperationQueue.main.addOperation {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }

            if Networker.verbose {
                Swift.print(" ")
                Swift.print("Response \(String(describing: request.httpMethod)) \(request.url!)")
                Swift.print("\tStatus: \(response?.httpStatusCode ?? -1)")
            }

            guard dataTaskError == nil else {

                // TODO: Better error handling
                if let error = dataTaskError as NSError? {
                    switch error.code {
                    case NSURLErrorTimedOut,
                         NSURLErrorCannotFindHost,
                         NSURLErrorCannotConnectToHost,
                         NSURLErrorNetworkConnectionLost,
                         NSURLErrorDNSLookupFailed,
                         NSURLErrorNotConnectedToInternet:
                        completion(.failure(error: .noConnection))
                    default:
                        completion(.failure(error: NetworkerError.networkingFailure(error: error)))
                    }
                } else {
                    let error = NSError()
                    completion(.failure(error: NetworkerError.networkingFailure(error: error)))
                }

                return
            }

            guard let data = data else {
                completion(.failure(error: .noData))
                return
            }

            if Networker.verbose {
                if let bodyEncoded = String(data: data, encoding: String.Encoding.utf8) {
                    Swift.print("\tBody: \(bodyEncoded)")
                }
            }

            completion(.success(status: response?.httpStatusCode ?? -1, data: data))

        })

        dataTask.resume()

        return dataTask

    }

    var additionalHeaders: [AnyHashable: Any]? {
        return session.configuration.httpAdditionalHeaders
    }

    func reset() {
        requestHeaders = [String: String]()
    }

    func invalidateAndCancelAllTasks() {

        URLSession.shared.invalidateAndCancelAllTasks()
        session.invalidateAndCancelAllTasks()
    }
}

private extension URLSession {

    func invalidateAndCancelAllTasks() {
        getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() }
        }
    }
}


/**
 HTTP method definitions.

 See http://tools.ietf.org/html/rfc7231#section-4.3
 */
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}


private extension URLResponse {

    var httpStatusCode: Int {
        //this cast will fail only if we don't use HTTP.
        let response = self as! HTTPURLResponse

        return response.statusCode
    }
}


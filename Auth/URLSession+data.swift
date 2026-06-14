import Foundation
import os

extension URLSession {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.unsplash.ImageFeed",
        category: "NetworkLayer"
    )
    
    private static let sharedDecoder = JSONDecoder()
    
    func data(
        for request: URLRequest,
        completion: @escaping(Result<Data, Error>) -> Void
    ) -> URLSessionTask {
        let fulfillCompletionOnTheMainThread: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        let task = dataTask(with: request, completionHandler: { data, response, error in
            if let data, let response, let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if 200 ..< 300 ~= statusCode {
                    fulfillCompletionOnTheMainThread(.success(data))
                } else {
                    fulfillCompletionOnTheMainThread(.failure(NetworkError.httpStatusCode(statusCode)))
                }
            } else if let error = error {
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlRequestError(error)))
            } else {
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlSessionError))
            }
        })
        
        return task
    }
}

extension URLSession {
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        
        let task = data(for: request) { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                if let jsonString = String(data: data, encoding: .utf8) {
                    Self.logger.debug("Полученные данные: \(jsonString, privacy: .public)")
                }
                do {
                    let decodedObject = try Self.sharedDecoder.decode(T.self, from: data)
                    completion(.success(decodedObject))
                } catch {
                    if let decodingError = error as? DecodingError {
                        Self.logger.error("Ошибка декодирования: \(decodingError), Данные: \(String(data: data, encoding: .utf8) ?? "", privacy: .public)")
                    } else {
                        Self.logger.error("Ошибка декодирования: \(error.localizedDescription), Данные: \(String(data: data, encoding: .utf8) ?? "", privacy: .public)")
                    }
                    completion(.failure(error))
                }
                
            case .failure(let error):
                Self.logger.error("Ошибка запроса: \(error.localizedDescription, privacy: .public)")
                completion(.failure(error))
            }
        }
        
        return task
    }
}

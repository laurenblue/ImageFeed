import Foundation

extension URLSession {
    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {
        let fulfillCompletionOnTheMainThread: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        let task = dataTask(with: request) { data, response, error in
            if let error {
                fulfillCompletionOnTheMainThread(
                    .failure(NetworkError.urlRequestError(error))
                )
                return
            }

            guard
                let data,
                let httpResponse = response as? HTTPURLResponse
            else {
                fulfillCompletionOnTheMainThread(
                    .failure(NetworkError.urlSessionError)
                )
                return
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                fulfillCompletionOnTheMainThread(
                    .failure(NetworkError.httpStatusCode(httpResponse.statusCode))
                )
                return
            }

            fulfillCompletionOnTheMainThread(.success(data))
        }
        return task
    }
}

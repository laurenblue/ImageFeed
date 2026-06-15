//
//  ImagesListService.swift
//  ImageFeed
//
//  Created by Sofia Noelle on 12.06.26.
// тут должны быть номер последней скачанной страницы lastLoadedPage, функция для получения очередной страницы fetchPhotosNextPage()

import Foundation
import CoreGraphics
import os

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

final class ImagesListService {
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.unsplash.ImageFeed",
        category: "ImagesListService"
    )
    
    private static let dateFormatter = ISO8601DateFormatter()
    
    private(set) var photos: [Photo] = []
    private let urlSession = URLSession.shared
    private var currentTask: URLSessionTask?
    private var lastLoadedPage: Int?
    
    private init() {}
    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)
        guard currentTask == nil else { return }
        
        let nextPage = (lastLoadedPage ?? 0) + 1
        guard let request = makePhotosRequest(page: nextPage) else {
            Self.logger.error("Ошибка: Не удалось создать URLRequest для списка фото")
            return
        }
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self = self else { return }
            self.currentTask = nil
            
            switch result {
            case .success(let photoResults):
                let newPhotos = photoResults.map { photoResult in
                    Photo(
                        id: photoResult.id,
                        size: CGSize(width: CGFloat(photoResult.width), height: CGFloat(photoResult.height)),
                        createdAt: photoResult.createdAt.flatMap { Self.dateFormatter.date(from: $0) },
                        welcomeDescription: photoResult.description,
                        thumbImageURL: photoResult.urls.thumb,
                        largeImageURL: photoResult.urls.full,
                        isLiked: photoResult.likedByUser
                    )
                }
                
                self.photos.append(contentsOf: newPhotos)
                self.lastLoadedPage = nextPage
                
                NotificationCenter.default.post(
                    name: ImagesListService.didChangeNotification,
                    object: self
                )
                
            case .failure(let error):
                Self.logger.error("[fetchPhotosNextPage]: Ошибка выполнения запроса: \(error.localizedDescription, privacy: .public)")
            }
        }
        
        currentTask = task
        task.resume()
    }
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        guard let request = makeLikeRequest(photoId: photoId, isLike: isLike) else {
            Self.logger.error("Ошибка: Не удалось создать URLRequest для лайка")
            return
        }
        
        let task = urlSession.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse,
                   !(200...299).contains(httpResponse.statusCode) {
                    let statusError = NSError(
                        domain: "ImagesListService",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Server returned status \(httpResponse.statusCode)"]
                    )
                    completion(.failure(statusError))
                    return
                }
                
                if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                    let photo = self.photos[index]
                    
                    let newPhoto = Photo(
                        id: photo.id,
                        size: photo.size,
                        createdAt: photo.createdAt,
                        welcomeDescription: photo.welcomeDescription,
                        thumbImageURL: photo.thumbImageURL,
                        largeImageURL: photo.largeImageURL,
                        isLiked: !photo.isLiked
                    )
                    
                    self.photos = self.photos.withReplaced(itemAt: index, newValue: newPhoto)
                }
                
                completion(.success(()))
            }
        }
        task.resume()
    }
    
    private func makePhotosRequest(page: Int) -> URLRequest? {
        let urlString = "https://api.unsplash.com/photos?page=\(page)&per_page=10"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        
        if let token = OAuth2TokenStorage.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func makeLikeRequest(photoId: String, isLike: Bool) -> URLRequest? {
        let urlString = "https://api.unsplash.com/photos/\(photoId)/like"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = isLike ? HTTPMethod.post.rawValue : HTTPMethod.delete.rawValue
        
        if let token = OAuth2TokenStorage.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    func clear() {
        photos = []
        lastLoadedPage = nil
        currentTask?.cancel()
        currentTask = nil
    }
}

extension Array {
    func withReplaced(itemAt index: Int, newValue: Element) -> [Element] {
        var mutableArray = self
        mutableArray[index] = newValue
        return mutableArray
    }
}

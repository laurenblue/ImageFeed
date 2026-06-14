//
//  ImagesListService.swift
//  ImageFeed
//
//  Created by Sofia Noelle on 12.06.26.
// тут должны быть номер последней скачанной страницы lastLoadedPage, функция для получения очередной страницы fetchPhotosNextPage()

import Foundation
import CoreGraphics

final class ImagesListService {
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    
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
            print("Ошибка: Не удалось создать URLRequest для списка фото")
            return
        }
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.currentTask = nil
                
                if let error = error {
                    print("[fetchPhotosNextPage]: Ошибка сети: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else { return }
                
                do {
                    let decoder = JSONDecoder()
                    let photoResults = try decoder.decode([PhotoResult].self, from: data)
                    let dateFormatter = ISO8601DateFormatter()
                    
                    let newPhotos = photoResults.map { photoResult in
                        Photo(
                            id: photoResult.id,
                            size: CGSize(width: CGFloat(photoResult.width), height: CGFloat(photoResult.height)),
                            createdAt: photoResult.createdAt != nil ? dateFormatter.date(from: photoResult.createdAt!) : nil,
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
                    
                } catch {
                    print("[fetchPhotosNextPage]: Ошибка декодирования JSON: \(error)")
                }
            }
        }
        
        currentTask = task
        task.resume()
    }
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        guard let request = makeLikeRequest(photoId: photoId, isLike: isLike) else {
            print("Ошибка: Не удалось создать URLRequest для лайка")
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
        request.httpMethod = "GET"
        
        if let token = OAuth2TokenStorage.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func makeLikeRequest(photoId: String, isLike: Bool) -> URLRequest? {
        let urlString = "https://api.unsplash.com/photos/\(photoId)/like"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        
        if let token = OAuth2TokenStorage.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
}

extension Array {
    func withReplaced(itemAt index: Int, newValue: Element) -> [Element] {
        var mutableArray = self
        mutableArray[index] = newValue
        return mutableArray
    }
}

//
//  ImagesListService.swift
//  ImageFeed
//
//  Created by Sofia Noelle on 12.06.26.
// тут должны быть номер последней скачанной страницы lastLoadedPage, функция для получения очередной страницы fetchPhotosNextPage()

import Foundation
import CoreGraphics

final class ImagesListService {
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    
    static let shared = ImagesListService()
    
    private(set) var photos: [Photo] = []
    
    private var lastLoadedPage: Int?
    private var currentTask: URLSessionTask?
    
    private let urlSession = URLSession.shared
    private let dateFormatter = ISO8601DateFormatter()
    
    private init() {}
    
    func fetchPhotosNextPage() {
        
        assert(Thread.isMainThread)
        
        guard currentTask == nil else {
            print("Лог: Запрос уже выполняется, отмена повторного вызова.")
            return
        }
        
        let nextPage = (lastLoadedPage ?? 0) + 1
        
        guard let request = makeRequest(page: nextPage) else {
            print("Ошибка: Не удалось создать URLRequest")
            return
        }
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                defer { self.currentTask = nil }
                
                if let error = error {
                    print("Ошибка сети: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else { return }
                
                do {
                    let decoder = JSONDecoder()
                    let photoResults = try decoder.decode([PhotoResult].self, from: data)
                    
                    let newPhotos = photoResults.map { photoResult in
                        Photo(
                            id: photoResult.id,
                            size: CGSize(width: photoResult.width, height: photoResult.height),
                            createdAt: self.dateFormatter.date(from: photoResult.createdAt ?? ""),
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
                    print("Лог: Успешно загружена страница \(nextPage). Всего фото: \(self.photos.count)")
                    
                } catch {
                    print("Ошибка декодирования JSON: \(error)")
                }
            }
        }
        
        self.currentTask = task
        task.resume()
    }
    
    private func makeRequest(page: Int) -> URLRequest? {
        guard var urlComponents = URLComponents(string: "https://api.unsplash.com/photos") else { return nil }
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "10")
        ]
        
        guard let url = urlComponents.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = OAuth2TokenStorage.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("Ошибка авторизации: Токен отсутствует в KeychainWrapper!")
        }
        
        return request
    }
}

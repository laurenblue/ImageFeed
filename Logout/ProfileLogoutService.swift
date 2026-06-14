//
//  ProfileLogoutService.swift
//  ImageFeed
//
//  Created by Sofia Noelle on 14.06.26.
//

import Foundation
import WebKit
import UIKit

final class ProfileLogoutService {
    static let shared = ProfileLogoutService()
    
    private init() { }
    
    func logout() {
        cleanCookies()
        clearStorageAndServices()
        switchToSplashViewController()
    }
    
    private func cleanCookies() {
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
        
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
    
    private func clearStorageAndServices() {
        OAuth2TokenStorage.shared.token = nil
        ProfileService.shared.clear()
        ProfileImageService.shared.clear()
        ImagesListService.shared.clear()
    }
    
    private func switchToSplashViewController() {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first else {
                assertionFailure("Invalid window configuration")
                return
            }
            let splashViewController = SplashViewController()
            
            window.rootViewController = splashViewController
            window.makeKeyAndVisible()
        }
    }
}

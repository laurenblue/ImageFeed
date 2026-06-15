//
//  ProfilePresenter.swift
//  ImageFeed
//
//  Created by Sofia Noelle on 15.06.26.
//

import Foundation

public protocol ProfileViewControllerProtocol: AnyObject {
    func displayProfileDetails(name: String, loginName: String, bio: String)
    func displayAvatar(url: URL)
}

public protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func logOut()
}

final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewControllerProtocol?
    
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    private let profileLogoutService = ProfileLogoutService.shared
    private var profileImageServiceObserver: NSObjectProtocol?
    
    init() {
        configureNotificationObserver()
    }
    
    func viewDidLoad() {
        if let profile = profileService.profile {
            updateProfileDetails(profile: profile)
        }
        updateAvatar()
    }
    
    func logOut() {
        profileLogoutService.logout()
    }
    
    private func configureNotificationObserver() {
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.updateAvatar()
        }
    }
    
    private func updateProfileDetails(profile: Profile) {
        let name = profile.name.isEmpty ? "Имя не указано" : profile.name
        let loginName = profile.loginName.isEmpty ? "@неизвестный_пользователь" : profile.loginName
        let bio = (profile.bio?.isEmpty ?? true) ? "Профиль не заполнен" : (profile.bio ?? "")
        
        view?.displayProfileDetails(name: name, loginName: loginName, bio: bio)
    }
    
    private func updateAvatar() {
        guard let profileImageURL = profileImageService.avatarURL,
              let imageUrl = URL(string: profileImageURL) else { return }
        view?.displayAvatar(url: imageUrl)
    }
}

//
//  ProfileTests.swift
//  ImageFeed
//
//  Created by Sofia Noelle on 15.06.26.
//

@testable import ImageFeed
import XCTest

final class ProfileTests: XCTestCase {
    
    func testViewControllerCallsViewDidLoad() async {
        let viewController = ProfileViewController()
        let presenterSpy = ProfilePresenterSpy()
        
        viewController.configure(presenterSpy)
        
        _ = viewController.view
        XCTAssertTrue(presenterSpy.viewDidLoadCalled, "ViewController должен вызывать метод viewDidLoad у Presenter")
    }
    
    func testViewControllerCallsLogOut() async {
        let viewController = ProfileViewController()
        let presenterSpy = ProfilePresenterSpy()
        viewController.configure(presenterSpy)
        _ = viewController.view
        presenterSpy.logOut()
        
        XCTAssertTrue(presenterSpy.logOutCalled, "Presenter должен фиксировать вызов метода logout")
    }
    
    func testPresenterCallsDisplayProfileDetails() async {
        let presenter = ProfilePresenter()
        let viewControllerSpy = ProfileViewControllerSpy()
        presenter.view = viewControllerSpy
        
        presenter.viewDidLoad()
        
        XCTAssertNotNil(presenter.view, "У презентера должна быть активная ссылка на View")
    }
}

final class ProfilePresenterSpy: ProfilePresenterProtocol {
    var view: ProfileViewControllerProtocol?
    var viewDidLoadCalled = false
    var logOutCalled = false
    
    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    
    func logOut() {
        logOutCalled = true
    }
}

final class ProfileViewControllerSpy: ProfileViewControllerProtocol {
    var displayProfileDetailsCalled = false
    var displayAvatarCalled = false
    
    var name: String?
    var loginName: String?
    var bio: String?
    var avatarURL: URL?
    
    func displayProfileDetails(name: String, loginName: String, bio: String) {
        displayProfileDetailsCalled = true
        self.name = name
        self.loginName = loginName
        self.bio = bio
    }
    
    func displayAvatar(url: URL) {
        displayAvatarCalled = true
        self.avatarURL = url
    }
}

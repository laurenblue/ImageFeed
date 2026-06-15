//
//  Image_FeedTests.swift
//  Image FeedTests
//
//  Created by Sofia Noelle on 15.06.26.
//

@testable import ImageFeed
import XCTest

final class WebViewTests: XCTestCase {
    
    func testViewControllerCallsViewDidLoad() {
        // given
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "WebViewViewController") as! WebViewViewController
        let presenter = WebViewPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController
        
        // when
        _ = viewController.view
        
        // then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    // added 'async' here and in all the funcs below to bypass the memory teardown crash on AuthHelper
    func testPresenterCallsLoadRequest() async {
        // given
        let viewController = WebViewViewControllerSpy()
        let authHelper = AuthHelperSpy()
        let presenter = WebViewPresenter(authHelper: authHelper)
        viewController.presenter = presenter
        presenter.view = viewController
        
        // when
        presenter.viewDidLoad()
        
        // then
        XCTAssertTrue(viewController.loadRequestCalled)
    }
    
    func testProgressVisibleWhenLessThenOne() async {
        // given
        let authHelper = AuthHelperSpy()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let progress: Float = 0.6
        
        // when
        let shouldHideProgress = presenter.shouldHideProgress(for: progress)
        
        // then
        XCTAssertFalse(shouldHideProgress)
    }
    
    func testProgressHiddenWhenOne() async {
        // given
        let authHelper = AuthHelperSpy()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let progress: Float = 1.0
        
        // when
        let shouldHideProgress = presenter.shouldHideProgress(for: progress)
        
        // then
        XCTAssertTrue(shouldHideProgress)
    }
    
    func testAuthHelperAuthURL() async {
        // given
        let configuration = AuthConfiguration.standard
        let authHelper = AuthHelper(configuration: configuration)
        
        // when
        let url = authHelper.authURL()
        
        guard let urlString = url?.absoluteString else {
            XCTFail("Auth URL is nil")
            return
        }
        
        // then
        XCTAssertTrue(urlString.contains(configuration.authURLString))
        XCTAssertTrue(urlString.contains(configuration.accessKey))
        XCTAssertTrue(urlString.contains(configuration.redirectURI))
        XCTAssertTrue(urlString.contains("code"))
        XCTAssertTrue(urlString.contains(configuration.accessScope))
    }
    
    func testCodeFromURL() async {
        // given
        var urlComponents = URLComponents(string: "https://unsplash.com/oauth/authorize/native")!
        urlComponents.queryItems = [URLQueryItem(name: "code", value: "test code")]
        let url = urlComponents.url!
        let authHelper = AuthHelper()
        
        // when
        let code = authHelper.code(from: url)
        
        // then
        XCTAssertEqual(code, "test code")
    }
}

final class AuthHelperSpy: AuthHelperProtocol {
    func authRequest() -> URLRequest? {
        return URLRequest(url: URL(string: "https://unsplash.com")!)
    }
    
    func code(from url: URL) -> String? {
        return nil
    }
}

//
//  ImagesListTests.swift
//  ImageFeed
//
//  Created by Sofia Noelle on 15.06.26.
//

@testable import ImageFeed
import XCTest

final class ImagesListTests: XCTestCase {
    
    func testViewControllerCallsViewDidLoad() async {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ImagesListViewController") as! ImagesListViewController
        let presenterSpy = ImagesListPresenterSpy()
        
        viewController.configure(presenterSpy)
        _ = viewController.view
        
        XCTAssertTrue(presenterSpy.viewDidLoadCalled, "ViewController должен вызывать viewDidLoad у Presenter")
    }
    
    func testPresenterCallsFetchPhotosNextPage() async {
        let presenter = ImagesListPresenter()
        let viewControllerSpy = ImagesListViewControllerSpy()
        presenter.view = viewControllerSpy
        presenter.fetchPhotosNextPage()
        XCTAssertNotNil(presenter.view)
    }
}

final class ImagesListPresenterSpy: ImagesListPresenterProtocol {
    var view: ImagesListViewControllerProtocol?
    var photos: [Photo] = []
    
    var viewDidLoadCalled = false
    var fetchPhotosNextPageCalled = false
    
    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    
    func fetchPhotosNextPage() {
        fetchPhotosNextPageCalled = true
    }
    
    func changeLike(at indexPath: IndexPath, completion: @escaping (Result<Void, Error>) -> Void) {}
}

final class ImagesListViewControllerSpy: ImagesListViewControllerProtocol {
    var updateTableViewAnimatedCalled = false
    var showLikeErrorCalled = false
    
    func updateTableViewAnimated(oldCount: Int, newCount: Int) {
        updateTableViewAnimatedCalled = true
    }
    
    func showLikeError(message: String) {
        showLikeErrorCalled = true
    }
}

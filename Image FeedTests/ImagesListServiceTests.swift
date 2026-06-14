//
//  Image_FeedTests.swift
//  Image FeedTests
//
//  Created by Sofia Noelle on 14.06.26.
//
import XCTest
@testable import ImageFeed

final class ImagesListServiceTests: XCTestCase {
    func testFetchPhotos() {
        let service = ImagesListService.shared
        
        let expectation = self.expectation(description: "Wait for Notification")
        
        NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        service.fetchPhotosNextPage()

        wait(for: [expectation], timeout: 10)

        XCTAssertEqual(service.photos.count, 10)
    }
}

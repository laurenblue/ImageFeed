//
//  WebViewViewControllerSpy.swift
//  ImageFeed
//
//  Created by Sofia Noelle on 15.06.26.
//

import ImageFeed
import Foundation

final class WebViewViewControllerSpy: NSObject, WebViewViewControllerProtocol {
    var presenter: ImageFeed.WebViewPresenterProtocol?
    var loadRequestCalled: Bool = false
    
    func load(request: URLRequest) {
        loadRequestCalled = true
    }
    
    func setProgressValue(_ newValue: Float) {}
    func setProgressHidden(_ isHidden: Bool) {}
}

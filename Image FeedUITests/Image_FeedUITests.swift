//
//  Image_FeedUITests.swift
//  Image FeedUITests
//
//  Created by Sofia Noelle on 15.06.26.
//

import XCTest

class Image_FeedUITests: XCTestCase {
    private let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["-testMode"]
        app.launch()
    }
    
    func testAuth() throws {
        app.buttons["Authenticate"].tap()
        
        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 15))
        let loginTextField = webView.textFields.firstMatch
        XCTAssertTrue(loginTextField.waitForExistence(timeout: 15), "Поле ввода e-mail не появилось")
        
        loginTextField.tap()
        loginTextField.typeText("<здесь должна быть почта>")
        webView.swipeUp()
        let passwordTextField = webView.secureTextFields.firstMatch
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 15), "Поле ввода пароля не появилось")
        passwordTextField.tap()
        sleep(1)
        passwordTextField.tap()
        passwordTextField.typeText("<а здесь должен быть пароль>")
        webView.swipeUp()
        let loginButton = webView.buttons["Login"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 15), "Кнопка Login не появилась")
        loginButton.tap()
        
        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        
        XCTAssertTrue(cell.waitForExistence(timeout: 10))
    }
    
    func testFeed() throws {
        let tablesQuery = app.tables
        XCTAssertTrue(tablesQuery.element.waitForExistence(timeout: 10), "Таблица не появилась на экране")
        let cellToLike = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(cellToLike.waitForExistence(timeout: 10), "Первая ячейка не загрузилась")
        
        let likeButton = cellToLike.buttons["Like Button"]
        XCTAssertTrue(likeButton.waitForExistence(timeout: 10), "Кнопка лайка не найдена в ячейке")
        likeButton.tap()
        sleep(2)
        let alert = app.alerts["Что-то пошло не так"]
        if alert.exists {
            alert.buttons["Ок"].tap()
            sleep(1)
        } else {
            likeButton.tap()
            sleep(2)
        }
        
        cellToLike.tap()
        sleep(3)
        
        let image = app.scrollViews.images.element(boundBy: 0)
        XCTAssertTrue(image.waitForExistence(timeout: 5))
        
        image.pinch(withScale: 3, velocity: 1)
        image.pinch(withScale: 0.5, velocity: -1)
        sleep(1)
        
        let navBackButtonWhiteButton = app.buttons["nav back button white"]
        XCTAssertTrue(navBackButtonWhiteButton.waitForExistence(timeout: 5), "Кнопка назад не найдена")
        navBackButtonWhiteButton.tap()
    }
    
    func testProfile() throws {
        sleep(3)
        
        let profileTabButton = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(profileTabButton.waitForExistence(timeout: 5))
        profileTabButton.tap()
        
        XCTAssertTrue(app.staticTexts.element(boundBy: 0).waitForExistence(timeout: 5))
        
        let logoutButton = app.buttons["logout button"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 5), "Кнопка logout button не найдена")
        logoutButton.tap()
        
        let alert = app.alerts["Bye bye!"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3), "Алерт 'Bye bye!' не появился")
        
        let yesButton = alert.buttons["Yes"]
        XCTAssertTrue(yesButton.exists, "Кнопка 'Yes' не найдена в алерте")
        yesButton.tap()
    }
}

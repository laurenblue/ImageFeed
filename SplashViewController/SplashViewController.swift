import UIKit

final class SplashViewController: UIViewController {
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    
    private let profileService = ProfileService.shared
    private let storage = OAuth2TokenStorage.shared
    private let oauth2Service = OAuth2Service.shared
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "splashScreenLogo")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: "ypBlack") ?? .black
        setupImageView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if NSClassFromString("XCTestCase") != nil {
            return
        }
        
        if let token = storage.token {
            fetchProfile(token: token)
        } else {
            presentAuthViewController()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    private func setupImageView() {
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func presentAuthViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let authNavigationController = storyboard.instantiateViewController(withIdentifier: "AuthNavigationController") as? UINavigationController,
              let authViewController = authNavigationController.viewControllers.first as? AuthViewController else {
            assertionFailure("Не удалось найти AuthNavigationController или AuthViewController")
            return
        }
        authViewController.delegate = self
        
        authNavigationController.modalPresentationStyle = .fullScreen
        present(authNavigationController, animated: true)
    }
    
    private func switchToTabBarController() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            assertionFailure("Invalid window configuration")
            return
        }
        
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        window.rootViewController = tabBarController
    }
    
    private func fetchProfile(token: String) {
        profileService.fetchProfile(token) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            
            guard let self else { return }
            
            switch result {
            case let .success(profile):
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                self.switchToTabBarController()
                
            case let .failure(error):
                print("[fetchProfile]: ProfileServiceError - \(error.localizedDescription)")
            }
        }
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func authViewController(_ vc: AuthViewController, didAuthenticateWithCode code: String) {
        UIBlockingProgressHUD.show()
        
        vc.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.oauth2Service.fetchOAuthToken(code) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let token):
                    self.storage.token = token
                    self.fetchProfile(token: token)
                case .failure(let error):
                    UIBlockingProgressHUD.dismiss()
                    print("[fetchOAuthTokenError]: \(error.localizedDescription)")
                }
            }
        }
    }
}

import UIKit
import Kingfisher
import os

final class ImagesListViewController: UIViewController, ImagesListViewControllerProtocol {
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.unsplash.ImageFeed",
        category: "ImagesListViewController"
    )
    
    @IBOutlet private var tableView: UITableView!
    
    private var presenter: ImagesListPresenterProtocol!
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    func configure(_ presenter: ImagesListPresenterProtocol) {
        self.presenter = presenter
        self.presenter.view = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if presenter == nil {
            configure(ImagesListPresenter())
        }
        
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        presenter.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("Invalid segue destination")
                return
            }
            let photo = presenter.photos[indexPath.row]
            viewController.largeImageURL = URL(string: photo.largeImageURL)
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    func updateTableViewAnimated(oldCount: Int, newCount: Int) {
        if oldCount != newCount {
            tableView.performBatchUpdates {
                let indexPaths = (oldCount..<newCount).map { i in
                    IndexPath(row: i, section: 0)
                }
                tableView.insertRows(at: indexPaths, with: .automatic)
            } completion: { _ in }
        }
    }
    
    func showLikeError(message: String) {
        let alert = UIAlertController(
            title: "Что-то пошло не так",
            message: "Не удалось изменить статус лайка: \(message)",
            preferredStyle: .alert
        )
        let action = UIAlertAction(title: "Ок", style: .default)
        alert.addAction(action)
        present(alert, animated: true)
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter.photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        
        imageListCell.delegate = self
        configCell(for: imageListCell, with: indexPath)
        return imageListCell
    }
}

extension ImagesListViewController {
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let photo = presenter.photos[indexPath.row]
        
        cell.cellImage.kf.indicatorType = .activity
        
        guard let url = URL(string: photo.thumbImageURL) else { return }
        let placeholder = UIImage(named: "stub")
        
        cell.cellImage.kf.setImage(with: url, placeholder: placeholder) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            case .failure(let error):
                Self.logger.error("Ошибка загрузки: \(error.localizedDescription, privacy: .public)")
            }
        }
        
        if let createdAt = photo.createdAt {
            cell.dateLabel.text = dateFormatter.string(from: createdAt)
        } else {
            cell.dateLabel.text = ""
        }
        
        cell.setIsLiked(photo.isLiked)
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = presenter.photos[indexPath.row]
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let imageWidth = photo.size.width
        let scale = imageViewWidth / imageWidth
        return photo.size.height * scale + imageInsets.top + imageInsets.bottom
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == presenter.photos.count {
            presenter.fetchPhotosNextPage()
        }
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        UIBlockingProgressHUD.show()
        
        presenter.changeLike(at: indexPath) { [weak self] result in
            guard let self else { return }
            UIBlockingProgressHUD.dismiss()
            
            switch result {
            case .success:
                let updatedPhoto = self.presenter.photos[indexPath.row]
                cell.setIsLiked(updatedPhoto.isLiked)
                
            case .failure(let error):
                self.showLikeError(message: error.localizedDescription)
            }
        }
    }
}

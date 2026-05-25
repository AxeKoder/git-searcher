import UIKit
import SnapKit

final class LoadingCollectionViewCell: UICollectionViewCell {
    private let activityIndicatorView = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimating() {
        activityIndicatorView.startAnimating()
    }

    private func configureViews() {
        contentView.addSubview(activityIndicatorView)

        activityIndicatorView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(52)
        }
    }
}


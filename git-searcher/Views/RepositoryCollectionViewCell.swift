import UIKit
import SnapKit

final class RepositoryCollectionViewCell: UICollectionViewCell {
    private let thumbnailImageView = UIImageView()
    private let titleLabel = UILabel()
    private let ownerLabel = UILabel()
    private let descriptionLabel = UILabel()
    private var imageTask: URLSessionDataTask?
    private var imageURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        imageURL = nil
        thumbnailImageView.image = UIImage(systemName: "shippingbox")
        titleLabel.text = nil
        ownerLabel.text = nil
        descriptionLabel.text = nil
    }

    func configure(with repository: GitHubRepository) {
        titleLabel.text = repository.name
        ownerLabel.text = repository.owner.login
        descriptionLabel.text = repository.descriptionText ?? "No description"
        loadImage(from: repository.owner.avatarURL)
    }

    private func configureViews() {
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true

        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 22
        thumbnailImageView.tintColor = .secondaryLabel
        thumbnailImageView.image = UIImage(systemName: "shippingbox")

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 1

        ownerLabel.font = .preferredFont(forTextStyle: .subheadline)
        ownerLabel.textColor = .secondaryLabel
        ownerLabel.numberOfLines = 1

        descriptionLabel.font = .preferredFont(forTextStyle: .footnote)
        descriptionLabel.textColor = .tertiaryLabel
        descriptionLabel.numberOfLines = 2

        let textStackView = UIStackView(arrangedSubviews: [titleLabel, ownerLabel, descriptionLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 4

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(textStackView)

        thumbnailImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.top.equalToSuperview().inset(14)
            $0.size.equalTo(44)
            $0.bottom.lessThanOrEqualToSuperview().inset(14)
        }

        textStackView.snp.makeConstraints {
            $0.leading.equalTo(thumbnailImageView.snp.trailing).offset(12)
            $0.top.bottom.equalToSuperview().inset(12)
            $0.trailing.equalToSuperview().inset(16)
        }
    }

    private func loadImage(from url: URL?) {
        imageTask?.cancel()
        imageURL = url
        thumbnailImageView.image = UIImage(systemName: "shippingbox")

        guard let url else { return }

        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }

            DispatchQueue.main.async { [weak self] in
                guard self?.imageURL == url else { return }
                self?.thumbnailImageView.image = image
            }
        }
        imageTask?.resume()
    }
}


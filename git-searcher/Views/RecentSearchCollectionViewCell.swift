import UIKit

final class RecentSearchCollectionViewCell: UICollectionViewCell {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter
    }()

    private let keywordLabel = UILabel()
    private let dateLabel = UILabel()
    private let deleteButton = UIButton(type: .system)

    var onDelete: (() -> Void)?

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
        keywordLabel.text = nil
        dateLabel.text = nil
        onDelete = nil
    }

    func configure(with recent: RecentSearch) {
        keywordLabel.text = recent.keyword
        dateLabel.text = Self.dateFormatter.string(from: recent.searchedAt)
    }

    private func configureViews() {
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true

        keywordLabel.font = .preferredFont(forTextStyle: .body)
        keywordLabel.numberOfLines = 1
        keywordLabel.translatesAutoresizingMaskIntoConstraints = false

        dateLabel.font = .preferredFont(forTextStyle: .caption1)
        dateLabel.textColor = .secondaryLabel
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        deleteButton.setTitle("삭제", for: .normal)
        deleteButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        let textStackView = UIStackView(arrangedSubviews: [keywordLabel, dateLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 4
        textStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(textStackView)
        contentView.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            textStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            textStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            deleteButton.leadingAnchor.constraint(greaterThanOrEqualTo: textStackView.trailingAnchor, constant: 12),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    @objc private func deleteButtonTapped() {
        onDelete?()
    }
}


import UIKit
import SnapKit

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

        dateLabel.font = .preferredFont(forTextStyle: .caption1)
        dateLabel.textColor = .secondaryLabel

        deleteButton.setTitle("삭제", for: .normal)
        deleteButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)

        let textStackView = UIStackView(arrangedSubviews: [keywordLabel, dateLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 4

        contentView.addSubview(textStackView)
        contentView.addSubview(deleteButton)

        textStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.top.bottom.equalToSuperview().inset(12)
        }

        deleteButton.snp.makeConstraints {
            $0.leading.greaterThanOrEqualTo(textStackView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
    }

    @objc private func deleteButtonTapped() {
        onDelete?()
    }
}


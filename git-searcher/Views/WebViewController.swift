import UIKit
import WebKit
import SnapKit

final class WebViewController: UIViewController {
    private let url: URL
    private let webView = WKWebView(frame: .zero)

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureWebView()
        webView.load(URLRequest(url: url))
    }

    private func configureNavigationBar() {
        title = url.host()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
    }

    private func configureWebView() {
        view.backgroundColor = .systemBackground
        view.addSubview(webView)

        webView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    @objc private func doneButtonTapped() {
        dismiss(animated: true)
    }
}


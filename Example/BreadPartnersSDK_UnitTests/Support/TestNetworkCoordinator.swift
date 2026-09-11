import Foundation

final class SharedTestURLProtocol: URLProtocol {
    static var responseData = Data()
    static var responseStatusCode = 200
    static var responseContentType = "application/json"
    static var capturedRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.capturedRequest = request
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: Self.responseStatusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": Self.responseContentType]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

actor TestNetworkCoordinator {
    static let shared = TestNetworkCoordinator()

    private var isBusy = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var isRegistered = false

    func withResponse(
        data: Data,
        statusCode: Int = 200,
        contentType: String = "application/json",
        operation: () async -> Void
    ) async {
        await acquire()
        configure(data: data, statusCode: statusCode, contentType: contentType)
        await operation()
        release()
    }

    func withRequest(operation: () async -> Void) async -> URLRequest? {
        await acquire()
        SharedTestURLProtocol.capturedRequest = nil
        registerIfNeeded()
        await operation()
        let capturedRequest = SharedTestURLProtocol.capturedRequest
        release()
        return capturedRequest
    }

    private func acquire() async {
        if !isBusy {
            isBusy = true
            return
        }

        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    private func release() {
        if waiters.isEmpty {
            isBusy = false
        } else {
            waiters.removeFirst().resume()
        }
    }

    private func configure(data: Data, statusCode: Int, contentType: String) {
        SharedTestURLProtocol.responseData = data
        SharedTestURLProtocol.responseStatusCode = statusCode
        SharedTestURLProtocol.responseContentType = contentType
        registerIfNeeded()
    }

    private func registerIfNeeded() {
        guard !isRegistered else { return }
        URLProtocol.registerClass(SharedTestURLProtocol.self)
        isRegistered = true
    }
}

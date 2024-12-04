import Foundation
import Combine

class LoginViewModel: ObservableObject {
    // Published properties for binding with the UI
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var shouldResetNavigation: Bool = false
    @Published var isFirstLogin: Bool = false // Tracks if it's the user's first login

    // Private properties
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "http://192.168.250.19:3000"
    
    // Initializer
    init() {
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication Check
    func checkAuthenticationStatus() {
        guard let accessToken = UserDefaults.standard.string(forKey: "accessToken"),
              let refreshToken = UserDefaults.standard.string(forKey: "refreshToken"),
              !accessToken.isEmpty else {
            self.isAuthenticated = false
            return
        }
        validateAndRefreshToken(accessToken: accessToken, refreshToken: refreshToken)
    }
    
    private func validateAndRefreshToken(accessToken: String, refreshToken: String) {
        guard let url = URL(string: "\(baseURL)/auth/refresh") else {
            handleError(LoginError.invalidURL)
            return
        }

        let requestBody = ["refreshToken": refreshToken]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(validateResponse)
            .decode(type: LoginResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.logout()
                    self?.handleError(error)
                }
            }, receiveValue: { [weak self] response in
                self?.handleSuccessfulTokenRefresh(response)
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Login
    func login() {
        guard !isLoading, isInputValid else {
            errorMessage = "Please provide a valid email and password."
            return
        }

        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            handleError(LoginError.invalidURL)
            return
        }

        let requestBody = ["email": email, "password": password]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(validateResponse)
            .decode(type: LoginResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            }, receiveValue: { [weak self] response in
                self?.handleSuccessfulLogin(response)
            })
            .store(in: &cancellables)
    }
    
    private func handleSuccessfulLogin(_ response: LoginResponse) {
        UserDefaults.standard.set(response.accestoken, forKey: "accessToken")
        UserDefaults.standard.set(response.refreshToken, forKey: "refreshToken")
        UserDefaults.standard.set(response.userId, forKey: "userId")
        UserDefaults.standard.set(response.isFirstLogin, forKey: "isFirstLogin")

        self.isFirstLogin = response.isFirstLogin
        self.isAuthenticated = true
        self.shouldResetNavigation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldResetNavigation = false
        }
    }
    
    // MARK: - Logout
    func logout() {
        UserDefaults.standard.removeObject(forKey: "accessToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "isFirstLogin")
        
        self.isAuthenticated = false
        self.email = ""
        self.password = ""
        self.errorMessage = nil
        self.shouldResetNavigation = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldResetNavigation = false
        }
    }
    
    // MARK: - Helpers
    private var isInputValid: Bool {
        return !email.isEmpty && email.contains("@") && password.count >= 6
    }

    private func handleError(_ error: Error) {
        self.errorMessage = (error as? LoginError)?.errorDescription ?? error.localizedDescription
    }
    
    private func validateResponse(data: Data, response: URLResponse) throws -> Data {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LoginError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            throw LoginError.invalidCredentials
        default:
            throw LoginError.serverError(httpResponse.statusCode)
        }
    }
    
    private func handleSuccessfulTokenRefresh(_ response: LoginResponse) {
        UserDefaults.standard.set(response.accestoken, forKey: "accessToken")
        UserDefaults.standard.set(response.refreshToken, forKey: "refreshToken")
        self.isAuthenticated = true
    }
}

// MARK: - Login Error Enum

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Сервис обновлений приложения «по воздуху» (Over-The-Air) для iOS и macOS
@MainActor
public final class UpdateManager: ObservableObject {
    public static let shared = UpdateManager()
    
    // MARK: - Константы репозитория
    private let repoOwner = "MaxRekkim"
    private let repoName = "BookParadise"
    public let otaManifestURLString = "https://raw.githubusercontent.com/MaxRekkim/BookParadise/main/manifest.plist"
    
    // MARK: - Состояние
    @Published public var isUpdateAvailable: Bool = false
    @Published public var latestVersion: String = ""
    @Published public var currentVersion: String = ""
    @Published public var releaseTitle: String = ""
    @Published public var releaseNotes: String = ""
    @Published public var isChecking: Bool = false
    @Published public var checkError: String? = nil
    @Published public var lastChecked: Date? = nil
    @Published public var isShowingUpdateSheet: Bool = false
    
    // Ссылки на дистрибутивы
    @Published public var ipaURL: URL? = nil
    @Published public var pkgURL: URL? = nil
    @Published public var dmgURL: URL? = nil
    @Published public var releasePageURL: URL? = nil
    
    private init() {
        self.currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "5.0.0"
    }
    
    // MARK: - Проверка обновлений через GitHub Releases API
    public func checkForUpdates(silent: Bool = false) async {
        if isChecking { return }
        isChecking = true
        checkError = nil
        
        let apiURLString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        guard let url = URL(string: apiURLString) else {
            isChecking = false
            return
        }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            request.setValue("BookParadise-App/\(currentVersion)", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                if !silent {
                    checkError = "Не удалось связаться с сервером обновлений"
                }
                isChecking = false
                return
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                isChecking = false
                return
            }
            
            let rawTagName = json["tag_name"] as? String ?? ""
            let parsedLatestVersion = rawTagName.hasPrefix("v") ? String(rawTagName.dropFirst()) : rawTagName
            let title = json["name"] as? String ?? "Новая версия \(parsedLatestVersion)"
            let body = json["body"] as? String ?? "Улучшения стабильности и новые возможности."
            let htmlUrlStr = json["html_url"] as? String ?? "https://github.com/\(repoOwner)/\(repoName)/releases/latest"
            
            self.latestVersion = parsedLatestVersion
            self.releaseTitle = title
            self.releaseNotes = body
            self.releasePageURL = URL(string: htmlUrlStr)
            self.lastChecked = Date()
            
            // Парсинг ассетов (IPA, PKG, DMG)
            if let assets = json["assets"] as? [[String: Any]] {
                for asset in assets {
                    guard let name = asset["name"] as? String,
                          let downloadStr = asset["browser_download_url"] as? String,
                          let downloadURL = URL(string: downloadStr) else { continue }
                    
                    if name.hasSuffix(".ipa") {
                        self.ipaURL = downloadURL
                    } else if name.hasSuffix(".pkg") {
                        self.pkgURL = downloadURL
                    } else if name.hasSuffix(".dmg") {
                        self.dmgURL = downloadURL
                    }
                }
            }
            
            let newer = isNewerVersion(remote: parsedLatestVersion, local: currentVersion)
            self.isUpdateAvailable = newer
            
            if newer && !silent {
                self.isShowingUpdateSheet = true
            }
        } catch {
            if !silent {
                self.checkError = error.localizedDescription
            }
        }
        
        isChecking = false
    }
    
    // MARK: - Сравнение версий (SemVer)
    private func isNewerVersion(remote: String, local: String) -> Bool {
        let remoteParts = remote.split(separator: ".").compactMap { Int($0) }
        let localParts = local.split(separator: ".").compactMap { Int($0) }
        
        let maxCount = max(remoteParts.count, localParts.count)
        for i in 0..<maxCount {
            let r = i < remoteParts.count ? remoteParts[i] : 0
            let l = i < localParts.count ? localParts[i] : 0
            if r > l { return true }
            if r < l { return false }
        }
        return false
    }
    
    // MARK: - Установка обновления «по воздуху» (OTA)
    public func installOTAUpdate() {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        // 1. На iOS вызываем нативный протокол Apple OTA itms-services
        let itmsString = "itms-services://?action=download-manifest&url=\(otaManifestURLString)"
        if let itmsURL = URL(string: itmsString) {
            UIApplication.shared.open(itmsURL, options: [:]) { success in
                if !success {
                    // Резервный переход на прямую загрузку IPA / страницу релиза
                    if let directURL = self.ipaURL ?? self.releasePageURL {
                        UIApplication.shared.open(directURL)
                    }
                }
            }
        }
        #elseif targetEnvironment(macCatalyst) || os(macOS)
        // 2. На macOS скачиваем и открываем .pkg инсталлятор или .dmg
        if let pkg = pkgURL {
            UIApplication.shared.open(pkg)
        } else if let dmg = dmgURL {
            UIApplication.shared.open(dmg)
        } else if let page = releasePageURL {
            UIApplication.shared.open(page)
        }
        #endif
    }
    
    // MARK: - Прямая установка через TrollStore / AltStore / Scarlet (если установлены)
    public func installViaTrollStore() {
        guard let ipa = ipaURL ?? URL(string: "https://github.com/\(repoOwner)/\(repoName)/releases/latest/download/BookParadise-\(latestVersion).ipa") else { return }
        
        let trollStoreURLString = "apple-magnifier://install?url=\(ipa.absoluteString)"
        if let tsURL = URL(string: trollStoreURLString) {
            #if canImport(UIKit)
            UIApplication.shared.open(tsURL, options: [:]) { success in
                if !success {
                    // Если схема apple-magnifier не открылась, пробуем trollstore://
                    if let altTS = URL(string: "trollstore://install?url=\(ipa.absoluteString)") {
                        UIApplication.shared.open(altTS)
                    }
                }
            }
            #endif
        }
    }
}

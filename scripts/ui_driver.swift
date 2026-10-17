import AppKit
import ApplicationServices
import Foundation

struct UIElementInfo {
    let element: AXUIElement
    let role: String
    let title: String
    let value: String
    let descriptionText: String
    let frame: CGRect
    
    var displayText: String {
        if !title.isEmpty { return title }
        if !value.isEmpty { return value }
        if !descriptionText.isEmpty { return descriptionText }
        return ""
    }
}

class UIDriver {
    let appElement: AXUIElement
    let windowElement: AXUIElement
    
    init?() {
        let pids = NSRunningApplication.runningApplications(withBundleIdentifier: "com.maxim.bookparadise")
        guard let app = pids.first else {
            print("❌ Ошибка: Приложение BookParadise не запущено.")
            return nil
        }
        self.appElement = AXUIElementCreateApplication(app.processIdentifier)
        
        var val: AnyObject?
        let err = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &val)
        guard err == .success, let windows = val as? [AXUIElement], let win = windows.first else {
            print("❌ Ошибка: Окно приложения не найдено.")
            return nil
        }
        self.windowElement = win
    }
    
    func getAttribute<T>(_ element: AXUIElement, _ attribute: String) -> T? {
        var val: AnyObject?
        let err = AXUIElementCopyAttributeValue(element, attribute as CFString, &val)
        if err == .success {
            return val as? T
        }
        return nil
    }
    
    func getFrame(_ element: AXUIElement) -> CGRect {
        var posVal: AnyObject?
        var sizeVal: AnyObject?
        var point = CGPoint.zero
        var size = CGSize.zero
        
        if AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posVal) == .success,
           let posVal = posVal as! AXValue? {
            AXValueGetValue(posVal, .cgPoint, &point)
        }
        if AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeVal) == .success,
           let sizeVal = sizeVal as! AXValue? {
            AXValueGetValue(sizeVal, .cgSize, &size)
        }
        return CGRect(origin: point, size: size)
    }
    
    func collectElements(from element: AXUIElement, depth: Int = 0) -> [UIElementInfo] {
        var results: [UIElementInfo] = []
        let role: String = getAttribute(element, kAXRoleAttribute as String) ?? "Unknown"
        let title: String = getAttribute(element, kAXTitleAttribute as String) ?? ""
        let val: String = getAttribute(element, kAXValueAttribute as String) ?? ""
        let desc: String = getAttribute(element, kAXDescriptionAttribute as String) ?? ""
        let frame = getFrame(element)
        
        let info = UIElementInfo(element: element, role: role, title: title, value: val, descriptionText: desc, frame: frame)
        results.append(info)
        
        if let children: [AXUIElement] = getAttribute(element, kAXChildrenAttribute as String) {
            for child in children {
                results.append(contentsOf: collectElements(from: child, depth: depth + 1))
            }
        }
        return results
    }
    
    func dumpTree() {
        let elements = collectElements(from: windowElement)
        print("📋 Найдено элементов интерфейса: \(elements.count)")
        for (i, el) in elements.enumerated() {
            if !el.displayText.isEmpty || el.role == "AXButton" || el.role == "AXImage" {
                let rectStr = "(\(Int(el.frame.origin.x)), \(Int(el.frame.origin.y)), \(Int(el.frame.width))x\(Int(el.frame.height)))"
                print("[\(i)] Role: \(el.role) | Text: \"\(el.displayText)\" | Bounds: \(rectStr)")
            }
        }
    }
    
    func click(text: String) -> Bool {
        let elements = collectElements(from: windowElement)
        let matches = elements.filter {
            $0.displayText.localizedCaseInsensitiveContains(text)
        }
        guard let target = matches.first else {
            print("❌ Элемент с текстом '\(text)' не найден.")
            return false
        }
        
        print("👉 Нажимаем на: [\(target.role)] \"\(target.displayText)\" at \(target.frame)")
        let err = AXUIElementPerformAction(target.element, kAXPressAction as CFString)
        if err == .success {
            print("✅ Нажатие выполнено успешно (kAXPressAction).")
            return true
        } else {
            // Резервный вариант: программный клик мышью по центру фрейма
            let center = CGPoint(x: target.frame.midX, y: target.frame.midY)
            simulateClick(at: center)
            print("✅ Симулирован клик курсором по координатам: \(center).")
            return true
        }
    }
    
    func simulateClick(at point: CGPoint) {
        let src = CGEventSource(stateID: .hidSystemState)
        let mouseDown = CGEvent(mouseEventSource: src, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left)
        let mouseUp = CGEvent(mouseEventSource: src, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)
        mouseDown?.post(tap: .cghidEventTap)
        usleep(50000)
        mouseUp?.post(tap: .cghidEventTap)
    }
    
    func inspectSpacing() {
        let elements = collectElements(from: windowElement)
        print("\n🔍 ========================================================")
        print("🔍 АНАЛИЗАТОР ВЕРСТКИ И ВЗАИМНЫХ ОТСТУПОВ (SPACING INSPECTOR)")
        print("🔍 ========================================================\n")
        
        // Ищем заголовки книг и авторов на экране
        var pairsFound = 0
        for i in 0..<elements.count {
            let titleEl = elements[i]
            guard titleEl.role == "AXStaticText", !titleEl.displayText.isEmpty else { continue }
            
            // Ищем автора рядом (ниже названия)
            for j in (i+1)..<min(elements.count, i + 8) {
                let authorEl = elements[j]
                guard authorEl.role == "AXStaticText", !authorEl.displayText.isEmpty else { continue }
                
                // Проверяем, что элементы расположены в одной колонке по X
                let xOverlap = abs(titleEl.frame.origin.x - authorEl.frame.origin.x)
                if xOverlap < 25 && authorEl.frame.minY >= titleEl.frame.maxY - 2 && (authorEl.frame.minY - titleEl.frame.maxY) < 60 {
                    pairsFound += 1
                    let gap = authorEl.frame.minY - titleEl.frame.maxY
                    
                    print("📖 Книга: «\(titleEl.displayText)»")
                    print("✍️ Автор:  \(authorEl.displayText)")
                    print("📏 Отступ между Названием и Автором: \(Int(gap)) pt")
                    
                    if gap > 16 {
                        print("  ⚠️ ДЕФЕКТ ВЕРСТКИ: Автор оторван от названия! Зазор \(Int(gap)) pt (норма: 4-8 pt).")
                    } else if gap < 2 {
                        print("  ⚠️ ДЕФЕКТ ВЕРСТКИ: Автор прилип вплотную к названию! Зазор \(Int(gap)) pt.")
                    } else {
                        print("  ✅ Идеальный отступ по HIG: \(Int(gap)) pt.")
                    }
                    print("--------------------------------------------------------")
                    break
                }
            }
        }
        
        if pairsFound == 0 {
            print("ℹ️ Текстовые пары 'Название -> Автор' на текущем экране не найдены.")
        }
    }
}

// CLI аргументы
guard let driver = UIDriver() else { exit(1) }

let args = CommandLine.arguments
if args.count > 1 {
    switch args[1] {
    case "dump":
        driver.dumpTree()
    case "click":
        let query = args.dropFirst(2).joined(separator: " ")
        _ = driver.click(text: query)
    case "inspect":
        driver.inspectSpacing()
    default:
        print("Неизвестная команда: \(args[1])")
    }
} else {
    driver.dumpTree()
    driver.inspectSpacing()
}

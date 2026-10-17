import Foundation
import CoreGraphics

/// Модель двухстраничного разворота и геометрии книги (Folio Spread Model)
/// Воссоздает оптику и пропорции физического книжного блока на экранах iPad и Mac Catalyst.
public struct FolioSpreadModel: Equatable {

    public enum SpreadMode: Equatable {
        case singlePage
        case twoPageSpread
    }

    public struct PageContent: Equatable {
        public let pageNumber: Int
        public let text: String
        public let isLeftPage: Bool
    }

    public let mode: SpreadMode
    public let leftPage: PageContent?
    public let rightPage: PageContent?
    public let spineGutterWidth: CGFloat
    public let spineShadowOpacity: Double
    public let runningHeaderLeft: String
    public let runningHeaderRight: String

    public init(
        mode: SpreadMode,
        leftPage: PageContent?,
        rightPage: PageContent?,
        spineGutterWidth: CGFloat = 32.0,
        spineShadowOpacity: Double = 0.22,
        runningHeaderLeft: String = "",
        runningHeaderRight: String = ""
    ) {
        self.mode = mode
        self.leftPage = leftPage
        self.rightPage = rightPage
        self.spineGutterWidth = spineGutterWidth
        self.spineShadowOpacity = spineShadowOpacity
        self.runningHeaderLeft = runningHeaderLeft
        self.runningHeaderRight = runningHeaderRight
    }

    /// Определяет режим отображения (одна страница vs двухстраничный разворот фолио)
    public static func determineMode(containerWidth: CGFloat, isRegularHorizontalSize: Bool) -> SpreadMode {
        if isRegularHorizontalSize || containerWidth >= 720.0 {
            return .twoPageSpread
        } else {
            return .singlePage
        }
    }

    /// Равномерно делит текст главы на две сбалансированные полосы набора
    public static func paginateSpread(
        chapterText: String,
        author: String,
        bookTitle: String,
        chapterTitle: String,
        currentPageBase: Int = 1
    ) -> FolioSpreadModel {
        let paragraphs = chapterText.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard paragraphs.count > 1 else {
            // Если текст короткий, помещаем на правую страницу (классическое начало главы)
            return FolioSpreadModel(
                mode: .twoPageSpread,
                leftPage: nil,
                rightPage: PageContent(pageNumber: currentPageBase, text: chapterText, isLeftPage: false),
                runningHeaderLeft: author.uppercased(),
                runningHeaderRight: chapterTitle.uppercased()
            )
        }

        let midIndex = max(1, paragraphs.count / 2)
        let leftText = paragraphs[0..<midIndex].joined(separator: "\n\n")
        let rightText = paragraphs[midIndex...].joined(separator: "\n\n")

        return FolioSpreadModel(
            mode: .twoPageSpread,
            leftPage: PageContent(pageNumber: currentPageBase, text: leftText, isLeftPage: true),
            rightPage: PageContent(pageNumber: currentPageBase + 1, text: rightText, isLeftPage: false),
            runningHeaderLeft: author.uppercased(),
            runningHeaderRight: chapterTitle.uppercased()
        )
    }
}

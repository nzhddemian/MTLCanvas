//
//  LayoutProp.swift
//  genie
//
//  Created by Demian on 10/09/2025.
//

import SwiftUI
import UIKit

public final class LayoutProp {
    private static var activeWindow: UIWindow? {
        guard Thread.isMainThread else { return nil }

        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first
    }

    public static var currentScreenBounds: CGRect {
        UIScreen.main.bounds
    }

    public static var screenSize: CGSize {
        currentScreenBounds.size
    }

    static var screenNativeSize: CGSize {
        UIScreen.main.nativeBounds.size
    }

    static var safeAreaInsets: UIEdgeInsets {
        activeWindow?.safeAreaInsets ?? .zero
    }

    static var screenWidth: CGFloat {
        screenSize.width
    }

    static var screenHeight: CGFloat {
        screenSize.height
    }

    static var screenHeightWithSafeArea: CGFloat {
        screenHeight + safeAreaInsetTop + safeAreaInsetBottom
    }

    static var safeAreaInsetTop: CGFloat {
        safeAreaInsets.top
    }

    static var safeAreaInsetBottom: CGFloat {
        safeAreaInsets.bottom
    }

    static var safeAreaVertical: CGFloat {
        safeAreaInsetTop + safeAreaInsetBottom
    }
}

//
//  ContentPopGestureDisabler.swift
//  UltraHFR
//
//  iOS 26 goes back when swiping right anywhere on the content, which is also the "swipe to
//  quote" gesture of the reader. While the reader is shown, going back stays available from
//  the screen edge only.
//

import SwiftUI
import UIKit

struct ContentPopGestureDisabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ controller: Controller, context: Context) {}

    final class Controller: UIViewController {
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            navigationController?.interactiveContentPopGestureRecognizer?.isEnabled = false
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            navigationController?.interactiveContentPopGestureRecognizer?.isEnabled = true
        }
    }
}

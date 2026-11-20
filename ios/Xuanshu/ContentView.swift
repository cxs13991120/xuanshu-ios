import SwiftUI

struct ContentView: View {
    private let paper = Color(red: 247 / 255, green: 240 / 255, blue: 227 / 255)

    var body: some View {
        ZStack {
            paper.ignoresSafeArea()
            XuanshuWebView()
                .ignoresSafeArea()
        }
    }
}

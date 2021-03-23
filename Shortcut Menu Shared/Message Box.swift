//
//  Miscellanous.swift
//  Wots4T
//
//  Created by Marc Shearer on 02/03/2021.
//

import SwiftUI

class MessageBox : ObservableObject {
    
    public static let shared = MessageBox()
    
    @Published public var text: String?
    public var closeButton = false
    public var showVersion = false
    public var completion: (()->())? = nil
    public var fontSize: CGFloat = 15.0

    public var isShown: Bool { MessageBox.shared.text != nil }
    
    public func show(_ text: String, fontSize: CGFloat = 15.0, closeButton: Bool = true, showVersion: Bool = false, hideAfter: TimeInterval? = nil, completion: (()->())? = nil) {
        MessageBox.shared.text = text
        MessageBox.shared.fontSize = fontSize
        MessageBox.shared.closeButton = closeButton
        MessageBox.shared.showVersion = showVersion
        MessageBox.shared.completion = completion
        if let hideAfter = hideAfter {
            Utility.executeAfter(delay: hideAfter) {
                self.hide()
            }
        }
    }
    
    public func show(closeButton: Bool = true) {
        MessageBox.shared.closeButton = closeButton
    }
    
    public func hide() {
        MessageBox.shared.text = nil
    }
    
}

struct MessageBoxView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var values = MessageBox.shared
    @State var showIcon = true
    
    var body: some View {
        ZStack {
            Palette.background.background
                .ignoresSafeArea()
            HStack(spacing: 0) {
                if showIcon {
                    Spacer().frame(width: 30)
                        VStack {
                        Spacer()
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image("shortcut").resizable().frame(width: 60, height: 60)
                                Spacer()
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .frame(width: 80)
                }
                Spacer()
                VStack(alignment: .center) {
                    Spacer()
                    Text("Shortcuts").font(.largeTitle).minimumScaleFactor(0.75)
                    if values.showVersion {
                        Text("Version \(Version.current.version) (\(Version.current.build)) \(MyApp.database.capitalized)").minimumScaleFactor(0.5)
                    }
                    if let message = $values.text.wrappedValue {
                        Spacer().frame(height: 30)
                        Text(message)
                            .multilineTextAlignment(.center)
                            .frame(maxHeight: 100)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(Font.system(size: values.fontSize))
                            .minimumScaleFactor(0.25)
                            .foregroundColor(Palette.background.text)
                    }
                    Spacer().frame(height: 30)
                    if MessageBox.shared.closeButton {
                        Text("Close")
                            .foregroundColor(Palette.highlightButton.text)
                            .font(.callout).minimumScaleFactor(0.5)
                            .frame(width: 100, height: 30)
                            .background(Palette.highlightButton.background)
                            .cornerRadius(15)
                            .onTapGesture {
                                values.completion?()
                                $values.text.wrappedValue = nil
                        }
                    } else {
                        Text("").frame(width: 100, height: 30)
                    }
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

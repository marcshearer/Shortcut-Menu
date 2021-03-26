//
//  Miscellanous.swift
//  Wots4T
//
//  Created by Marc Shearer on 02/03/2021.
//

import SwiftUI

class MessageBox : ObservableObject {
    
    enum Buttons {
        case close
        case confirmCancel
        case none
    }
    
    public static let shared = MessageBox()
    
    @Published public var text: String?
    public var buttons: Buttons = .close
    public var confirmButton = false
    public var showIcon = true
    public var showVersion = false
    public var completion: ((Bool)->())? = nil
    public var fontSize: CGFloat = 15.0

    public var isShown: Bool { MessageBox.shared.text != nil }
    
    public func show(_ text: String, fontSize: CGFloat = 15.0, buttons: Buttons = .close, showVersion: Bool = false, showIcon: Bool = true, hideAfter: TimeInterval? = nil, completion: ((Bool)->())? = nil) {
        MessageBox.shared.text = text
        MessageBox.shared.fontSize = fontSize
        MessageBox.shared.buttons = buttons
        MessageBox.shared.showVersion = showVersion
        MessageBox.shared.showIcon = showIcon
        MessageBox.shared.completion = completion
        if let hideAfter = hideAfter {
            Utility.executeAfter(delay: hideAfter) {
                self.hide()
            }
        }
    }
    
    public func show(closeButton: Bool = true) {
        MessageBox.shared.buttons = (closeButton ? .close : .none)
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
                if showIcon && values.showIcon {
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
                    let buttons = MessageBox.shared.buttons
                    if buttons != .none {
                        HStack {
                            let closeColor = (buttons == .confirmCancel ? Palette.enabledButton : Palette.highlightButton)
                            Text(buttons == .close ? "Close" : "Cancel")
                                .foregroundColor(closeColor.text)
                                .font(.callout).minimumScaleFactor(0.5)
                                .frame(width: 100, height: 30)
                                .background(closeColor.background)
                                .cornerRadius(15)
                                .onTapGesture {
                                    values.completion?(false)
                                    $values.text.wrappedValue = nil
                                }
                            if buttons == .confirmCancel {
                                Text("Confirm")
                                    .foregroundColor(Palette.highlightButton.text)
                                    .font(.callout).minimumScaleFactor(0.5)
                                    .frame(width: 100, height: 30)
                                    .background(Palette.highlightButton.background)
                                    .cornerRadius(15)
                                    .onTapGesture {
                                        values.completion?(true)
                                        $values.text.wrappedValue = nil
                                    }
                            }
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

//
// Banner.swift
//  Wots4T
//
//  Created by Marc Shearer on 05/02/2021.
//

import SwiftUI

struct BannerOption {
    let image: AnyView?
    let text: String?
    let hidden: (()->(Bool))?
    let action: ()->()
    
    init(image: AnyView? = nil, text: String? = nil, hidden: (()->(Bool))? = nil, action: @escaping ()->()) {
        self.image = image
        self.text = text
        self.hidden = hidden
        self.action = action
    }
}

enum BannerOptionMode {
    case menu
    case buttons
    case none
}

struct Banner: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @Binding var title: String
    var color: PaletteColor = Palette.banner
    var back: Bool = true
    var backEnabled: Binding<Bool>?
    var backAction: (()->())?
    var minimumBanner: Bool = false
    var optionMode: BannerOptionMode = .none
    var menuImage: AnyView? = nil
    var options: [BannerOption]? = nil
       
    var body: some View {
        ZStack {
            color.background
                .ignoresSafeArea()
            VStack {
                Spacer()
                HStack {
                    Spacer().frame(width: 16)
                    if back {
                        backButton
                    }
                    Text(title).font(minimumBanner ? Font.headline : Font.largeTitle).bold().foregroundColor(color.text)
                    Spacer()
                    switch optionMode {
                    case .menu:
                        Banner_Menu(image: menuImage, minimumBanner: minimumBanner, options: options!)
                    case .buttons:
                        Banner_Buttons(options: options!)
                    default:
                        Spacer()
                    }
                }
                Spacer().frame(height: bannerBottom)
            }
        }
        .frame(height: (minimumBanner ? minimumBannerHeight :  bannerHeight + bannerBottom))
    }
    
    var backButton: some View {
        let enabled = backEnabled?.wrappedValue ?? true
        return Button(action: {
            if enabled {
                backAction?()
                self.presentationMode.wrappedValue.dismiss()
            }
        }, label: {
            HStack {
                if minimumBanner {
                    Image(systemName: "xmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(color.strongText.opacity(enabled ? 1.0 : 0.5))
                } else {
                    Image(systemName: "chevron.left")
                        .font(.largeTitle)
                        .foregroundColor(Palette.bannerBackButton.opacity(enabled ? 1.0 : 0.5))
                }
            }
        })
        .buttonStyle(PlainButtonStyle())
        .disabled(!(enabled))
    }
}

struct Banner_Menu : View {
    var image: AnyView?
    var minimumBanner: Bool
    var options: [BannerOption]
    let menuStyle = DefaultMenuStyle()

    var body: some View {
        let menuLabel = image ?? AnyView(Image(systemName: "line.horizontal.3").foregroundColor(Palette.banner.text).font(minimumBanner ? Font.headline : Font.largeTitle))
        Menu {
            ForEach(0..<(options.count)) { (index) in
                let option = options[index]
                Button {
                    option.action()
                } label: {
                    if option.image != nil {
                        option.image
                    }
                    if option.image != nil && option.text != nil {
                        Spacer().frame(width: 16)
                    }
                    if option.text != nil {
                        Text(option.text!)
                            .minimumScaleFactor(0.5)
                    }
                }
                .menuStyle(menuStyle)
            }
        } label: {
            menuLabel
        }
        Spacer().frame(width: 16)
    }
}

struct Banner_Buttons : View {
    var options: [BannerOption]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<(options.count)) { (index) in
                let option = options[index]
                if !(option.hidden?() ?? false) {
                    Button {
                        option.action()
                    } label: {
                        if option.image != nil {
                            option.image
                        }
                        if option.image != nil && option.text != nil {
                            Spacer().frame(width: 16)
                        }
                        if option.text != nil {
                            Text(option.text ?? "")
                        }
                    }
                }
            }
        }
        Spacer().frame(width: 16)
    }
}

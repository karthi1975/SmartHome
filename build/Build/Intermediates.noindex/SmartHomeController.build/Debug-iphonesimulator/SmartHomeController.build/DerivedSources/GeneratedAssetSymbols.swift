import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "AVR_Red_Smarthome" asset catalog image resource.
    static let avrRedSmarthome = DeveloperToolsSupport.ImageResource(name: "AVR_Red_Smarthome", bundle: resourceBundle)

    /// The "AVR_Smarthome" asset catalog image resource.
    static let avrSmarthome = DeveloperToolsSupport.ImageResource(name: "AVR_Smarthome", bundle: resourceBundle)

    /// The "Addmore_Red_Smarthome" asset catalog image resource.
    static let addmoreRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Addmore_Red_Smarthome", bundle: resourceBundle)

    /// The "Addmore_Smarthome" asset catalog image resource.
    static let addmoreSmarthome = DeveloperToolsSupport.ImageResource(name: "Addmore_Smarthome", bundle: resourceBundle)

    /// The "Away_Black_Smarthome" asset catalog image resource.
    static let awayBlackSmarthome = DeveloperToolsSupport.ImageResource(name: "Away_Black_Smarthome", bundle: resourceBundle)

    /// The "Away_Red_Smarthome" asset catalog image resource.
    static let awayRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Away_Red_Smarthome", bundle: resourceBundle)

    /// The "Away_Smarthome" asset catalog image resource.
    static let awaySmarthome = DeveloperToolsSupport.ImageResource(name: "Away_Smarthome", bundle: resourceBundle)

    /// The "Backyard_Red_Smarthome" asset catalog image resource.
    static let backyardRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Backyard_Red_Smarthome", bundle: resourceBundle)

    /// The "Backyard_Smarthome" asset catalog image resource.
    static let backyardSmarthome = DeveloperToolsSupport.ImageResource(name: "Backyard_Smarthome", bundle: resourceBundle)

    /// The "Bedroom_Red_Smarthome" asset catalog image resource.
    static let bedroomRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Bedroom_Red_Smarthome", bundle: resourceBundle)

    /// The "Bedroom_Smarthome" asset catalog image resource.
    static let bedroomSmarthome = DeveloperToolsSupport.ImageResource(name: "Bedroom_Smarthome", bundle: resourceBundle)

    /// The "Bedtime_Black_Smarthome" asset catalog image resource.
    static let bedtimeBlackSmarthome = DeveloperToolsSupport.ImageResource(name: "Bedtime_Black_Smarthome", bundle: resourceBundle)

    /// The "Bedtime_Red_Smarthome" asset catalog image resource.
    static let bedtimeRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Bedtime_Red_Smarthome", bundle: resourceBundle)

    /// The "Bedtime_Smarthome" asset catalog image resource.
    static let bedtimeSmarthome = DeveloperToolsSupport.ImageResource(name: "Bedtime_Smarthome", bundle: resourceBundle)

    /// The "BlindsIcon_Smarthome" asset catalog image resource.
    static let blindsIconSmarthome = DeveloperToolsSupport.ImageResource(name: "BlindsIcon_Smarthome", bundle: resourceBundle)

    /// The "Blinds_Red_Smarthome" asset catalog image resource.
    static let blindsRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Blinds_Red_Smarthome", bundle: resourceBundle)

    /// The "Blinds_Smarthome" asset catalog image resource.
    static let blindsSmarthome = DeveloperToolsSupport.ImageResource(name: "Blinds_Smarthome", bundle: resourceBundle)

    /// The "ButtonBase_Smarthome" asset catalog image resource.
    static let buttonBaseSmarthome = DeveloperToolsSupport.ImageResource(name: "ButtonBase_Smarthome", bundle: resourceBundle)

    /// The "Cameras_Red_Smarthome" asset catalog image resource.
    static let camerasRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Cameras_Red_Smarthome", bundle: resourceBundle)

    /// The "Cameras_Smarthome" asset catalog image resource.
    static let camerasSmarthome = DeveloperToolsSupport.ImageResource(name: "Cameras_Smarthome", bundle: resourceBundle)

    /// The "CoffeeMaker_Red_Smarthome" asset catalog image resource.
    static let coffeeMakerRedSmarthome = DeveloperToolsSupport.ImageResource(name: "CoffeeMaker_Red_Smarthome", bundle: resourceBundle)

    /// The "CoffeeMaker_Smarthome" asset catalog image resource.
    static let coffeeMakerSmarthome = DeveloperToolsSupport.ImageResource(name: "CoffeeMaker_Smarthome", bundle: resourceBundle)

    /// The "DeviceSelection_Base_Smarthome" asset catalog image resource.
    static let deviceSelectionBaseSmarthome = DeveloperToolsSupport.ImageResource(name: "DeviceSelection_Base_Smarthome", bundle: resourceBundle)

    /// The "Dishwasher_Red_Smarthome" asset catalog image resource.
    static let dishwasherRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Dishwasher_Red_Smarthome", bundle: resourceBundle)

    /// The "Dishwasher_Smarthome" asset catalog image resource.
    static let dishwasherSmarthome = DeveloperToolsSupport.ImageResource(name: "Dishwasher_Smarthome", bundle: resourceBundle)

    /// The "DownArrow_Smarthome" asset catalog image resource.
    static let downArrowSmarthome = DeveloperToolsSupport.ImageResource(name: "DownArrow_Smarthome", bundle: resourceBundle)

    /// The "DownMaxArrow_Smarthome" asset catalog image resource.
    static let downMaxArrowSmarthome = DeveloperToolsSupport.ImageResource(name: "DownMaxArrow_Smarthome", bundle: resourceBundle)

    /// The "DownMax_Smarthome" asset catalog image resource.
    static let downMaxSmarthome = DeveloperToolsSupport.ImageResource(name: "DownMax_Smarthome", bundle: resourceBundle)

    /// The "Down_Smarthome" asset catalog image resource.
    static let downSmarthome = DeveloperToolsSupport.ImageResource(name: "Down_Smarthome", bundle: resourceBundle)

    /// The "Dryer_Red_Smarthome" asset catalog image resource.
    static let dryerRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Dryer_Red_Smarthome", bundle: resourceBundle)

    /// The "Dryer_Smarthome" asset catalog image resource.
    static let dryerSmarthome = DeveloperToolsSupport.ImageResource(name: "Dryer_Smarthome", bundle: resourceBundle)

    /// The "Elevator_Red_Smarthome" asset catalog image resource.
    static let elevatorRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Elevator_Red_Smarthome", bundle: resourceBundle)

    /// The "Elevator_Smarthome" asset catalog image resource.
    static let elevatorSmarthome = DeveloperToolsSupport.ImageResource(name: "Elevator_Smarthome", bundle: resourceBundle)

    /// The "Entrance_Red_Smarthome" asset catalog image resource.
    static let entranceRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Entrance_Red_Smarthome", bundle: resourceBundle)

    /// The "Entrance_Smarthome" asset catalog image resource.
    static let entranceSmarthome = DeveloperToolsSupport.ImageResource(name: "Entrance_Smarthome", bundle: resourceBundle)

    /// The "Fridge_Red_Smarthome" asset catalog image resource.
    static let fridgeRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Fridge_Red_Smarthome", bundle: resourceBundle)

    /// The "Fridge_Smarthome" asset catalog image resource.
    static let fridgeSmarthome = DeveloperToolsSupport.ImageResource(name: "Fridge_Smarthome", bundle: resourceBundle)

    /// The "Garage_Red_Smarthome" asset catalog image resource.
    static let garageRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Garage_Red_Smarthome", bundle: resourceBundle)

    /// The "Garage_Smarthome" asset catalog image resource.
    static let garageSmarthome = DeveloperToolsSupport.ImageResource(name: "Garage_Smarthome", bundle: resourceBundle)

    /// The "Home_Red_Smarthome" asset catalog image resource.
    static let homeRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Home_Red_Smarthome", bundle: resourceBundle)

    /// The "Home_Smarthome" asset catalog image resource.
    static let homeSmarthome = DeveloperToolsSupport.ImageResource(name: "Home_Smarthome", bundle: resourceBundle)

    /// The "Kitchen_Red_Smarthome" asset catalog image resource.
    static let kitchenRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Kitchen_Red_Smarthome", bundle: resourceBundle)

    /// The "Kitchen_Smarthome" asset catalog image resource.
    static let kitchenSmarthome = DeveloperToolsSupport.ImageResource(name: "Kitchen_Smarthome", bundle: resourceBundle)

    /// The "Laundry_Red_Smarthome" asset catalog image resource.
    static let laundryRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Laundry_Red_Smarthome", bundle: resourceBundle)

    /// The "Laundry_Smarthome" asset catalog image resource.
    static let laundrySmarthome = DeveloperToolsSupport.ImageResource(name: "Laundry_Smarthome", bundle: resourceBundle)

    /// The "LightIcon_Smarthome" asset catalog image resource.
    static let lightIconSmarthome = DeveloperToolsSupport.ImageResource(name: "LightIcon_Smarthome", bundle: resourceBundle)

    /// The "Lights_Red_Smarthome" asset catalog image resource.
    static let lightsRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Lights_Red_Smarthome", bundle: resourceBundle)

    /// The "Lights_Smarthome" asset catalog image resource.
    static let lightsSmarthome = DeveloperToolsSupport.ImageResource(name: "Lights_Smarthome", bundle: resourceBundle)

    /// The "LivingRm_Red_Smarthome" asset catalog image resource.
    static let livingRmRedSmarthome = DeveloperToolsSupport.ImageResource(name: "LivingRm_Red_Smarthome", bundle: resourceBundle)

    /// The "LivingRm_Smarthome" asset catalog image resource.
    static let livingRmSmarthome = DeveloperToolsSupport.ImageResource(name: "LivingRm_Smarthome", bundle: resourceBundle)

    /// The "Lock_Red_Smarthome" asset catalog image resource.
    static let lockRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Lock_Red_Smarthome", bundle: resourceBundle)

    /// The "Lock_Smarthome" asset catalog image resource.
    static let lockSmarthome = DeveloperToolsSupport.ImageResource(name: "Lock_Smarthome", bundle: resourceBundle)

    /// The "MasterBedrm_Red_Smarthome" asset catalog image resource.
    static let masterBedrmRedSmarthome = DeveloperToolsSupport.ImageResource(name: "MasterBedrm_Red_Smarthome", bundle: resourceBundle)

    /// The "MasterBedrm_Smarthome" asset catalog image resource.
    static let masterBedrmSmarthome = DeveloperToolsSupport.ImageResource(name: "MasterBedrm_Smarthome", bundle: resourceBundle)

    /// The "Morning_Black_Smarthome" asset catalog image resource.
    static let morningBlackSmarthome = DeveloperToolsSupport.ImageResource(name: "Morning_Black_Smarthome", bundle: resourceBundle)

    /// The "Morning_Red_Smarthome" asset catalog image resource.
    static let morningRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Morning_Red_Smarthome", bundle: resourceBundle)

    /// The "Morning_Smarthome" asset catalog image resource.
    static let morningSmarthome = DeveloperToolsSupport.ImageResource(name: "Morning_Smarthome", bundle: resourceBundle)

    /// The "Music_Red_Smarthome" asset catalog image resource.
    static let musicRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Music_Red_Smarthome", bundle: resourceBundle)

    /// The "Music_Smarthome" asset catalog image resource.
    static let musicSmarthome = DeveloperToolsSupport.ImageResource(name: "Music_Smarthome", bundle: resourceBundle)

    /// The "Mute_Red_Smarthome" asset catalog image resource.
    static let muteRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Mute_Red_Smarthome", bundle: resourceBundle)

    /// The "Mute_Smarthome" asset catalog image resource.
    static let muteSmarthome = DeveloperToolsSupport.ImageResource(name: "Mute_Smarthome", bundle: resourceBundle)

    /// The "Nursery_Red_Smarthome" asset catalog image resource.
    static let nurseryRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Nursery_Red_Smarthome", bundle: resourceBundle)

    /// The "Nursery_Smarthome" asset catalog image resource.
    static let nurserySmarthome = DeveloperToolsSupport.ImageResource(name: "Nursery_Smarthome", bundle: resourceBundle)

    /// The "Outside_Red_Smarthome" asset catalog image resource.
    static let outsideRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Outside_Red_Smarthome", bundle: resourceBundle)

    /// The "Outside_Smarthome" asset catalog image resource.
    static let outsideSmarthome = DeveloperToolsSupport.ImageResource(name: "Outside_Smarthome", bundle: resourceBundle)

    /// The "Oven_Red_Smarthome" asset catalog image resource.
    static let ovenRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Oven_Red_Smarthome", bundle: resourceBundle)

    /// The "Oven_Smarthome" asset catalog image resource.
    static let ovenSmarthome = DeveloperToolsSupport.ImageResource(name: "Oven_Smarthome", bundle: resourceBundle)

    /// The "Playroom_Red_Smarthome" asset catalog image resource.
    static let playroomRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Playroom_Red_Smarthome", bundle: resourceBundle)

    /// The "Playroom_Smarthome" asset catalog image resource.
    static let playroomSmarthome = DeveloperToolsSupport.ImageResource(name: "Playroom_Smarthome", bundle: resourceBundle)

    /// The "Power_Red_Smarthome" asset catalog image resource.
    static let powerRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Power_Red_Smarthome", bundle: resourceBundle)

    /// The "Power_Smarthome" asset catalog image resource.
    static let powerSmarthome = DeveloperToolsSupport.ImageResource(name: "Power_Smarthome", bundle: resourceBundle)

    /// The "Reading_Black_Smarthome" asset catalog image resource.
    static let readingBlackSmarthome = DeveloperToolsSupport.ImageResource(name: "Reading_Black_Smarthome", bundle: resourceBundle)

    /// The "Reading_Red_Smarthome" asset catalog image resource.
    static let readingRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Reading_Red_Smarthome", bundle: resourceBundle)

    /// The "Reading_Smarthome" asset catalog image resource.
    static let readingSmarthome = DeveloperToolsSupport.ImageResource(name: "Reading_Smarthome", bundle: resourceBundle)

    /// The "ScenesBackground_Smarthome" asset catalog image resource.
    static let scenesBackgroundSmarthome = DeveloperToolsSupport.ImageResource(name: "ScenesBackground_Smarthome", bundle: resourceBundle)

    /// The "SidebarIcon_Smarthome" asset catalog image resource.
    static let sidebarIconSmarthome = DeveloperToolsSupport.ImageResource(name: "SidebarIcon_Smarthome", bundle: resourceBundle)

    /// The "Sidebar_Base_Smarthome" asset catalog image resource.
    static let sidebarBaseSmarthome = DeveloperToolsSupport.ImageResource(name: "Sidebar_Base_Smarthome", bundle: resourceBundle)

    /// The "Smart HomeWHT" asset catalog image resource.
    static let smartHomeWHT = DeveloperToolsSupport.ImageResource(name: "Smart HomeWHT", bundle: resourceBundle)

    /// The "Soft_Red_Smarthome" asset catalog image resource.
    static let softRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Soft_Red_Smarthome", bundle: resourceBundle)

    /// The "Soft_Smarthome" asset catalog image resource.
    static let softSmarthome = DeveloperToolsSupport.ImageResource(name: "Soft_Smarthome", bundle: resourceBundle)

    /// The "Stove_Red_Smarthome" asset catalog image resource.
    static let stoveRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Stove_Red_Smarthome", bundle: resourceBundle)

    /// The "Stove_Smarthome" asset catalog image resource.
    static let stoveSmarthome = DeveloperToolsSupport.ImageResource(name: "Stove_Smarthome", bundle: resourceBundle)

    /// The "Streamer_Red_Smarthome" asset catalog image resource.
    static let streamerRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Streamer_Red_Smarthome", bundle: resourceBundle)

    /// The "Streamer_Smarthome" asset catalog image resource.
    static let streamerSmarthome = DeveloperToolsSupport.ImageResource(name: "Streamer_Smarthome", bundle: resourceBundle)

    /// The "Support_Red_Smarthome" asset catalog image resource.
    static let supportRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Support_Red_Smarthome", bundle: resourceBundle)

    /// The "Support_Smarthome" asset catalog image resource.
    static let supportSmarthome = DeveloperToolsSupport.ImageResource(name: "Support_Smarthome", bundle: resourceBundle)

    /// The "TVTime_Smarthome" asset catalog image resource.
    static let tvTimeSmarthome = DeveloperToolsSupport.ImageResource(name: "TVTime_Smarthome", bundle: resourceBundle)

    /// The "TV_Black_Smarthome" asset catalog image resource.
    static let tvBlackSmarthome = DeveloperToolsSupport.ImageResource(name: "TV_Black_Smarthome", bundle: resourceBundle)

    /// The "TV_Red_Smarthome" asset catalog image resource.
    static let tvRedSmarthome = DeveloperToolsSupport.ImageResource(name: "TV_Red_Smarthome", bundle: resourceBundle)

    /// The "TV_Smarthome" asset catalog image resource.
    static let tvSmarthome = DeveloperToolsSupport.ImageResource(name: "TV_Smarthome", bundle: resourceBundle)

    /// The "Temp_Red_Smarthome" asset catalog image resource.
    static let tempRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Temp_Red_Smarthome", bundle: resourceBundle)

    /// The "Temp__Smarthome" asset catalog image resource.
    static let tempSmarthome = DeveloperToolsSupport.ImageResource(name: "Temp__Smarthome", bundle: resourceBundle)

    /// The "ToggleOn_Smarthome" asset catalog image resource.
    static let toggleOnSmarthome = DeveloperToolsSupport.ImageResource(name: "ToggleOn_Smarthome", bundle: resourceBundle)

    /// The "UpArrow_Smarthome" asset catalog image resource.
    static let upArrowSmarthome = DeveloperToolsSupport.ImageResource(name: "UpArrow_Smarthome", bundle: resourceBundle)

    /// The "UpMaxArrow_Smarthome" asset catalog image resource.
    static let upMaxArrowSmarthome = DeveloperToolsSupport.ImageResource(name: "UpMaxArrow_Smarthome", bundle: resourceBundle)

    /// The "UpMax_Smarthome" asset catalog image resource.
    static let upMaxSmarthome = DeveloperToolsSupport.ImageResource(name: "UpMax_Smarthome", bundle: resourceBundle)

    /// The "Up_Smarthome" asset catalog image resource.
    static let upSmarthome = DeveloperToolsSupport.ImageResource(name: "Up_Smarthome", bundle: resourceBundle)

    /// The "Washer_Red_Smarthome" asset catalog image resource.
    static let washerRedSmarthome = DeveloperToolsSupport.ImageResource(name: "Washer_Red_Smarthome", bundle: resourceBundle)

    /// The "Washer_Smarthome" asset catalog image resource.
    static let washerSmarthome = DeveloperToolsSupport.ImageResource(name: "Washer_Smarthome", bundle: resourceBundle)

    /// The "tetradapt" asset catalog image resource.
    static let tetradapt = DeveloperToolsSupport.ImageResource(name: "tetradapt", bundle: resourceBundle)

    /// The "tetradapt-logo" asset catalog image resource.
    static let tetradaptLogo = DeveloperToolsSupport.ImageResource(name: "tetradapt-logo", bundle: resourceBundle)

    /// The "tetradapt-main-logo-BLKWHT" asset catalog image resource.
    static let tetradaptMainLogoBLKWHT = DeveloperToolsSupport.ImageResource(name: "tetradapt-main-logo-BLKWHT", bundle: resourceBundle)

    /// The "tetradapt-main-logo-transparent" asset catalog image resource.
    static let tetradaptMainLogoTransparent = DeveloperToolsSupport.ImageResource(name: "tetradapt-main-logo-transparent", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "AVR_Red_Smarthome" asset catalog image.
    static var avrRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .avrRedSmarthome)
#else
        .init()
#endif
    }

    /// The "AVR_Smarthome" asset catalog image.
    static var avrSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .avrSmarthome)
#else
        .init()
#endif
    }

    /// The "Addmore_Red_Smarthome" asset catalog image.
    static var addmoreRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .addmoreRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Addmore_Smarthome" asset catalog image.
    static var addmoreSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .addmoreSmarthome)
#else
        .init()
#endif
    }

    /// The "Away_Black_Smarthome" asset catalog image.
    static var awayBlackSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .awayBlackSmarthome)
#else
        .init()
#endif
    }

    /// The "Away_Red_Smarthome" asset catalog image.
    static var awayRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .awayRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Away_Smarthome" asset catalog image.
    static var awaySmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .awaySmarthome)
#else
        .init()
#endif
    }

    /// The "Backyard_Red_Smarthome" asset catalog image.
    static var backyardRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .backyardRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Backyard_Smarthome" asset catalog image.
    static var backyardSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .backyardSmarthome)
#else
        .init()
#endif
    }

    /// The "Bedroom_Red_Smarthome" asset catalog image.
    static var bedroomRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bedroomRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Bedroom_Smarthome" asset catalog image.
    static var bedroomSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bedroomSmarthome)
#else
        .init()
#endif
    }

    /// The "Bedtime_Black_Smarthome" asset catalog image.
    static var bedtimeBlackSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bedtimeBlackSmarthome)
#else
        .init()
#endif
    }

    /// The "Bedtime_Red_Smarthome" asset catalog image.
    static var bedtimeRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bedtimeRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Bedtime_Smarthome" asset catalog image.
    static var bedtimeSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bedtimeSmarthome)
#else
        .init()
#endif
    }

    /// The "BlindsIcon_Smarthome" asset catalog image.
    static var blindsIconSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .blindsIconSmarthome)
#else
        .init()
#endif
    }

    /// The "Blinds_Red_Smarthome" asset catalog image.
    static var blindsRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .blindsRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Blinds_Smarthome" asset catalog image.
    static var blindsSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .blindsSmarthome)
#else
        .init()
#endif
    }

    /// The "ButtonBase_Smarthome" asset catalog image.
    static var buttonBaseSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .buttonBaseSmarthome)
#else
        .init()
#endif
    }

    /// The "Cameras_Red_Smarthome" asset catalog image.
    static var camerasRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .camerasRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Cameras_Smarthome" asset catalog image.
    static var camerasSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .camerasSmarthome)
#else
        .init()
#endif
    }

    /// The "CoffeeMaker_Red_Smarthome" asset catalog image.
    static var coffeeMakerRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .coffeeMakerRedSmarthome)
#else
        .init()
#endif
    }

    /// The "CoffeeMaker_Smarthome" asset catalog image.
    static var coffeeMakerSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .coffeeMakerSmarthome)
#else
        .init()
#endif
    }

    /// The "DeviceSelection_Base_Smarthome" asset catalog image.
    static var deviceSelectionBaseSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .deviceSelectionBaseSmarthome)
#else
        .init()
#endif
    }

    /// The "Dishwasher_Red_Smarthome" asset catalog image.
    static var dishwasherRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dishwasherRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Dishwasher_Smarthome" asset catalog image.
    static var dishwasherSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dishwasherSmarthome)
#else
        .init()
#endif
    }

    /// The "DownArrow_Smarthome" asset catalog image.
    static var downArrowSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .downArrowSmarthome)
#else
        .init()
#endif
    }

    /// The "DownMaxArrow_Smarthome" asset catalog image.
    static var downMaxArrowSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .downMaxArrowSmarthome)
#else
        .init()
#endif
    }

    /// The "DownMax_Smarthome" asset catalog image.
    static var downMaxSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .downMaxSmarthome)
#else
        .init()
#endif
    }

    /// The "Down_Smarthome" asset catalog image.
    static var downSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .downSmarthome)
#else
        .init()
#endif
    }

    /// The "Dryer_Red_Smarthome" asset catalog image.
    static var dryerRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dryerRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Dryer_Smarthome" asset catalog image.
    static var dryerSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dryerSmarthome)
#else
        .init()
#endif
    }

    /// The "Elevator_Red_Smarthome" asset catalog image.
    static var elevatorRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .elevatorRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Elevator_Smarthome" asset catalog image.
    static var elevatorSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .elevatorSmarthome)
#else
        .init()
#endif
    }

    /// The "Entrance_Red_Smarthome" asset catalog image.
    static var entranceRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .entranceRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Entrance_Smarthome" asset catalog image.
    static var entranceSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .entranceSmarthome)
#else
        .init()
#endif
    }

    /// The "Fridge_Red_Smarthome" asset catalog image.
    static var fridgeRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .fridgeRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Fridge_Smarthome" asset catalog image.
    static var fridgeSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .fridgeSmarthome)
#else
        .init()
#endif
    }

    /// The "Garage_Red_Smarthome" asset catalog image.
    static var garageRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .garageRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Garage_Smarthome" asset catalog image.
    static var garageSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .garageSmarthome)
#else
        .init()
#endif
    }

    /// The "Home_Red_Smarthome" asset catalog image.
    static var homeRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .homeRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Home_Smarthome" asset catalog image.
    static var homeSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .homeSmarthome)
#else
        .init()
#endif
    }

    /// The "Kitchen_Red_Smarthome" asset catalog image.
    static var kitchenRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .kitchenRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Kitchen_Smarthome" asset catalog image.
    static var kitchenSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .kitchenSmarthome)
#else
        .init()
#endif
    }

    /// The "Laundry_Red_Smarthome" asset catalog image.
    static var laundryRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .laundryRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Laundry_Smarthome" asset catalog image.
    static var laundrySmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .laundrySmarthome)
#else
        .init()
#endif
    }

    /// The "LightIcon_Smarthome" asset catalog image.
    static var lightIconSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .lightIconSmarthome)
#else
        .init()
#endif
    }

    /// The "Lights_Red_Smarthome" asset catalog image.
    static var lightsRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .lightsRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Lights_Smarthome" asset catalog image.
    static var lightsSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .lightsSmarthome)
#else
        .init()
#endif
    }

    /// The "LivingRm_Red_Smarthome" asset catalog image.
    static var livingRmRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .livingRmRedSmarthome)
#else
        .init()
#endif
    }

    /// The "LivingRm_Smarthome" asset catalog image.
    static var livingRmSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .livingRmSmarthome)
#else
        .init()
#endif
    }

    /// The "Lock_Red_Smarthome" asset catalog image.
    static var lockRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .lockRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Lock_Smarthome" asset catalog image.
    static var lockSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .lockSmarthome)
#else
        .init()
#endif
    }

    /// The "MasterBedrm_Red_Smarthome" asset catalog image.
    static var masterBedrmRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .masterBedrmRedSmarthome)
#else
        .init()
#endif
    }

    /// The "MasterBedrm_Smarthome" asset catalog image.
    static var masterBedrmSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .masterBedrmSmarthome)
#else
        .init()
#endif
    }

    /// The "Morning_Black_Smarthome" asset catalog image.
    static var morningBlackSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .morningBlackSmarthome)
#else
        .init()
#endif
    }

    /// The "Morning_Red_Smarthome" asset catalog image.
    static var morningRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .morningRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Morning_Smarthome" asset catalog image.
    static var morningSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .morningSmarthome)
#else
        .init()
#endif
    }

    /// The "Music_Red_Smarthome" asset catalog image.
    static var musicRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .musicRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Music_Smarthome" asset catalog image.
    static var musicSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .musicSmarthome)
#else
        .init()
#endif
    }

    /// The "Mute_Red_Smarthome" asset catalog image.
    static var muteRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .muteRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Mute_Smarthome" asset catalog image.
    static var muteSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .muteSmarthome)
#else
        .init()
#endif
    }

    /// The "Nursery_Red_Smarthome" asset catalog image.
    static var nurseryRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .nurseryRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Nursery_Smarthome" asset catalog image.
    static var nurserySmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .nurserySmarthome)
#else
        .init()
#endif
    }

    /// The "Outside_Red_Smarthome" asset catalog image.
    static var outsideRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .outsideRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Outside_Smarthome" asset catalog image.
    static var outsideSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .outsideSmarthome)
#else
        .init()
#endif
    }

    /// The "Oven_Red_Smarthome" asset catalog image.
    static var ovenRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ovenRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Oven_Smarthome" asset catalog image.
    static var ovenSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ovenSmarthome)
#else
        .init()
#endif
    }

    /// The "Playroom_Red_Smarthome" asset catalog image.
    static var playroomRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .playroomRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Playroom_Smarthome" asset catalog image.
    static var playroomSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .playroomSmarthome)
#else
        .init()
#endif
    }

    /// The "Power_Red_Smarthome" asset catalog image.
    static var powerRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .powerRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Power_Smarthome" asset catalog image.
    static var powerSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .powerSmarthome)
#else
        .init()
#endif
    }

    /// The "Reading_Black_Smarthome" asset catalog image.
    static var readingBlackSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .readingBlackSmarthome)
#else
        .init()
#endif
    }

    /// The "Reading_Red_Smarthome" asset catalog image.
    static var readingRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .readingRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Reading_Smarthome" asset catalog image.
    static var readingSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .readingSmarthome)
#else
        .init()
#endif
    }

    /// The "ScenesBackground_Smarthome" asset catalog image.
    static var scenesBackgroundSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .scenesBackgroundSmarthome)
#else
        .init()
#endif
    }

    /// The "SidebarIcon_Smarthome" asset catalog image.
    static var sidebarIconSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .sidebarIconSmarthome)
#else
        .init()
#endif
    }

    /// The "Sidebar_Base_Smarthome" asset catalog image.
    static var sidebarBaseSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .sidebarBaseSmarthome)
#else
        .init()
#endif
    }

    /// The "Smart HomeWHT" asset catalog image.
    static var smartHomeWHT: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .smartHomeWHT)
#else
        .init()
#endif
    }

    /// The "Soft_Red_Smarthome" asset catalog image.
    static var softRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .softRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Soft_Smarthome" asset catalog image.
    static var softSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .softSmarthome)
#else
        .init()
#endif
    }

    /// The "Stove_Red_Smarthome" asset catalog image.
    static var stoveRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .stoveRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Stove_Smarthome" asset catalog image.
    static var stoveSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .stoveSmarthome)
#else
        .init()
#endif
    }

    /// The "Streamer_Red_Smarthome" asset catalog image.
    static var streamerRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .streamerRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Streamer_Smarthome" asset catalog image.
    static var streamerSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .streamerSmarthome)
#else
        .init()
#endif
    }

    /// The "Support_Red_Smarthome" asset catalog image.
    static var supportRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .supportRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Support_Smarthome" asset catalog image.
    static var supportSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .supportSmarthome)
#else
        .init()
#endif
    }

    /// The "TVTime_Smarthome" asset catalog image.
    static var tvTimeSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tvTimeSmarthome)
#else
        .init()
#endif
    }

    /// The "TV_Black_Smarthome" asset catalog image.
    static var tvBlackSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tvBlackSmarthome)
#else
        .init()
#endif
    }

    /// The "TV_Red_Smarthome" asset catalog image.
    static var tvRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tvRedSmarthome)
#else
        .init()
#endif
    }

    /// The "TV_Smarthome" asset catalog image.
    static var tvSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tvSmarthome)
#else
        .init()
#endif
    }

    /// The "Temp_Red_Smarthome" asset catalog image.
    static var tempRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tempRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Temp__Smarthome" asset catalog image.
    static var tempSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tempSmarthome)
#else
        .init()
#endif
    }

    /// The "ToggleOn_Smarthome" asset catalog image.
    static var toggleOnSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .toggleOnSmarthome)
#else
        .init()
#endif
    }

    /// The "UpArrow_Smarthome" asset catalog image.
    static var upArrowSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .upArrowSmarthome)
#else
        .init()
#endif
    }

    /// The "UpMaxArrow_Smarthome" asset catalog image.
    static var upMaxArrowSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .upMaxArrowSmarthome)
#else
        .init()
#endif
    }

    /// The "UpMax_Smarthome" asset catalog image.
    static var upMaxSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .upMaxSmarthome)
#else
        .init()
#endif
    }

    /// The "Up_Smarthome" asset catalog image.
    static var upSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .upSmarthome)
#else
        .init()
#endif
    }

    /// The "Washer_Red_Smarthome" asset catalog image.
    static var washerRedSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .washerRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Washer_Smarthome" asset catalog image.
    static var washerSmarthome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .washerSmarthome)
#else
        .init()
#endif
    }

    /// The "tetradapt" asset catalog image.
    static var tetradapt: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tetradapt)
#else
        .init()
#endif
    }

    /// The "tetradapt-logo" asset catalog image.
    static var tetradaptLogo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tetradaptLogo)
#else
        .init()
#endif
    }

    /// The "tetradapt-main-logo-BLKWHT" asset catalog image.
    static var tetradaptMainLogoBLKWHT: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tetradaptMainLogoBLKWHT)
#else
        .init()
#endif
    }

    /// The "tetradapt-main-logo-transparent" asset catalog image.
    static var tetradaptMainLogoTransparent: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tetradaptMainLogoTransparent)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "AVR_Red_Smarthome" asset catalog image.
    static var avrRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .avrRedSmarthome)
#else
        .init()
#endif
    }

    /// The "AVR_Smarthome" asset catalog image.
    static var avrSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .avrSmarthome)
#else
        .init()
#endif
    }

    /// The "Addmore_Red_Smarthome" asset catalog image.
    static var addmoreRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .addmoreRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Addmore_Smarthome" asset catalog image.
    static var addmoreSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .addmoreSmarthome)
#else
        .init()
#endif
    }

    /// The "Away_Black_Smarthome" asset catalog image.
    static var awayBlackSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .awayBlackSmarthome)
#else
        .init()
#endif
    }

    /// The "Away_Red_Smarthome" asset catalog image.
    static var awayRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .awayRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Away_Smarthome" asset catalog image.
    static var awaySmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .awaySmarthome)
#else
        .init()
#endif
    }

    /// The "Backyard_Red_Smarthome" asset catalog image.
    static var backyardRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .backyardRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Backyard_Smarthome" asset catalog image.
    static var backyardSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .backyardSmarthome)
#else
        .init()
#endif
    }

    /// The "Bedroom_Red_Smarthome" asset catalog image.
    static var bedroomRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bedroomRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Bedroom_Smarthome" asset catalog image.
    static var bedroomSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bedroomSmarthome)
#else
        .init()
#endif
    }

    /// The "Bedtime_Black_Smarthome" asset catalog image.
    static var bedtimeBlackSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bedtimeBlackSmarthome)
#else
        .init()
#endif
    }

    /// The "Bedtime_Red_Smarthome" asset catalog image.
    static var bedtimeRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bedtimeRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Bedtime_Smarthome" asset catalog image.
    static var bedtimeSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bedtimeSmarthome)
#else
        .init()
#endif
    }

    /// The "BlindsIcon_Smarthome" asset catalog image.
    static var blindsIconSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .blindsIconSmarthome)
#else
        .init()
#endif
    }

    /// The "Blinds_Red_Smarthome" asset catalog image.
    static var blindsRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .blindsRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Blinds_Smarthome" asset catalog image.
    static var blindsSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .blindsSmarthome)
#else
        .init()
#endif
    }

    /// The "ButtonBase_Smarthome" asset catalog image.
    static var buttonBaseSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .buttonBaseSmarthome)
#else
        .init()
#endif
    }

    /// The "Cameras_Red_Smarthome" asset catalog image.
    static var camerasRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .camerasRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Cameras_Smarthome" asset catalog image.
    static var camerasSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .camerasSmarthome)
#else
        .init()
#endif
    }

    /// The "CoffeeMaker_Red_Smarthome" asset catalog image.
    static var coffeeMakerRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .coffeeMakerRedSmarthome)
#else
        .init()
#endif
    }

    /// The "CoffeeMaker_Smarthome" asset catalog image.
    static var coffeeMakerSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .coffeeMakerSmarthome)
#else
        .init()
#endif
    }

    /// The "DeviceSelection_Base_Smarthome" asset catalog image.
    static var deviceSelectionBaseSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .deviceSelectionBaseSmarthome)
#else
        .init()
#endif
    }

    /// The "Dishwasher_Red_Smarthome" asset catalog image.
    static var dishwasherRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dishwasherRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Dishwasher_Smarthome" asset catalog image.
    static var dishwasherSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dishwasherSmarthome)
#else
        .init()
#endif
    }

    /// The "DownArrow_Smarthome" asset catalog image.
    static var downArrowSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .downArrowSmarthome)
#else
        .init()
#endif
    }

    /// The "DownMaxArrow_Smarthome" asset catalog image.
    static var downMaxArrowSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .downMaxArrowSmarthome)
#else
        .init()
#endif
    }

    /// The "DownMax_Smarthome" asset catalog image.
    static var downMaxSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .downMaxSmarthome)
#else
        .init()
#endif
    }

    /// The "Down_Smarthome" asset catalog image.
    static var downSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .downSmarthome)
#else
        .init()
#endif
    }

    /// The "Dryer_Red_Smarthome" asset catalog image.
    static var dryerRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dryerRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Dryer_Smarthome" asset catalog image.
    static var dryerSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dryerSmarthome)
#else
        .init()
#endif
    }

    /// The "Elevator_Red_Smarthome" asset catalog image.
    static var elevatorRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .elevatorRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Elevator_Smarthome" asset catalog image.
    static var elevatorSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .elevatorSmarthome)
#else
        .init()
#endif
    }

    /// The "Entrance_Red_Smarthome" asset catalog image.
    static var entranceRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .entranceRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Entrance_Smarthome" asset catalog image.
    static var entranceSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .entranceSmarthome)
#else
        .init()
#endif
    }

    /// The "Fridge_Red_Smarthome" asset catalog image.
    static var fridgeRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .fridgeRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Fridge_Smarthome" asset catalog image.
    static var fridgeSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .fridgeSmarthome)
#else
        .init()
#endif
    }

    /// The "Garage_Red_Smarthome" asset catalog image.
    static var garageRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .garageRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Garage_Smarthome" asset catalog image.
    static var garageSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .garageSmarthome)
#else
        .init()
#endif
    }

    /// The "Home_Red_Smarthome" asset catalog image.
    static var homeRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .homeRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Home_Smarthome" asset catalog image.
    static var homeSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .homeSmarthome)
#else
        .init()
#endif
    }

    /// The "Kitchen_Red_Smarthome" asset catalog image.
    static var kitchenRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .kitchenRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Kitchen_Smarthome" asset catalog image.
    static var kitchenSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .kitchenSmarthome)
#else
        .init()
#endif
    }

    /// The "Laundry_Red_Smarthome" asset catalog image.
    static var laundryRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .laundryRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Laundry_Smarthome" asset catalog image.
    static var laundrySmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .laundrySmarthome)
#else
        .init()
#endif
    }

    /// The "LightIcon_Smarthome" asset catalog image.
    static var lightIconSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .lightIconSmarthome)
#else
        .init()
#endif
    }

    /// The "Lights_Red_Smarthome" asset catalog image.
    static var lightsRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .lightsRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Lights_Smarthome" asset catalog image.
    static var lightsSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .lightsSmarthome)
#else
        .init()
#endif
    }

    /// The "LivingRm_Red_Smarthome" asset catalog image.
    static var livingRmRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .livingRmRedSmarthome)
#else
        .init()
#endif
    }

    /// The "LivingRm_Smarthome" asset catalog image.
    static var livingRmSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .livingRmSmarthome)
#else
        .init()
#endif
    }

    /// The "Lock_Red_Smarthome" asset catalog image.
    static var lockRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .lockRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Lock_Smarthome" asset catalog image.
    static var lockSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .lockSmarthome)
#else
        .init()
#endif
    }

    /// The "MasterBedrm_Red_Smarthome" asset catalog image.
    static var masterBedrmRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .masterBedrmRedSmarthome)
#else
        .init()
#endif
    }

    /// The "MasterBedrm_Smarthome" asset catalog image.
    static var masterBedrmSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .masterBedrmSmarthome)
#else
        .init()
#endif
    }

    /// The "Morning_Black_Smarthome" asset catalog image.
    static var morningBlackSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .morningBlackSmarthome)
#else
        .init()
#endif
    }

    /// The "Morning_Red_Smarthome" asset catalog image.
    static var morningRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .morningRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Morning_Smarthome" asset catalog image.
    static var morningSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .morningSmarthome)
#else
        .init()
#endif
    }

    /// The "Music_Red_Smarthome" asset catalog image.
    static var musicRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .musicRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Music_Smarthome" asset catalog image.
    static var musicSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .musicSmarthome)
#else
        .init()
#endif
    }

    /// The "Mute_Red_Smarthome" asset catalog image.
    static var muteRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .muteRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Mute_Smarthome" asset catalog image.
    static var muteSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .muteSmarthome)
#else
        .init()
#endif
    }

    /// The "Nursery_Red_Smarthome" asset catalog image.
    static var nurseryRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .nurseryRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Nursery_Smarthome" asset catalog image.
    static var nurserySmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .nurserySmarthome)
#else
        .init()
#endif
    }

    /// The "Outside_Red_Smarthome" asset catalog image.
    static var outsideRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .outsideRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Outside_Smarthome" asset catalog image.
    static var outsideSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .outsideSmarthome)
#else
        .init()
#endif
    }

    /// The "Oven_Red_Smarthome" asset catalog image.
    static var ovenRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .ovenRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Oven_Smarthome" asset catalog image.
    static var ovenSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .ovenSmarthome)
#else
        .init()
#endif
    }

    /// The "Playroom_Red_Smarthome" asset catalog image.
    static var playroomRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .playroomRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Playroom_Smarthome" asset catalog image.
    static var playroomSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .playroomSmarthome)
#else
        .init()
#endif
    }

    /// The "Power_Red_Smarthome" asset catalog image.
    static var powerRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .powerRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Power_Smarthome" asset catalog image.
    static var powerSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .powerSmarthome)
#else
        .init()
#endif
    }

    /// The "Reading_Black_Smarthome" asset catalog image.
    static var readingBlackSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .readingBlackSmarthome)
#else
        .init()
#endif
    }

    /// The "Reading_Red_Smarthome" asset catalog image.
    static var readingRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .readingRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Reading_Smarthome" asset catalog image.
    static var readingSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .readingSmarthome)
#else
        .init()
#endif
    }

    /// The "ScenesBackground_Smarthome" asset catalog image.
    static var scenesBackgroundSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .scenesBackgroundSmarthome)
#else
        .init()
#endif
    }

    /// The "SidebarIcon_Smarthome" asset catalog image.
    static var sidebarIconSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .sidebarIconSmarthome)
#else
        .init()
#endif
    }

    /// The "Sidebar_Base_Smarthome" asset catalog image.
    static var sidebarBaseSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .sidebarBaseSmarthome)
#else
        .init()
#endif
    }

    /// The "Smart HomeWHT" asset catalog image.
    static var smartHomeWHT: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .smartHomeWHT)
#else
        .init()
#endif
    }

    /// The "Soft_Red_Smarthome" asset catalog image.
    static var softRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .softRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Soft_Smarthome" asset catalog image.
    static var softSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .softSmarthome)
#else
        .init()
#endif
    }

    /// The "Stove_Red_Smarthome" asset catalog image.
    static var stoveRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .stoveRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Stove_Smarthome" asset catalog image.
    static var stoveSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .stoveSmarthome)
#else
        .init()
#endif
    }

    /// The "Streamer_Red_Smarthome" asset catalog image.
    static var streamerRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .streamerRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Streamer_Smarthome" asset catalog image.
    static var streamerSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .streamerSmarthome)
#else
        .init()
#endif
    }

    /// The "Support_Red_Smarthome" asset catalog image.
    static var supportRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .supportRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Support_Smarthome" asset catalog image.
    static var supportSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .supportSmarthome)
#else
        .init()
#endif
    }

    /// The "TVTime_Smarthome" asset catalog image.
    static var tvTimeSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tvTimeSmarthome)
#else
        .init()
#endif
    }

    /// The "TV_Black_Smarthome" asset catalog image.
    static var tvBlackSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tvBlackSmarthome)
#else
        .init()
#endif
    }

    /// The "TV_Red_Smarthome" asset catalog image.
    static var tvRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tvRedSmarthome)
#else
        .init()
#endif
    }

    /// The "TV_Smarthome" asset catalog image.
    static var tvSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tvSmarthome)
#else
        .init()
#endif
    }

    /// The "Temp_Red_Smarthome" asset catalog image.
    static var tempRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tempRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Temp__Smarthome" asset catalog image.
    static var tempSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tempSmarthome)
#else
        .init()
#endif
    }

    /// The "ToggleOn_Smarthome" asset catalog image.
    static var toggleOnSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .toggleOnSmarthome)
#else
        .init()
#endif
    }

    /// The "UpArrow_Smarthome" asset catalog image.
    static var upArrowSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .upArrowSmarthome)
#else
        .init()
#endif
    }

    /// The "UpMaxArrow_Smarthome" asset catalog image.
    static var upMaxArrowSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .upMaxArrowSmarthome)
#else
        .init()
#endif
    }

    /// The "UpMax_Smarthome" asset catalog image.
    static var upMaxSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .upMaxSmarthome)
#else
        .init()
#endif
    }

    /// The "Up_Smarthome" asset catalog image.
    static var upSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .upSmarthome)
#else
        .init()
#endif
    }

    /// The "Washer_Red_Smarthome" asset catalog image.
    static var washerRedSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .washerRedSmarthome)
#else
        .init()
#endif
    }

    /// The "Washer_Smarthome" asset catalog image.
    static var washerSmarthome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .washerSmarthome)
#else
        .init()
#endif
    }

    /// The "tetradapt" asset catalog image.
    static var tetradapt: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tetradapt)
#else
        .init()
#endif
    }

    /// The "tetradapt-logo" asset catalog image.
    static var tetradaptLogo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tetradaptLogo)
#else
        .init()
#endif
    }

    /// The "tetradapt-main-logo-BLKWHT" asset catalog image.
    static var tetradaptMainLogoBLKWHT: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tetradaptMainLogoBLKWHT)
#else
        .init()
#endif
    }

    /// The "tetradapt-main-logo-transparent" asset catalog image.
    static var tetradaptMainLogoTransparent: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tetradaptMainLogoTransparent)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif


// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "MailPacket",
    platforms: [
        .macOS(.v10_13), .iOS(.v11)
    ],
    products: [
        .library( name: "MailPacket", targets: ["MailPacket"] ),
    ],
    dependencies: [
        .package(url: "https://github.com/KittyMac/Flynn.git", from: "0.4.0"),
        .package(url: "https://github.com/KittyMac/Hitch.git", from: "0.4.0"),
        .package(url: "https://github.com/KittyMac/Studding.git", from: "0.0.1"),
        .package(url: "https://github.com/KittyMac/Spanker.git", from: "0.2.0"),
        .package(url: "https://github.com/KittyMac/Sextant.git", from: "0.4.0"),
    ],
    targets: [
        .target(
            name: "MailPacket",
            dependencies: [
                "Flynn",
                "Hitch",
                "Spanker",
                "Studding",
                "Sextant",
                "libetpan"
			],
            plugins: [
                .plugin(name: "FlynnPlugin", package: "Flynn")
            ]
        ),
        .target(
            name: "libetpan",
            dependencies: [ ],
            cxxSettings: [
                .headerSearchPath("./**"),
                .define("HAVE_CFNETWORK"),
                .define("HAVE_CONFIG_H"),
                .define("LIBETPAN_IOS_DISABLE_SSL"),
            ]
        ),
        .testTarget(
            name: "MailPacketTests",
            dependencies: [
                "Flynn",
                "MailPacket",
                "Studding",
                "Spanker"
            ]
        )
    ],
    cLanguageStandard: .c99
    
    // -DHAVE_CFNETWORK=1 -DHAVE_CONFIG_H=1 -DLIBETPAN_IOS_DISABLE_SSL=1
    //.define("HAVE_CFNETWORK", .when(platforms: [.iOS])),
    //.define("HAVE_CONFIG_H"),
    /*
    linkerSettings: [
        .linkedLibrary("z"),
        .linkedLibrary("tesseract", .when(platforms: [.linux])),
        .linkedLibrary("leptonica", .when(platforms: [.linux]))
    ]*/

)

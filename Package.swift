// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "MailPacket",
    platforms: [
        .macOS(.v10_13), .iOS(.v11)
    ],
    products: [
        .library( name: "MailPacket", targets: ["MailPacket"] ),
        .library( name: "libetpan", type: .dynamic, targets: ["libetpan"]),
    ],
    dependencies: [
        .package(url: "https://github.com/KittyMac/Flynn.git", from: "0.4.0"),
        .package(url: "https://github.com/KittyMac/Hitch.git", from: "0.4.121"),
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
                .headerSearchPath("./"),
                .headerSearchPath("./cJSON/"),
                .headerSearchPath("./main/"),
                .headerSearchPath("./libetpan/"),
                .headerSearchPath("./libetpan/libetpan/"),
                .headerSearchPath("./driver/interface/"),
                .headerSearchPath("./driver/tools/"),
                .headerSearchPath("./data-types/"),
                .define("HAVE_CONFIG_H"),
                .define("HAVE_CFNETWORK", .when(platforms: [.iOS, .macOS])),
                .define("LIBETPAN_IOS_DISABLE_SSL", .when(platforms: [.iOS, .macOS])),
            ],
            linkerSettings: [
                .linkedLibrary("z", .when(platforms: [.linux, .android])),
                .linkedLibrary("ssl", .when(platforms: [.linux, .android])),
                .linkedLibrary("crypto", .when(platforms: [.linux, .android])),
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
    ]
)

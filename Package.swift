// swift-tools-version: 5.6

import PackageDescription

var dynamicLibs: [Product] = []

#if os(Linux)
dynamicLibs = [
    .library( name: "libetpan", type: .dynamic, targets: ["libetpan"])
]
#endif

var libetpanTargets: [Target] = []
var libetpanDependency: [Target.Dependency] = []

#if !os(Windows)
libetpanTargets = [
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
            .define("USE_SASL=1", .when(platforms: [.linux, .macOS]))
        ],
        linkerSettings: [
            .linkedLibrary("sasl2", .when(platforms: [.linux, .macOS])),
            .linkedLibrary("z", .when(platforms: [.linux, .android])),
            .linkedLibrary("ssl", .when(platforms: [.linux, .android])),
            .linkedLibrary("crypto", .when(platforms: [.linux, .android])),
        ]
    )
]
libetpanDependency = [
    "libetpan"
]
#endif

let package = Package(
    name: "MailPacket",
    products: dynamicLibs + [
        .library( name: "MailPacket", targets: ["MailPacket"] )
    ],
    dependencies: [
        .package(url: "https://github.com/KittyMac/Flynn.git", from: "0.4.0"),
        .package(url: "https://github.com/KittyMac/Hitch.git", from: "0.4.121"),
        .package(url: "https://github.com/KittyMac/Studding.git", from: "0.0.1"),
        .package(url: "https://github.com/KittyMac/Spanker.git", from: "0.2.0"),
        .package(url: "https://github.com/KittyMac/Sextant.git", from: "0.4.0"),
        .package(url: "https://github.com/KittyMac/Picaroon.git", from: "0.4.0"),
    ],
    targets: libetpanTargets + [
        .target(
            name: "MailPacket",
            dependencies: libetpanDependency + [
                "Flynn",
                "Hitch",
                "Spanker",
                "Studding",
                "Sextant",
                "Picaroon"
			],
            plugins: [
                .plugin(name: "FlynnPlugin", package: "Flynn")
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

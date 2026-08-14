import ProjectDescription

let appGroup = "group.dev.ryo.pixelterrarium"

let sharedSettings: Settings = .settings(
    base: [
        "SWIFT_VERSION": "6.0",
        "SWIFT_STRICT_CONCURRENCY": "complete",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    ],
    configurations: [
        .debug(name: "Debug"),
        .release(name: "Release"),
    ]
)

let project = Project(
    name: "PixelTerrarium",
    organizationName: "Ryo",
    settings: sharedSettings,
    targets: [
        .target(
            name: "TerrariumCore",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.ryo.pixelterrarium.core",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["Core/Sources/**"],
            settings: sharedSettings
        ),
        .target(
            name: "PixelTerrariumWidget",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "dev.ryo.pixelterrarium.widget",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Pixel Terrarium",
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.widgetkit-extension",
                ],
            ]),
            sources: ["Widget/Sources/**"],
            resources: ["Widget/Resources/**"],
            entitlements: "Widget/Entitlements.plist",
            dependencies: [.target(name: "TerrariumCore")],
            settings: sharedSettings
        ),
        .target(
            name: "PixelTerrariumApp",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ryo.pixelterrarium",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Pixel Terrarium",
                "UILaunchScreen": [:],
                "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
                "CFBundleURLTypes": [[
                    "CFBundleURLName": "dev.ryo.pixelterrarium",
                    "CFBundleURLSchemes": ["pixelterrarium"],
                ]],
            ]),
            sources: ["App/Sources/**"],
            resources: ["App/Resources/**"],
            entitlements: "App/Entitlements.plist",
            dependencies: [
                .target(name: "TerrariumCore"),
                .target(name: "PixelTerrariumWidget"),
            ],
            settings: sharedSettings
        ),
        .target(
            name: "TerrariumCoreTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ryo.pixelterrarium.coretests",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["Core/Tests/**"],
            dependencies: [.target(name: "TerrariumCore")],
            settings: sharedSettings
        ),
        .target(
            name: "PixelTerrariumUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "dev.ryo.pixelterrarium.uitests",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["UITests/**"],
            dependencies: [.target(name: "PixelTerrariumApp")],
            settings: sharedSettings
        ),
    ],
    schemes: [
        .scheme(
            name: "PixelTerrarium",
            shared: true,
            buildAction: .buildAction(targets: [
                "PixelTerrariumApp",
                "PixelTerrariumWidget",
                "TerrariumCore",
            ]),
            testAction: .targets(
                ["TerrariumCoreTests", "PixelTerrariumUITests"],
                configuration: "Debug"
            ),
            runAction: .runAction(configuration: "Debug", executable: "PixelTerrariumApp"),
            archiveAction: .archiveAction(configuration: "Release")
        ),
    ]
)

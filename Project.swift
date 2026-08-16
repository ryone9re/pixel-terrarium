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
    name: "Terrarit",
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
            name: "TerraritWidget",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "dev.ryo.pixelterrarium.widget",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Terrarit",
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
            name: "TerraritApp",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ryo.pixelterrarium",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Terrarit",
                "UILaunchScreen": [:],
                "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
                "CFBundleURLTypes": [[
                    "CFBundleURLName": "dev.ryo.pixelterrarium",
                    "CFBundleURLSchemes": ["terrarit", "pixelterrarium"],
                ]],
            ]),
            sources: ["App/Sources/**"],
            resources: ["App/Resources/**"],
            entitlements: "App/Entitlements.plist",
            dependencies: [
                .target(name: "TerrariumCore"),
                .target(name: "TerraritWidget"),
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
            name: "TerraritUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "dev.ryo.pixelterrarium.uitests",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["UITests/**"],
            dependencies: [.target(name: "TerraritApp")],
            settings: sharedSettings
        ),
    ],
    schemes: [
        .scheme(
            name: "Terrarit",
            shared: true,
            buildAction: .buildAction(targets: [
                "TerraritApp",
                "TerraritWidget",
                "TerrariumCore",
            ]),
            testAction: .targets(
                ["TerrariumCoreTests", "TerraritUITests"],
                configuration: "Debug"
            ),
            runAction: .runAction(configuration: "Debug", executable: "TerraritApp"),
            archiveAction: .archiveAction(configuration: "Release")
        ),
    ]
)

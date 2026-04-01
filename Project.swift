import ProjectDescription

// MARK: - Version Configuration

let marketingVersion = "1.2.9"
let developmentTeam = "2SB5Z68H26"

// MARK: - Shared Settings

let moduleVerifierSettings: SettingsDictionary = [
    "ENABLE_MODULE_VERIFIER": true,
    "ENABLE_MODULE_VERIFIER_SUPPORTED_LANGUAGES": true
]

// MARK: - Signing

func signingConfigurations(bundleId: String, extraDebugDevSettings: SettingsDictionary = [:]) -> [Configuration] {
    [
        .debug(
            name: "Debug",
            settings: [
                "CODE_SIGN_STYLE": "Manual",
                "CODE_SIGN_IDENTITY": "Apple Development",
                "PROVISIONING_PROFILE_SPECIFIER": "match Development \(bundleId)"
            ]),
        .debug(
            name: "Debug-Dev",
            settings: extraDebugDevSettings.merging([
                "CODE_SIGN_STYLE": "Manual",
                "CODE_SIGN_IDENTITY": "Apple Development",
                "PROVISIONING_PROFILE_SPECIFIER": "match Development \(bundleId)"
            ]) { $1 }),
        .release(
            name: "Release",
            settings: [
                "CODE_SIGN_STYLE": "Manual",
                "CODE_SIGN_IDENTITY": "Apple Distribution",
                "PROVISIONING_PROFILE_SPECIFIER": "match AppStore \(bundleId)"
            ])
    ]
}

// MARK: - Project

let project = Project(
    name: "Lumo",
    settings: .settings(
        base: [
            // Asset Catalog - Swift symbol generation
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": true,

            // Security - script sandboxing (important for Xcode 15+)
            "ENABLE_USER_SCRIPT_SANDBOXING": true,

            // Module verification - validate clang modules
            "ENABLE_MODULE_VERIFIER": true,
            "ENABLE_MODULE_VERIFIER_SUPPORTED_LANGUAGES": true,

            // Localization - prefer string catalogs
            "LOCALIZATION_PREFERS_STRING_CATALOGS": true,
            "STRING_CATALOG_GENERATE_SYMBOLS": true,
            "SWIFT_EMIT_LOC_STRINGS": true,

            // Performance - Metal fast math optimization
            "MTL_FAST_MATH": true,

            // Warnings - Additional useful warnings
            "CLANG_WARN_DOCUMENTATION_COMMENTS": true,
            "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": true,
            "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE"
        ],
        configurations: [
            .debug(name: "Debug", xcconfig: "Xcconfigs/Debug.xcconfig"),
            .debug(name: "Debug-Dev", xcconfig: "Xcconfigs/Debug-Dev.xcconfig"),
            .release(name: "Release", xcconfig: "Xcconfigs/Release.xcconfig")
        ]
    ),
    targets: [
        .target(
            name: "LumoApp",
            destinations: .iOS,
            product: .app,
            bundleId: "me.proton.lumo",
            deploymentTargets: .iOS("17.6"),
            infoPlist: .file(path: "Modules/App/SupportingFiles/Info.plist"),
            sources: ["Modules/App/Sources/**"],
            resources: [
                "Modules/App/Resources/**",
                "Modules/App/Sources/JSBridge/*.js",
                "Modules/App/Sources/Helpers/LumoPlans.storekit",
                "Modules/App/Sources/Helpers/plans.json"
            ],
            entitlements: "Modules/App/SupportingFiles/lumo.entitlements",
            dependencies: [
                .external(name: "ProtonUIFoundations"),
                .external(name: "Lottie"),
                .target(name: "LumoWidgetExtension"),
                .target(name: "LumoComposer"),
                .target(name: "LumoCore"),
                .target(name: "LumoDesignSystem"),
                .target(name: "LumoUI")
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": .string(developmentTeam),
                    "MARKETING_VERSION": .string(marketingVersion),
                    "CURRENT_PROJECT_VERSION": "1",
                    "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.productivity"
                ],
                configurations: signingConfigurations(
                    bundleId: "me.proton.lumo",
                    extraDebugDevSettings: [
                        "INFOPLIST_FILE": "Modules/App/SupportingFiles/Info-Dev.plist"
                    ]
                )
            ),
            additionalFiles: [
                "Modules/App/SupportingFiles/Info.plist",
                "Modules/App/SupportingFiles/Info-Dev.plist",
                .glob(pattern: "Modules/App/Sources/JSBridge/*.js"),
                "Modules/App/Sources/Helpers/LumoPlans.storekit",
                "Modules/App/Sources/Helpers/plans.json"
            ]
        ),
        .target(
            name: "LumoWidgetExtension",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "me.proton.lumo.LumoWidgetExtension",
            deploymentTargets: .iOS("17.6"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "LumoWidgetExtension",
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
                ]
            ]),
            sources: ["Modules/WidgetExtension/Sources/**"],
            resources: [
                "Modules/WidgetExtension/Resources/**"
            ],
            dependencies: [
                .external(name: "Lottie"),
                .target(name: "LumoUI")
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": .string(developmentTeam),
                    "MARKETING_VERSION": .string(marketingVersion),
                    "CURRENT_PROJECT_VERSION": "1"
                ],
                configurations: signingConfigurations(bundleId: "me.proton.lumo.LumoWidgetExtension")
            )
        ),
        .target(
            name: "LumoComposer",
            destinations: .iOS,
            product: .framework,
            bundleId: "me.proton.lumo.LumoComposer",
            deploymentTargets: .iOS("17.6"),
            sources: ["Modules/LumoComposer/Sources/**"],
            resources: [
                "Modules/LumoComposer/Resources/**"
            ],
            dependencies: [
                .external(name: "ProtonUIFoundations"),
                .target(name: "LumoCore"),
                .target(name: "LumoDesignSystem"),
                .target(name: "LumoUI")
            ],
            settings: .settings(base: moduleVerifierSettings)
        ),
        .target(
            name: "LumoCore",
            destinations: .iOS,
            product: .framework,
            bundleId: "me.proton.lumo.LumoCore",
            deploymentTargets: .iOS("17.6"),
            sources: ["Modules/LumoCore/Sources/**"],
            settings: .settings(base: moduleVerifierSettings)
        ),
        .target(
            name: "LumoDesignSystem",
            destinations: .iOS,
            product: .framework,
            bundleId: "me.proton.lumo.LumoDesignSystem",
            deploymentTargets: .iOS("17.6"),
            sources: ["Modules/LumoDesignSystem/Sources/**"],
            resources: [
                "Modules/LumoDesignSystem/Resources/**"
            ],
            dependencies: [
                .external(name: "Lottie")
            ],
            settings: .settings(base: moduleVerifierSettings)
        ),
        .target(
            name: "LumoUI",
            destinations: .iOS,
            product: .framework,
            bundleId: "me.proton.lumo.LumoUI",
            deploymentTargets: .iOS("17.6"),
            sources: ["Modules/LumoUI/Sources/**"],
            settings: .settings(base: moduleVerifierSettings)
        ),
        .target(
            name: "LumoAppUnitTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "me.proton.lumo.LumoAppUnitTests",
            deploymentTargets: .iOS("17.6"),
            sources: ["Modules/App/Tests/**"],
            dependencies: [
                .target(name: "LumoApp")
            ]
        ),
        .target(
            name: "LumoComposerTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "me.proton.lumo.LumoComposerTests",
            deploymentTargets: .iOS("17.6"),
            sources: ["Modules/LumoComposer/Tests/**"],
            dependencies: [
                .external(name: "Difference"),
                .target(name: "LumoComposer"),
                .target(name: "LumoApp"),
                .external(name: "SnapshotTesting")
            ],
            settings: .settings(
                base: [
                    "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/LumoApp.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/LumoApp",
                    "BUNDLE_LOADER": "$(TEST_HOST)"
                ]
            )
        )
    ],
    schemes: [
        .scheme(
            name: "LumoApp",
            shared: true,
            buildAction: .buildAction(targets: [.target("LumoApp")]),
            testAction: .targets(
                [
                    .testableTarget(target: .target("LumoAppUnitTests")),
                    .testableTarget(target: .target("LumoComposerTests"))
                ],
                configuration: "Debug"
            ),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        ),
        .scheme(
            name: "LumoApp-Dev",
            shared: true,
            buildAction: .buildAction(targets: [.target("LumoApp")]),
            testAction: .targets(
                [
                    .testableTarget(target: .target("LumoAppUnitTests")),
                    .testableTarget(target: .target("LumoComposerTests"))
                ],
                configuration: "Debug-Dev"
            ),
            runAction: .runAction(configuration: "Debug-Dev"),
            archiveAction: .archiveAction(configuration: "Debug-Dev"),
            profileAction: .profileAction(configuration: "Debug-Dev"),
            analyzeAction: .analyzeAction(configuration: "Debug-Dev")
        ),
        .scheme(
            name: "LumoWidgetExtension",
            shared: true,
            buildAction: .buildAction(
                targets: [.target("LumoWidgetExtension")]
            ),
            runAction: .runAction(configuration: "Debug")
        )
    ]
)

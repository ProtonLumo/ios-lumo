import ProjectDescription

// MARK: - Version Configuration

let marketingVersion = "1.2.5"
let currentProjectVersion = "31"
let developmentTeam = "2SB5Z68H26"

// MARK: - Project

let project = Project(
    name: "Lumo",
    settings: .settings(
        base: [
            // Asset Catalog - Swift symbol generation
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": true,

            // Security - script sandboxing (important for Xcode 15+)
            "ENABLE_USER_SCRIPT_SANDBOXING": true,

            // Localization - prefer string catalogs
            "LOCALIZATION_PREFERS_STRING_CATALOGS": true,
            "STRING_CATALOG_GENERATE_SYMBOLS": true,

            // Performance - Metal fast math optimization
            "MTL_FAST_MATH": true,

            // Warnings - Additional useful warnings
            "CLANG_WARN_DOCUMENTATION_COMMENTS": true,
            "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": true,
            "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
        ],
        configurations: [
            .debug(name: "Debug", xcconfig: "Xcconfigs/Debug.xcconfig"),
            .debug(name: "Debug-Dev", xcconfig: "Xcconfigs/Debug-Dev.xcconfig"),
            .release(name: "Release", xcconfig: "Xcconfigs/Release.xcconfig"),
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
                "Modules/App/Sources/Helpers/plans.json",
            ],
            entitlements: "Modules/App/SupportingFiles/lumo.entitlements",
            dependencies: [
                .external(name: "ProtonUIFoundations"),
                .external(name: "Lottie"),
                .target(name: "LumoWidgetExtension"),
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": .string(developmentTeam),
                    "MARKETING_VERSION": .string(marketingVersion),
                    "CURRENT_PROJECT_VERSION": .string(currentProjectVersion),
                    "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.productivity",
                ],
                configurations: [
                    .debug(name: "Debug"),
                    .debug(
                        name: "Debug-Dev",
                        settings: [
                            "INFOPLIST_FILE": "Modules/App/SupportingFiles/Info-Dev.plist"
                        ]
                    ),
                    .release(name: "Release"),
                ]
            ),
            additionalFiles: [
                "Modules/App/SupportingFiles/Info.plist",
                "Modules/App/SupportingFiles/Info-Dev.plist",
                .glob(pattern: "Modules/App/Sources/JSBridge/*.js"),
                "Modules/App/Sources/Helpers/LumoPlans.storekit",
                "Modules/App/Sources/Helpers/plans.json",
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
                ],
            ]),
            sources: ["Modules/WidgetExtension/Sources/**"],
            resources: [
                "Modules/WidgetExtension/Resources/**"
            ],
            dependencies: [
                .external(name: "Lottie")
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": .string(developmentTeam),
                    "MARKETING_VERSION": .string(marketingVersion),
                    "CURRENT_PROJECT_VERSION": .string(currentProjectVersion),
                ]
            )
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
    ],
    schemes: [
        .scheme(
            name: "LumoApp",
            shared: true,
            buildAction: swiftFormatBuildAction,
            testAction: .targets(
                [.testableTarget(target: .target("LumoAppUnitTests"))],
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
            buildAction: swiftFormatBuildAction,
            testAction: .targets(
                [.testableTarget(target: .target("LumoAppUnitTests"))],
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
        ),
    ]
)

var swiftFormatBuildAction: BuildAction {
    .buildAction(
        targets: [.target("LumoApp")],
        preActions: [
            .executionAction(
                scriptText: """
                    if [ $ACTION == "build" ]; then
                      cd "$SRCROOT"
                      xcrun swift-format format -r Modules -i
                    fi
                    """,
                target: .target("LumoApp")
            )
        ]
    )
}

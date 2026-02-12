import ProjectDescription

extension BuildAction {
    public static func swiftFormat(target: TargetReference) -> BuildAction {
        .buildAction(
            targets: [target],
            preActions: [
                .executionAction(
                    scriptText: """
                        if [ $ACTION == "build" ]; then
                          cd "$SRCROOT"
                          xcrun swift-format format -r Modules -i
                        fi
                        """,
                    target: target
                )
            ]
        )
    }
}

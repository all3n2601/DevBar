# Contributing

Use macOS 14+ with Xcode and Swift 5.9+. Run `swift test` and `python3 scripts/smoke-test.py "$(swift build --show-bin-path)/DevBar"` before opening a pull request.

Keep device operations in `DevBarCore` and reuse them across the GUI, CLI, and MCP. Avoid fixed-delay synchronization, shell interpolation, and success messages before the command completes. UI state changes belong on the main thread. MCP stdout must contain JSON-RPC messages only.

Add regression tests for changes to command construction, parsing, validation, process termination, and protocol behavior. Use fixtures or the injectable command runner rather than assuming a particular simulator is installed. Document platform-specific limitations honestly.

For bug reports, include setup versions, diagnostic output, and reproducible steps. Keep changes focused and explain the resulting behavior and verification in your pull request.

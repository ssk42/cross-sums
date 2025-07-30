# WORKSPACE

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Apple support repository (required for toolchains)
http_archive(
    name = "build_bazel_apple_support",
    sha256 = "cf4d63f39c7ba9059f70e995bf5fe1019267d3f77379c2028561a5d7645ef67c",
    urls = ["https://github.com/bazelbuild/apple_support/releases/download/1.11.1/apple_support.1.11.1.tar.gz"],
)

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()

# Apple's build rules for Bazel. This is the core dependency needed to build
# any Apple-platform application (iOS, macOS, etc.).
http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "841b8d1bd270ee19c75c5e953be1b58ace0ecb35ed97c56f53c28392ef86e0d7",
    urls = ["https://github.com/bazelbuild/rules_apple/releases/download/3.2.0/rules_apple.3.2.0.tar.gz"],
)

# Load the dependencies required by rules_apple.
load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

# Swift's build rules for Bazel. Required for compiling Swift code.
http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "28a66ff5d97500f0304f4e8945d936fe0584e0d5b7a6f83258298007a93190ba",
    urls = ["https://github.com/bazelbuild/rules_swift/releases/download/1.13.0/rules_swift.1.13.0.tar.gz"],
)

# Load the dependencies required by rules_swift.
load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

# Register necessary toolchains for Apple platforms
register_toolchains(
    "@build_bazel_rules_apple//toolchains:all",
)
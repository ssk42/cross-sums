# WORKSPACE

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Apple support - required for iOS builds
http_archive(
    name = "build_bazel_apple_support",
    sha256 = "100d12617a84ebc7ee7a10ecf3b3e2fdadaebc167ad93a21f820a6cb60158ead",
    urls = ["https://github.com/bazelbuild/apple_support/releases/download/1.12.0/apple_support.1.12.0.tar.gz"],
)

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()

# Apple's build rules for Bazel
http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "b4df908ec14868369021182ab191dbd1f40830c9b300650d5dc389e0b9266c8d",
    urls = ["https://github.com/bazelbuild/rules_apple/releases/download/3.5.1/rules_apple.3.5.1.tar.gz"],
)

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

# Swift's build rules for Bazel - using a different version
http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "28a66ff5d97500f0304f4e8945d936fe0584e0d5b7a6f83258298007a93190ba",
    urls = ["https://github.com/bazelbuild/rules_swift/releases/download/1.13.0/rules_swift.1.13.0.tar.gz"],
)

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()
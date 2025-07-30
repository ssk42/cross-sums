# WORKSPACE

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Apple's build rules for Bazel. This is the core dependency needed to build
# any Apple-platform application (iOS, macOS, etc.).
http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "516994a3654949575908535c8084a861a5259972b26c03472393322a55799703",
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
    sha256 = "b6172d03998a67545695817c185124118b6e3f43dd60a0389a41639c4c153702",
    urls = ["https://github.com/bazelbuild/rules_swift/releases/download/1.13.0/rules_swift.1.13.0.tar.gz"],
)

# Load the dependencies required by rules_swift.
load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

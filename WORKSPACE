# WORKSPACE

# This file defines the external dependencies for the Bazel build.
# It should be located in the root directory of your repository.

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# -----------------------------------------------------------------------------
# Apple Build Rules
# This dependency provides the rules for building applications for Apple platforms
# (iOS, macOS, etc.), such as ios_application and ios_application_ipa.
# -----------------------------------------------------------------------------
http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "1d9916358535d499ed93951336423233e164f20817479a653a1a6b8259e8e579",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/3.2.0/rules_apple.3.2.0.tar.gz",
)

# Load the dependencies that rules_apple itself needs.
load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)
apple_rules_dependencies()

# -----------------------------------------------------------------------------
# Swift Build Rules
# This dependency provides the rules for compiling Swift code (swift_library).
# -----------------------------------------------------------------------------
http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "b613617c44a37b0423e435941b2e65c8a50613a238e1258da18a815a519888a7",
    url = "https://github.com/bazelbuild/rules_swift/releases/download/2.1.0/rules_swift.2.1.0.tar.gz",
)

# Load the dependencies that rules_swift itself needs.
load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)
swift_rules_dependencies()

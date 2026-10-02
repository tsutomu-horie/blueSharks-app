# Build the JDK17 base first; see README.md for the complete preparation order.
# docker build -f tools/autodev/docker/Dockerfile.base -t bluesharks-autodev-flutter:3.27.4-jdk17-base tools/autodev/docker
# docker build --pull=false -t bluesharks-autodev-flutter:3.27.4 tools/autodev/docker
ARG BASE_IMAGE=bluesharks-autodev-flutter:3.27.4-jdk17-base
FROM ${BASE_IMAGE}

ENV ANDROID_PLATFORM_VERSION=35 \
    ANDROID_BUILD_TOOLS_VERSION=35.0.0

# Flutter 3.27.4 selects compileSdk 35 and NDK 26.1.10909125.
# The project's Android Gradle plugin also requires Build Tools 33.0.1.
# Downloads occur only while preparing the image; checks use --network=none.
RUN yes | sdkmanager --sdk_root="$ANDROID_SDK_ROOT" \
        "platforms;android-35" \
        "build-tools;33.0.1" \
        "build-tools;35.0.0" \
        "ndk;26.1.10909125" \
    && test -f "$ANDROID_SDK_ROOT/platforms/android-35/android.jar" \
    && test -x "$ANDROID_SDK_ROOT/build-tools/33.0.1/aapt2" \
    && test -x "$ANDROID_SDK_ROOT/build-tools/35.0.0/aapt2" \
    && test -f "$ANDROID_SDK_ROOT/ndk/26.1.10909125/source.properties"

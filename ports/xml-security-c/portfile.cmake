include(vcpkg_common_functions)

set(VERSION 2.0.2)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO apache/santuario-cpp
    REF c0e83733941cfa7dc1df0983a001a150e9fbe70a
    SHA512 8c675a0a48b08a4faf2645fe36945fbb97087846e5212e0a0a149fca0d5e3450300f77a6c2911dd445c4bedb4417a11f059951063f787ce393219cf530becd82
    PATCHES
        001_remove-xalan-macros.patch
        002_ignore-libtool-dllexport.patch
)

vcpkg_check_features(
    OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        openssl	WITH_OPENSSL
        xalan	WITH_XALAN
)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt DESTINATION ${SOURCE_PATH})
vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS ${FEATURE_OPTIONS}
)
vcpkg_install_cmake()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
vcpkg_fixup_cmake_targets(CONFIG_PATH lib/cmake/XmlSecurityC)
vcpkg_copy_pdbs()

file(INSTALL ${SOURCE_PATH}/LICENSE.txt
    DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT}
    RENAME copyright
)

vcpkg_test_cmake(PACKAGE_NAME XmlSecurityC)

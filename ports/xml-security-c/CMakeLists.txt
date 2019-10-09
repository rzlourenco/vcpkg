cmake_minimum_required(VERSION 3.12)
project(xml-security-c VERSION 2.0.2 LANGUAGES C CXX)

include(CheckCSourceCompiles)
include(CheckCSourceRuns)
include(CheckIncludeFile)
include(CheckSymbolExists)
include(CMakePackageConfigHelpers)

find_package(XercesC CONFIG REQUIRED)

option(WITH_OPENSSL "Use OpenSSL" OFF)
option(WITH_XALAN "Use Xalan" OFF)


if(WITH_OPENSSL)
    find_package(OpenSSL REQUIRED)
endif()
if(WITH_XALAN)
    find_package(ICU REQUIRED COMPONENTS i18n uc)
    find_package(XalanC CONFIG REQUIRED)
endif()

check_c_source_runs("\
#include <stdlib.h>\n\
#include <unistd.h>\n\
int main() {\
    char *cwd = getcwd(NULL, 0);\
    return (cwd != NULL) ? EXIT_SUCCESS : EXIT_FAILURE;\
}" XSEC_HAVE_GETCWD_DYN)
check_include_file("direct.h" HAVE_DIRECT_H)

if(OpenSSL_FOUND)
    set(old_CMAKE_REQUIRED_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES})
    set(CMAKE_REQUIRED_LIBRARIES "ssl;crypto")
    check_c_source_compiles("\
    #include <openssl/rsa.h>\n\
    int main() {\
        const unsigned char *buf;\
        unsigned char *outbuf;\
        RSA rsa;\
        RSA_private_decrypt(1, buf, outbuf, &rsa, RSA_PKCS1_PADDING);\
    }" XSEC_OPENSSL_CONST_BUFFERS)
    check_symbol_exists(EVP_PKEY_id "openssl/evp.h" XSEC_OPENSSL_HAVE_EVP_PKEY_ID)
    check_symbol_exists(EVP_aes_256_cbc "openssl/evp.h" XSEC_OPENSSL_HAVE_AES)
    check_symbol_exists(EVP_aes_256_gcm "openssl/evp.h" XSEC_OPENSSL_HAVE_GCM)
    check_symbol_exists(PKCS1_MGF1 "openssl/rsa.h" XSEC_OPENSSL_HAVE_MGF1)
    check_symbol_exists(EVP_PKEY_set1_EC_KEY "openssl/evp.h" XSEC_OPENSSL_HAVE_EC)
    check_symbol_exists(EVP_sha512 "openssl/evp.h" XSEC_OPENSSL_HAVE_SHA2)
    check_symbol_exists(EVP_CIPHER_CTX_set_padding "openssl/evp.h" XSEC_OPENSSL_CANSET_PADDING)
    check_symbol_exists(CRYPTO_cleanup_all_ex_data "openssl/crypto.h" XSEC_OPENSSL_HAVE_CRYPTO_CLEANUP_ALL_EX_DATA)
    check_c_source_compiles("\
    #include <openssl/x509.h>\n\
    int main() {\
        const unsigned char *buf;\
        d2i_X509(NULL, &buf, 1);\
    }" XSEC_OPENSSL_D2IX509_CONST_BUFFER)

    set(CMAKE_REQUIRED_LIBRARIES ${old_CMAKE_REQUIRED_LIBRARIES})
endif()

file(GLOB canon_src CONFIGURE_DEPENDS xsec/canon/*.cpp)
file(GLOB dsig_src CONFIGURE_DEPENDS xsec/dsig/*.cpp)
file(GLOB enc_src CONFIGURE_DEPENDS xsec/enc/*.cpp)
file(GLOB framework_src CONFIGURE_DEPENDS xsec/framework/*.cpp)
file(GLOB transformers_src CONFIGURE_DEPENDS xsec/transformers/*.cpp)
file(GLOB utils_src CONFIGURE_DEPENDS xsec/utils/*.cpp)
file(GLOB xenc_src CONFIGURE_DEPENDS xsec/xenc/impl/*.cpp)
file(GLOB xkms_src CONFIGURE_DEPENDS xsec/xkms/*.cpp xsec/xkms/impl/*.cpp)
file(GLOB xscrypt_src CONFIGURE_DEPENDS xsec/enc/XSCrypt/*.cpp)

if(WIN32)
    list(APPEND utils_src xsec/utils/winutils/XSECSOAPRequestorSimpleWin32.cpp)
else()
    list(APPEND utils_src xsec/utils/unixutils/XSECSOAPRequestorSimpleUnix.cpp)
endif()

file(GLOB canon_inc CONFIGURE_DEPENDS xsec/canon/*.hpp)
file(GLOB dsig_inc CONFIGURE_DEPENDS xsec/dsig/*.hpp)
file(GLOB enc_inc CONFIGURE_DEPENDS xsec/enc/*.hpp)
file(GLOB framework_inc CONFIGURE_DEPENDS xsec/framework/*.hpp)
file(GLOB transformers_inc CONFIGURE_DEPENDS xsec/transformers/*.hpp)
file(GLOB utils_inc CONFIGURE_DEPENDS xsec/utils/*.hpp)
file(GLOB xenc_inc CONFIGURE_DEPENDS xsec/xenc/*.hpp)
file(GLOB xkms_inc CONFIGURE_DEPENDS xsec/xkms/*.hpp)
file(GLOB xscrypt_inc CONFIGURE_DEPENDS xsec/enc/XSCrypt/*.hpp)

list(REMOVE_ITEM transformers_inc xsec/framework/XSECConfig.hpp)

set(openssl_src )
set(openssl_inc )
if(OpenSSL_FOUND)
    file(GLOB openssl_src CONFIGURE_DEPENDS xsec/enc/OpenSSL/*.cpp)
    file(GLOB openssl_inc CONFIGURE_DEPENDS xsec/enc/OpenSSL/*.hpp)
endif()

# These are macro files but we define everything dia the preprocessor
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/config.h
    "#include <xsec/framework/XSECVersion.hpp>")
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/xsec/framework/XSECConfig.hpp
    "#include <xsec/framework/XSECVersion.hpp>")
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/xsec/framework/XSECW32Config.hpp
    "#include <xsec/framework/XSECVersion.hpp>")

add_library(xml-security-c
    ${canon_src}
    ${dsig_src}
    ${enc_src}
    ${dsig_src}
    ${framework_src}
    ${transformers_src}
    ${utils_src}
    ${xenc_src}
    ${xscrypt_src}
    ${xkms_src}
    ${openssl_src}
)
target_include_directories(xml-security-c
    PRIVATE
        ${CMAKE_CURRENT_BINARY_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}
)

target_compile_definitions(xml-security-c
    PRIVATE
        XSEC_XKMS_ENABLED=1
        XSEC_BUILDING_LIBRARY=1
        $<$<BOOL:XSEC_HAVE_GETCWD_DYN>:XSEC_HAVE_GETCWD_DYN=1>
        $<$<BOOL:Xalan_FOUND>:XSEC_HAVE_XALAN=1>
        $<$<BOOL:OpenSSL_FOUND>:XSEC_HAVE_OPENSSL=1>
        $<$<BOOL:XSEC_OPENSSL_CONST_BUFFERS>:XSEC_OPENSSL_CONST_BUFFERS=1>
        $<$<BOOL:XSEC_OPENSSL_HAVE_EVP_PKEY_ID>:XSEC_OPENSSL_HAVE_EVP_PKEY_ID=1>
        $<$<BOOL:XSEC_OPENSSL_HAVE_AES>:XSEC_OPENSSL_HAVE_AES=1>
        $<$<BOOL:XSEC_OPENSSL_HAVE_GCM>:XSEC_OPENSSL_HAVE_GCM=1>
        $<$<BOOL:XSEC_OPENSSL_HAVE_MGF1>:XSEC_OPENSSL_HAVE_MGF1=1>
        $<$<BOOL:XSEC_OPENSSL_HAVE_EC>:XSEC_OPENSSL_HAVE_EC=1>
        $<$<BOOL:XSEC_OPENSSL_HAVE_SHA2>:XSEC_OPENSSL_HAVE_SHA2=1>
        $<$<BOOL:XSEC_OPENSSL_CANSET_PADDING>:XSEC_OPENSSL_CANSET_PADDING=1>
        $<$<BOOL:XSEC_OPENSSL_HAVE_CRYPTO_CLEANUP_ALL_EX_DATA>:XSEC_OPENSSL_HAVE_CRYPTO_CLEANUP_ALL_EX_DATA=1>
        $<$<BOOL:XSEC_OPENSSL_D2IX509_CONST_BUFFER>:XSEC_OPENSSL_D2IX509_CONST_BUFFER=1>
        $<$<BOOL:HAVE_DIRECT_H>:HAVE_DIRECT_H=1>
)

target_link_libraries(xml-security-c PRIVATE XercesC::XercesC)
if(WITH_OPENSSL)
    target_link_libraries(xml-security-c PRIVATE OpenSSL::SSL OpenSSL::Crypto)
endif()
if(WITH_XALAN)
    target_link_libraries(xml-security-c PRIVATE XalanC::XalanC)
endif()
if(WIN32)
    target_link_libraries(xml-security-c PRIVATE ws2_32)
endif()
set_target_properties(xml-security-c PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
)

add_library(XmlSecurityC ALIAS xml-security-c)

install(TARGETS xml-security-c
    EXPORT XmlSecurityCTargets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    INCLUDES DESTINATION include
)
install(EXPORT XmlSecurityCTargets
    FILE XmlSecurityCTargets.cmake
    NAMESPACE XmlSecurityC::
    DESTINATION lib/cmake/XmlSecurityC
)

set(public_inc
    ${canon_inc}
    ${dsig_inc}
    ${enc_inc}
    ${framework_inc}
    ${transformers_inc}
    ${utils_inc}
    ${xenc_inc}
    ${xkms_inc}
    ${xscrypt_inc}
    ${openssl_inc}
)
foreach(header ${public_inc})
    file(RELATIVE_PATH prefix ${CMAKE_CURRENT_SOURCE_DIR} ${header})
    get_filename_component(prefix ${prefix} DIRECTORY)
    install(FILES ${header} DESTINATION include/${prefix})
endforeach()

write_basic_package_version_file(
    XmlSecurityCConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY AnyNewerVersion
)

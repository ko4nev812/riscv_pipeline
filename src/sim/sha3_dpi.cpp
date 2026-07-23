#include <cstdio>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <cstdlib>

#if defined(_WIN32)
#define DPI_EXPORT __declspec(dllexport)
#include <windows.h>
#else
#define DPI_EXPORT
#include <dlfcn.h>
#endif

namespace {

#if defined(_WIN32)
using LibraryHandle = HMODULE;

constexpr const char* kLibraryPathVariable = "PATH";

const char* const kLibcryptoCandidates[] = {
    "libcrypto-3-x64.dll",
    "libcrypto-3.dll",
    "libcrypto-1_1-x64.dll",
    "libeay32.dll",
};

LibraryHandle open_library(const char* name) {
    return LoadLibraryA(name);
}

void* get_symbol(LibraryHandle handle, const char* name) {
    return reinterpret_cast<void*>(GetProcAddress(handle, name));
}

void close_library(LibraryHandle handle) {
    if (handle != nullptr) {
        FreeLibrary(handle);
    }
}
#else
using LibraryHandle = void*;

#if defined(__APPLE__)
constexpr const char* kLibraryPathVariable = "DYLD_LIBRARY_PATH";

const char* const kLibcryptoCandidates[] = {
    "libcrypto.3.dylib",
    "libcrypto.1.1.dylib",
    "libcrypto.dylib",
};
#else
constexpr const char* kLibraryPathVariable = "LD_LIBRARY_PATH";

const char* const kLibcryptoCandidates[] = {
    "libcrypto.so.3",
    "libcrypto.so.1.1",
    "libcrypto.so",
};
#endif

LibraryHandle open_library(const char* name) {
    return dlopen(name, RTLD_NOW | RTLD_LOCAL);
}

void* get_symbol(LibraryHandle handle, const char* name) {
    return dlsym(handle, name);
}

void close_library(LibraryHandle handle) {
    if (handle != nullptr) {
        dlclose(handle);
    }
}
#endif

struct evp_md_ctx_st;
struct evp_md_st;

using EVP_MD_CTX = evp_md_ctx_st;
using EVP_MD = evp_md_st;

using EVP_MD_CTX_new_fn = EVP_MD_CTX* (*)();
using EVP_MD_CTX_free_fn = void (*)(EVP_MD_CTX*);
using EVP_sha3_256_fn = const EVP_MD* (*)();
using EVP_DigestInit_ex_fn = int (*)(EVP_MD_CTX*, const EVP_MD*, void*);
using EVP_DigestUpdate_fn = int (*)(EVP_MD_CTX*, const void*, std::size_t);
using EVP_DigestFinal_ex_fn = int (*)(EVP_MD_CTX*, unsigned char*, unsigned int*);


struct OpenSslApi {
    bool load_attempted = false;
    bool loaded = false;
    LibraryHandle handle = nullptr;
    char loaded_name[512] = {};
    char error[2048] = {};

    EVP_MD_CTX_new_fn EVP_MD_CTX_new = nullptr;
    EVP_MD_CTX_free_fn EVP_MD_CTX_free = nullptr;
    EVP_sha3_256_fn EVP_sha3_256 = nullptr;
    EVP_DigestInit_ex_fn EVP_DigestInit_ex = nullptr;
    EVP_DigestUpdate_fn EVP_DigestUpdate = nullptr;
    EVP_DigestFinal_ex_fn EVP_DigestFinal_ex = nullptr;
};

OpenSslApi& openssl() {
    static OpenSslApi api;
    return api;
}

struct Sha3State {
    EVP_MD_CTX* ctx = nullptr;
    bool initialized = false;
};

Sha3State& state() {
    static Sha3State s;
    return s;
}

void free_context() {
    Sha3State& s = state();
    OpenSslApi& api = openssl();

    if (s.ctx != nullptr && api.EVP_MD_CTX_free != nullptr) {
        api.EVP_MD_CTX_free(s.ctx);
    }

    s.ctx = nullptr;
    s.initialized = false;
}

void append_text(char* dst, std::size_t dst_size, const char* src) {
    const std::size_t used = std::strlen(dst);
    if (used >= dst_size - 1) {
        return;
    }

    std::strncat(dst, src, dst_size - used - 1);
}

void set_missing_library_error(OpenSslApi& api, const char* tried) {
    std::snprintf(api.error,
                  sizeof(api.error),
                  "OpenSSL libcrypto was not found. Tried: %s. "
                  "Set RV_NSU_LIBCRYPTO to the full libcrypto path or add "
                  "OpenSSL to %s.",
                  tried[0] == '\0' ? "(none)" : tried,
                  kLibraryPathVariable);
}

bool try_open(OpenSslApi& api, const char* name, char* tried, std::size_t tried_size) {
    if (name == nullptr || name[0] == '\0') {
        return false;
    }

    if (tried[0] != '\0') {
        append_text(tried, tried_size, "; ");
    }
    append_text(tried, tried_size, name);

    api.handle = open_library(name);
    if (api.handle != nullptr) {
        std::snprintf(api.loaded_name, sizeof(api.loaded_name), "%s", name);
        return true;
    }

    return false;
}

template <typename T>
bool resolve_symbol(OpenSslApi& api, T& slot, const char* name) {
    slot = reinterpret_cast<T>(get_symbol(api.handle, name));
    if (slot != nullptr) {
        return true;
    }

    std::snprintf(api.error,
                  sizeof(api.error),
                  "OpenSSL libcrypto is missing symbol %s.",
                  name);
    return false;
}

bool load_openssl() {
    OpenSslApi& api = openssl();
    if (api.load_attempted) {
        return api.loaded;
    }

    api.load_attempted = true;

    char tried[4096] = {};
    const char* explicit_path = std::getenv("RV_NSU_LIBCRYPTO");

    if (explicit_path != nullptr && explicit_path[0] != '\0') {
        try_open(api, explicit_path, tried, sizeof(tried));
    } else {
        for (const char* candidate : kLibcryptoCandidates) {
            if (try_open(api, candidate, tried, sizeof(tried))) {
                break;
            }
        }
    }

    if (api.handle == nullptr) {
        set_missing_library_error(api, tried);
        std::fprintf(stderr, "[E] SHA3 DPI: %s\n", api.error);
        return false;
    }

    const bool resolved =
        resolve_symbol(api, api.EVP_MD_CTX_new, "EVP_MD_CTX_new") &&
        resolve_symbol(api, api.EVP_MD_CTX_free, "EVP_MD_CTX_free") &&
        resolve_symbol(api, api.EVP_sha3_256, "EVP_sha3_256") &&
        resolve_symbol(api, api.EVP_DigestInit_ex, "EVP_DigestInit_ex") &&
        resolve_symbol(api, api.EVP_DigestUpdate, "EVP_DigestUpdate") &&
        resolve_symbol(api, api.EVP_DigestFinal_ex, "EVP_DigestFinal_ex");

    if (!resolved) {
        std::fprintf(stderr, "[E] SHA3 DPI: %s\n", api.error);
        close_library(api.handle);
        api.handle = nullptr;
        return false;
    }

    api.loaded = true;
    std::fprintf(stderr, "[I] SHA3 DPI: using OpenSSL libcrypto: %s\n",
                 api.loaded_name);
    return true;
}

std::uint32_t pack_be32(const unsigned char* data) {
    return (static_cast<std::uint32_t>(data[0]) << 24) |
           (static_cast<std::uint32_t>(data[1]) << 16) |
           (static_cast<std::uint32_t>(data[2]) << 8) |
           static_cast<std::uint32_t>(data[3]);
}

}  // namespace

extern "C" DPI_EXPORT int dpi_sha3_256_begin() {
    if (!load_openssl()) {
        return -1;
    }

    OpenSslApi& api = openssl();
    Sha3State& s = state();

    free_context();

    s.ctx = api.EVP_MD_CTX_new();
    if (s.ctx == nullptr) {
        std::fprintf(stderr, "[E] SHA3 DPI: EVP_MD_CTX_new failed.\n");
        return -2;
    }

    const EVP_MD* sha3_256 = api.EVP_sha3_256();
    if (sha3_256 == nullptr) {
        std::fprintf(stderr, "[E] SHA3 DPI: EVP_sha3_256 returned null.\n");
        free_context();
        return -3;
    }

    if (api.EVP_DigestInit_ex(s.ctx, sha3_256, nullptr) != 1) {
        std::fprintf(stderr, "[E] SHA3 DPI: EVP_DigestInit_ex failed.\n");
        free_context();
        return -4;
    }

    s.initialized = true;
    return 0;
}

extern "C" DPI_EXPORT int dpi_sha3_256_update_word(unsigned int word, int byte_count) {
    if (byte_count < 0 || byte_count > 4) {
        return -5;
    }

    OpenSslApi& api = openssl();
    if (!api.loaded) {
        return -6;
    }

    Sha3State& s = state();
    if (!s.initialized || s.ctx == nullptr) {
        return -7;
    }

    unsigned char bytes[4] = {};
    for (int i = 0; i < byte_count; ++i) {
        bytes[i] = static_cast<unsigned char>((word >> (8 * i)) & 0xffU);
    }

    if (api.EVP_DigestUpdate(s.ctx, bytes, static_cast<std::size_t>(byte_count)) != 1) {
        std::fprintf(stderr, "[E] SHA3 DPI: EVP_DigestUpdate failed.\n");
        return -8;
    }

    return 0;
}

extern "C" DPI_EXPORT int dpi_sha3_256_final(unsigned int* digest0,
                                             unsigned int* digest1,
                                             unsigned int* digest2,
                                             unsigned int* digest3,
                                             unsigned int* digest4,
                                             unsigned int* digest5,
                                             unsigned int* digest6,
                                             unsigned int* digest7) {
    if (digest0 == nullptr || digest1 == nullptr || digest2 == nullptr ||
        digest3 == nullptr || digest4 == nullptr || digest5 == nullptr ||
        digest6 == nullptr || digest7 == nullptr) {
        return -9;
    }

    OpenSslApi& api = openssl();
    if (!api.loaded) {
        return -10;
    }

    Sha3State& s = state();
    if (!s.initialized || s.ctx == nullptr) {
        return -11;
    }

    unsigned char digest[32] = {};
    unsigned int digest_len = 0;

    if (api.EVP_DigestFinal_ex(s.ctx, digest, &digest_len) != 1) {
        std::fprintf(stderr, "[E] SHA3 DPI: EVP_DigestFinal_ex failed.\n");
        free_context();
        return -12;
    }

    free_context();

    if (digest_len != 32) {
        std::fprintf(stderr,
                     "[E] SHA3 DPI: unexpected SHA3-256 digest length %u.\n",
                     digest_len);
        return -13;
    }

    *digest0 = pack_be32(digest + 0);
    *digest1 = pack_be32(digest + 4);
    *digest2 = pack_be32(digest + 8);
    *digest3 = pack_be32(digest + 12);
    *digest4 = pack_be32(digest + 16);
    *digest5 = pack_be32(digest + 20);
    *digest6 = pack_be32(digest + 24);
    *digest7 = pack_be32(digest + 28);

    return 0;
}

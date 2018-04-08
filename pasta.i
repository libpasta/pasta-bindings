%module(package="libpasta") pasta

%include "std_string.i"

#if defined(SWIGJAVA)
%include "enums.swg"
#endif

%ignore HashUpdate::HashUpdate;
%ignore PrimitiveWrapper::inner;

// 
%{
    namespace ffi {
        #include "pasta.h"
    }
    using namespace ffi;

    class HashUpdate {
        public:
            enum Tag {
              Updated,
              Ok,
              Failed,
            } tag;

            char *updated = NULL;

            HashUpdate(HashUpdateFfi *other) {
                switch(other->tag) {
                    case HashUpdateFfi::Tag::Updated:
                        tag = HashUpdate::Updated;
                        updated = other->updated._0; break;
                    case HashUpdateFfi::Tag::Ok: tag = HashUpdate::Ok; break;
                    case HashUpdateFfi::Tag::Failed: tag = HashUpdate::Failed; break;
                }
            }

            ~HashUpdate() {
                free_string(updated);
                updated = NULL;
            }
    };

    class PrimitiveWrapper {
        public:
            Primitive *self;
            virtual Primitive *inner() =0;
            virtual ~PrimitiveWrapper()=0;
    };

    PrimitiveWrapper::~PrimitiveWrapper() {}

    class Argon2i: public PrimitiveWrapper {
        public:
            Argon2i() {
                self = default_argon2i();
            };
            Argon2i(int passes, int lanes, int kib) {
              self = new_argon2i(passes, lanes, kib);
            };
            ~Argon2i() {
                free_Primitive(self);
                self = NULL;
            }
        protected:
            Primitive *inner() {
                return self;
            };
    };

    class Bcrypt: public PrimitiveWrapper {
        public:
            Bcrypt() {
                self = default_bcrypt();
            };
            Bcrypt(int cost) {
              self = new_bcrypt(cost);
            };
            ~Bcrypt() {
                free_Primitive(self);
                self = NULL;
            }
        protected:
            Primitive *inner() {
                return self;
            };
    };

    class Scrypt: public PrimitiveWrapper {
        public:
            Scrypt() {
                self = default_scrypt();
            };
            Scrypt(unsigned char log_n, unsigned int r, unsigned int p) {
              self = new_scrypt(log_n, r, p);
            };
            ~Scrypt() {
                free_Primitive(self);
                self = NULL;
            }
        protected:
            Primitive *inner() {
                return self;
            };
    };

    namespace libpasta {
        HashUpdate *migrate_hash(const char *hash) {
            return new HashUpdate(ffi::migrate_hash(hash));
        }

        HashUpdate *verify_password_update_hash(const char *hash, const char *password) {
            return new HashUpdate(ffi::verify_password_update_hash(hash, password));
        }

        class Config {
            ffi::Config *self;

            public:
                Config() {
                    self = config_new();
                };

                Config(PrimitiveWrapper *p) {
                    self = config_with_primitive(p->inner());
                };

                ~Config(){
                    config_free(self);
                    self = NULL;
                };

                static Config *with_primitive(PrimitiveWrapper *p) {
                    return new Config(p);
                };

                char *hash_password(const char *password) {
                    return config_hash_password(self, password);
                };

                HashUpdate *migrate_hash(const char *hash) {
                    return new HashUpdate(config_migrate_hash(self, hash));    
                };

                bool verify_password(const char *hash, const char *password) {
                    return config_verify_password(self, hash, password);
                };

                HashUpdate *verify_password_update_hash(const char *hash, const char *password) {
                    return new HashUpdate(config_verify_password_update_hash(self, hash, password));
                }
        };
    }
%}

// For functions returning `char *`, allocate a new String and immediately
// call `free_string` on the pointer to clean up from Rust.
%typemap(newfree) char * "free_string($1);";
%newobject hash_password;
%newobject read_password;


%pragma(java) jniclassimports=%{
import org.scijava.nativelib.*;
%}

%pragma(java) jniclasscode=%{
  static {
    try {
        NativeLoader.loadLibrary("pasta_jni");
    } catch (Exception e) {
      try {
        NativeLibraryUtil.loadNativeLibrary(pastaJNI.class, "pasta_jni");
      } catch (Exception e2) {
        System.err.println("Native code library failed to load. \n" + e);
        System.exit(1);
      }
    }
  }
%}



%nodefaultctor;
%nodefaultdtor;

class PrimitiveWrapper {
    public:
        virtual Primitive *inner() =0;
};

class Argon2i: public PrimitiveWrapper {
    public:
        Argon2i();
        Argon2i(int passes, int lanes, int kib);
        ~Argon2i();
    protected:
        Primitive *inner();
};

class Bcrypt: public PrimitiveWrapper {
    public:
        Bcrypt();
        Bcrypt(int cost);
        ~Bcrypt();
    protected:
        Primitive *inner();
};

class Scrypt: public PrimitiveWrapper {
    public:
        Scrypt();
        Scrypt(unsigned char log_n, unsigned int r, unsigned int p);
        ~Scrypt();
    protected:
        Primitive *inner();
};

class HashUpdate {
    public:
        enum Tag {
          Updated,
          Ok,
          Failed,
        } tag;

        char *updated = NULL;

        HashUpdate(HashUpdateFfi *other);
        ~HashUpdate();
};

// Password hashing primitives
//
// Each variant is backed up by different implementation.
// Internally, primitives can either be static values, for example,
// the `lazy_static` generated value `DEFAULT_PRIM`, or dynamically allocated
// variables, which are `Arc<Box<...>>`.
//
// Most operations are expected to be performed using the static functions,
// since most use the default algorithms. However, the flexibilty to support
// arbitrary parameter sets is essential.
struct Primitive;

namespace libpasta {
    %newobject migrate_hash;
    %newobject verify_password_update_hash;
    HashUpdate *migrate_hash(const char *hash);
    HashUpdate *verify_password_update_hash(const char *hash, const char *password);

    class Config {
        public:
            Config();
            Config(PrimitiveWrapper *p);
            ~Config();

            static Config *with_primitive(PrimitiveWrapper *p);
            char *hash_password(const char *password);
            HashUpdate *migrate_hash(const char *hash);
            bool verify_password(const char *hash, const char *password);
            HashUpdate *verify_password_update_hash(const char *hash, const char *password);
    };
}


extern "C" {
    char *hash_password(const char *password);
    char *read_password(const char *prompt);
    bool verify_password(const char *hash, const char *password);
}

%module(package="libpasta") pasta
%{
    #include "../libpasta/libpasta-capi/include/pasta.h"

    class PrimitiveWrapper {
        public:
            Primitive *self;
            virtual Primitive *inner() =0;
    };

    class Argon2i: public PrimitiveWrapper {
      public:
        Argon2i() {
            self = default_argon2i();
        };
        Argon2i(int passes, int lanes, int kib) {
          self = new_argon2i(passes, lanes, kib);
        };
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
        Primitive *inner() {
            return self;
        };
    };
%}

// For functions returning `char *`, allocate a new String and immediately
// call `free_string` on the pointer to clean up from Rust.
%typemap(newfree) char * "free_string($1);";

%include <typemaps.i>

// This input typemap declares that char** requires no input parameter.
// Instead, the address of a local char* is used to call the function.
%typemap(in,numinputs=0) char** (char* tmp) %{
    $1 = &tmp;
%}

// The malloc'ed pointer is no longer needed, so make sure it is freed.
%typemap(freearg) char** %{
    free(*$1);
%}

#if defined(SWIGRUBY) || defined(SWIGPYTHON)
  // This input typemap declares that char** requires no input parameter.
  // Instead, the address of a local char* is used to call the function.
  %typemap(in,numinputs=0) char** (char* tmp) %{
      $1 = &tmp;
  %}
#endif

#if defined(SWIGPYTHON)
  // After the function is called, the char** parameter contains a malloc'ed char* pointer.
  // Construct a Python Unicode object (I'm using Python 3) and append it to
  // any existing return value for the wrapper.
  %typemap(argout) char** (PyObject* obj) %{
      obj = PyUnicode_FromString(*$1);
      $result = SWIG_Python_AppendOutput($result,obj);
  %}
#elif defined(SWIGRUBY)
  %typemap(argout) char** (VALUE obj) %{
      obj = SWIG_FromCharPtr(*$1);
      $result = SWIG_Ruby_AppendOutput($result, obj);
  %}
#else
%inline %{
  char * verify_password_update_hash_fix(char *hash, const char *password) {
    char *newhash;
    if (verify_password_update_hash(hash, password, &newhash)) {
      return newhash;
    } else {
      return "";
    }
  }
%}
#endif




%newobject hash_password;
%newobject read_password;
%newobject migrate_password;

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

class PrimitiveWrapper {
    public:
        virtual Primitive *inner() =0;
};

class Argon2i: public PrimitiveWrapper {
    public:
        Argon2i();
        Argon2i(int passes, int lanes, int kib);
        Primitive *inner();
};

class Bcrypt: public PrimitiveWrapper {
  public:
    Bcrypt();
    Bcrypt(int cost);
    Primitive *inner();
};

class Scrypt: public PrimitiveWrapper {
  public:
    Scrypt();
    Scrypt(unsigned char log_n, unsigned int r, unsigned int p);
    Primitive *inner();
};

%nodefaultctor;
%nodefaultdtor;

typedef struct Config {
    %extend {
        static Config *with_primitive(PrimitiveWrapper *p) {
            return config_with_primitive(p->inner());
        }

        char *hash_password(const char *password) {
            return config_hash_password(self, password);
        }

        char *migrate_hash(const char *hash) {
            return config_migrate_hash(self, hash);
        }

        bool verify_password(const char *hash, const char *password) {
            return config_verify_password(self, hash, password);
        }

        bool verify_password_update_hash(const char *hash, const char *password, char **new_hash) {
            return config_verify_password_update_hash(self, hash, password, new_hash);
        }
    }

} Config;

// We intentionally only pull in a subset of the exported functions
// %include "libpasta/libpasta-capi/include/pasta-bindings.h"

// Holds possible configuration options
// See the [module level documentation](index.html) for more information.
struct Config;

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

extern "C" {
char *hash_password(const char *password);
char *migrate_hash(const char *hash);
char *read_password(const char *prompt);
bool verify_password(const char *hash, const char *password);
bool verify_password_update_hash(const char *hash, const char *password, char **new_hash);

} // extern "C"
%module(package="libpasta") pasta
%{
    #include "../libpasta/libpasta-capi/include/pasta.h"
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

%include "libpasta/libpasta-capi/include/pasta.h"
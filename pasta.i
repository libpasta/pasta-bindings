%module(package="libpasta") pasta
%{
    #include "../libpasta/libpasta-capi/include/pasta.h"
%}

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

%include "libpasta/libpasta-capi/include/pasta.h"
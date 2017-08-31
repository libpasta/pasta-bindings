%module pasta
%{
    #include <stdbool.h>

    extern char * hash_password(const char *password);
    extern bool verify_password(const char* hash, const char *password);
    extern void free_string(const char *);
    extern char * read_password(const char *prompt);
%}

%typemap(newfree) char * "free_string($1);";
%newobject hash_password;
%newobject read_password;


%pragma(java) jniclasscode=%{
  static {
    try {
        System.loadLibrary("pasta_jni");
    } catch (UnsatisfiedLinkError e) {
      System.err.println("Native code library failed to load. \n" + e);
      System.exit(1);
    }
  }
%}

%include <pasta.h>
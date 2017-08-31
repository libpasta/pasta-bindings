public class test {
  public static void main(String argv[]) {
    String hash = pasta.hash_password("hello123");
    assert pasta.verify_password(hash, "hello123");
    System.out.println((char)27 + "[1;32mJava test passed." + (char)27 + "[m");
  }
}
import sys
sys.path.insert(1, '../python')
import pasta

hash = pasta.hash_password("hello123")
assert pasta.verify_password(hash, "hello123")
print '\x1b[1;32m' + "Python test passed." + '\x1b[m'

import sys
sys.path.insert(1, '../python')
import libpasta

hash = libpasta.hash_password("hello123")
assert libpasta.verify_password(hash, "hello123")
print '\x1b[1;32m' + "Python test passed." + '\x1b[m'

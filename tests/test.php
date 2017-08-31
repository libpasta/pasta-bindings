<?php
include("../php5/pasta.php");

$hash = pasta::hash_password("hello123"); 
assert(pasta::verify_password($hash, "hello123"));
echo "\033[1;32mPHP test passed.\033[m";
?> 

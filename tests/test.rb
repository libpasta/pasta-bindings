require '../ruby/pasta.so'

hash = Pasta::hash_password("hunter2")
raise "Failed to verify password" unless Pasta::verify_password(hash, "hunter2")
puts "\e[1;32m" + "Ruby test passed." + "\e[m"

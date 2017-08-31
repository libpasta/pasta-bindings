package pasta_test

import "../go"
import "testing"

func TestPasta(t *testing.T) {
    hash := pasta.Hash_password("hello123")
    verify := pasta.Verify_password(hash, "hello123")
    if verify == 0 {
        t.Error("failed to verify correctly")
    }
}
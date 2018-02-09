class CITimeoutException : System.Exception {
    CITimeoutException([string] $msg) : base($msg) {}
    CITimeoutException([string] $msg, [System.Exception] $inner) : base($msg, $inner) {}
}

class CILinterException : System.Exception {
    CILinterException([string] $msg) : base($msg) {}
    CILinterException([string] $msg, [System.Exception] $inner) : base($msg, $inner) {}
}

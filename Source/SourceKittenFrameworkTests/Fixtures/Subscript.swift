struct VoidStruct {
    /// Returns or sets Void.
    subscript(key: String) -> () {
        get { return () }
        set {}
    }
}

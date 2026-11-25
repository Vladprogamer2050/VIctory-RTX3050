fn main() {
    // GPU unit tests create root signatures with directly indexed descriptor
    // heaps, which Windows 10's in-box D3D12 runtime rejects. Export the
    // Agility SDK selectors from the test harness, as victory.exe does.
    if std::env::var("CARGO_CFG_TARGET_ENV").as_deref() == Ok("msvc") {
        println!("cargo:rustc-link-arg=/EXPORT:D3D12SDKVersion,DATA");
        println!("cargo:rustc-link-arg=/EXPORT:D3D12SDKPath,DATA");
    }
}

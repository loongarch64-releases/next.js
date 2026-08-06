#!/bin/sh

SRC=${1}

add_target()
{
    cat << 'EOF' >> "${SRC}/.cargo/config.toml"
[target.loongarch64-unknown-linux-musl]
rustflags = [
  "--cfg", "tokio_unstable",
  "-Zshare-generics=y",
  "-Zthreads=8",
  "-Ctarget-feature=+lsx,+lasx", 
  "-Csymbol-mangling-version=v0",
  "-Clink-arg=-static-libgcc",
]
EOF
}

# 依赖补丁
patch_dep()
{
    cd "${SRC}"
    # 旧版 rustix 与 musl libc 命名冲突
    cargo update -p rustix@1

    # cty 补丁
    cargo fetch

    mkdir -p "${SRC}/third_party"
    local cty_ori=$(find ~/.cargo/registry/src -name cty*)
    local cty_name="$(basename ${cty_ori})"
    local cty_new="${SRC}/third_party/${cty_name}"

    cp -a "${cty_ori}" "${cty_new}"
    sed -i 's/deny(warnings)/allow(warnings)/' "${cty_new}/src/lib.rs"
    sed -i '/target_arch = "mips64"/a \
          target_arch = "loongarch64",' "${cty_new}/src/lib.rs"
    if grep -q "\[patch.crates-io\]" "${SRC}/Cargo.toml"; then
        sed -i "/\[patch.crates-io\]/a\\
cty = { path = \"${cty_new}\" }" "${SRC}/Cargo.toml"
    else
        cat << EOF >> "${SRC}/Cargo.toml"
[patch.crates-io]
cty = { path = "${cty_new}" }
EOF
    fi
}

patch()
{
    echo "patching ..."
    add_target
    patch_dep
    echo "done"
}

patch

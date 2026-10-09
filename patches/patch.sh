#!/bin/sh

SRC=${1}

add_target()
{
    # 这里只开 LSX
    # v16.4.0 把 rust-toolchain 从 nightly-2026-07-29 升到 nightly-2026-08-20,
    # 新 nightly 自带的 LLVM 在 LoongArch LASX 上无法选择
    # `sign_extend_vector_inreg`(v4i64),而 roaring 的
    # RoaringBitmap::intersection_len 被循环向量化成 256 位后正好触发它,
    # 直接以 "rustc-LLVM ERROR: Cannot select: ... sign_extend_vector_inreg" 中断构建。
    # 关掉 LASX 后向量化宽度回到 128 位,可以正常编译(等 LLVM/rustc 修好后再考虑加回)。
    cat << 'EOF' >> "${SRC}/.cargo/config.toml"
[target.loongarch64-unknown-linux-musl]
rustflags = [
  "--cfg", "tokio_unstable",
  "-Zshare-generics=y",
  "-Zthreads=8",
  "-Ctarget-feature=+lsx",
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

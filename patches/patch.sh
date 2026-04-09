#!/bin/sh

SRC=${1}

echo "patching ..."

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

echo "done"

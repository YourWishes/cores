#!/bin/bash
if [ ! -d "dist" ]; then
  mkdir dist
fi
cd dist

# Install emscripten
if [ ! -d "emsdk" ]; then
  git clone https://github.com/emscripten-core/emsdk.git
  cd emsdk
  git checkout 3.1.54
  ./emsdk install 3.1.54
  ./emsdk activate 3.1.54
  source ./emsdk_env.sh
  wget https://raw.githubusercontent.com/EmulatorJS/build/main/emscripten.patch
  patch -u -p0 -i ./emscripten.patch
else
  cd emsdk
  source ./emsdk_env.sh
fi
cd ..

# Get and Build Cores
if [ ! -d "build" ]; then
  git clone https://github.com/EmulatorJS/build.git
fi
if [ -f "../src/cores.json" ]; then
  echo "Copying cores.json"
  rm ./build/cores.json
  sync
  cp ../src/cores.json ./build/cores.json
fi
cd build
chmod +x ./build.sh
echo "Building Cores"
./build.sh

# Copy cores out
cd ../..

if [ ! -d "src" ]; then
  mkdir src
fi
realpath .

# Get all .data files in ./dist/build/output
DATA_FILES=$(find ./dist/build/output -name "*.data")
for file in $DATA_FILES; do
  IS_LEGACY=false
  IS_THREAD=false
  IS_WASM=false
  if [[ $file == *"-legacy"* ]]; then
    IS_LEGACY=true
  fi
  if [[ $file == *"-thread"* ]]; then
    IS_THREAD=true
  fi
  if [[ $file == *"-wasm"* ]]; then
    IS_WASM=true
  fi

  # Get filename without extension
  filename=$(basename -- "$file")
  filename="${filename%.*}"
  OUT_PATH="./src/cores/"

  # Subdir for wasm
  # if [ $IS_WASM = true ]; then
  #   OUT_PATH="$OUT_PATH/wasm"
  # else
  #   OUT_PATH="$OUT_PATH/js"
  # fi

  # Subdir for legacy
  if [ $IS_LEGACY = true ]; then
    OUT_PATH="$OUT_PATH/legacy"
  else
    OUT_PATH="$OUT_PATH/normal"
  fi

  # Subdir for threads
  if [ $IS_THREAD = true ]; then
    OUT_PATH="$OUT_PATH/threads"
  else
    OUT_PATH="$OUT_PATH/sync"
  fi

  # Take the filename and remove all things after -
  filename=$(echo $filename | cut -d'-' -f1)
  OUT_PATH="$OUT_PATH/$filename"

  if [ -d $OUT_PATH ]; then
    rm -rf $OUT_PATH
  fi
  mkdir -p $OUT_PATH

  # Extract 7z file
  7z x $file -o$OUT_PATH
done
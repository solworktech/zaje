#!/bin/sh -e

if [ "$(id -u)" != 0 ];then
    echo "You need super user privileges to run this script."
    exit 1
fi

apt-get -U -y -q install libdeflate-dev libtiff-dev libsharpyuv-dev libwebp-dev libgif-dev \
  liblerc-dev liblzma-dev libjbig-dev libpng-dev libzstd-dev libjpeg-dev build-essential strace

TMPDIR=$(mktemp -d --suffix=_super-zaje)

cd "$TMPDIR"

git clone --depth 1 https://github.com/DanBloomberg/leptonica.git
cd leptonica
./autogen.sh
./configure --with-pic --disable-shared 'CFLAGS=-D DEFAULT_SEVERITY=L_SEVERITY_ERROR -g0 -O3'
make && make install

cd "$TMPDIR"

git clone --depth 1 https://github.com/tesseract-ocr/tesseract.git
cd tesseract
./autogen.sh
./configure --with-pic --disable-shared --disable-legacy --disable-graphics \
--disable-openmp --without-curl --without-archive --disable-doc \
'CXXFLAGS=-DTESS_EXPORTS -g0 -O3 -ffast-math' 
make && make install
wget -q https://github.com/tesseract-ocr/tessdata/raw/refs/heads/main/eng.traineddata -P /usr/local/share/tessdata


cd "$TMPDIR"

BIN_NAME=super-zaje
git clone https://github.com/jessp01/zaje.git --recursive 
cd zaje/cmd/super-zaje  
CGO_ENABLED=1 GOOS=linux go build  -a -tags netgo -ldflags \
    '-extldflags "-static -ldeflate -ltiff -L/usr/local/lib -ldeflate -lsharpyuv -lwebp -lLerc -llzma -ljbig -ltesseract -lleptonica -lpng -lzstd -ljpeg -lz -lgif -lsharpyuv -lwebp"' super-zaje.go

set +e
echo "Let's make sure we got a static binary..."
ldd $BIN_NAME

echo "Okay, now let's test it..."
strace ./$BIN_NAME "https://github.com/jessp01/zaje/blob/master/testimg/go1.png?raw=true"
echo $?
echo "Great. Remember to copy /usr/local/share/tessdata to your target machine." 

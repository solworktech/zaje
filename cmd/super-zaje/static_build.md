#### Static compilation on Debian/Ubuntu

The below will produce a rather chubby binary (29M on my Debian box) but it should run correctly on all modern Linux distros.
If you don't need a static binary, simply follow the relevant install procedure [here](./README.md)

- Install deps:
```sh
apt-get install libdeflate-dev libtiff-dev libsharpyuv-dev libwebp-dev \
  liblerc-dev liblzma-dev libjbig-dev libpng-dev libzstd-dev libjpeg-dev
```

Note: Debian/Ubuntu do provide static archives for both `libleptonica` and `libtesseract` but these are compiled with additional options that `super-zaje` does not need and statically linking against these archives would require the installation of several more `dev` packages.

- Build a statically linked version of libleptonica:

```sh
git clone --depth 1 https://github.com/DanBloomberg/leptonica.git
./autogen.sh
./configure --with-pic --disable-shared 'CFLAGS=-D DEFAULT_SEVERITY=L_SEVERITY_ERROR -g0 -O3'
make
make install
```

- Build a statically linked version of libtesseract:
```sh
git clone --depth 1 https://github.com/tesseract-ocr/tesseract.git
./autogen.sh
./configure --with-pic --disable-shared --disable-legacy --disable-graphics \
--disable-openmp --without-curl --without-archive --disable-doc \
'CXXFLAGS=-DTESS_EXPORTS -g0 -O3 -ffast-math' 
make
make install
```

- Build super-zaje:
```sh
git clone https://github.com/jessp01/zaje.git 
cd zaje/cmd/super-zaje  
CGO_ENABLED=1 GOOS=linux go build  -a -tags netgo -ldflags '-extldflags "-static \
 -ldeflate -ltiff  -L/usr/local/lib -ldeflate -lsharpyuv -lwebp -lLerc -llzma \
 -ljbig -ltesseract -lleptonica -lpng -lzstd -ljpeg -lz -lgif -lsharpyuv -lwebp"' super-zaje.go
```

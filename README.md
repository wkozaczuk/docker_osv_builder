# Docker OSv builder
Docker container along with other scripts to build OSv kernel and packages

Build container
```
docker build -t osv/builder .
```

Run container
```
docker run -it --privileged --volume="$PWD/result:/result" osv/builder
```

After starting you will end up in /capstan-packages directory
where you can execute build_packages.sh scripts to build all
and individual packages like so:
```bash
./build_packages.sh all
./build_packages.sh osv_loader_and_bootstrap # builds kernel
./build_packages.sh generic_app "ffmpeg" "4.0.2" "/ffmpeg.so -formats" #builds specific app package
```

Resulting mpm files will end up in /capstan-packages/output.

The publish_packages.sh script can be used to copy produced artifacts
to the local $HOME/.capstan repository.

# Docker OSv builder
Docker container along with other scripts to build OSv kernel and packages

Build container
```
docker build -t osv/builder .
```

Run container
```
docker run -it --volume="$PWD/result:/result" osv/builder
```

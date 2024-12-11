

## https://github.com/WeihanLi/dotnet-httpie/blob/dev/Dockerfile

FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet-buildtools/prereqs:azurelinux-3.0-net9.0-cross-arm64-musl AS cross-build-env

FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:9.0-alpine AS build-env

COPY --from=cross-build-env /crossrootfs /crossrootfs

ARG TARGETARCH
ARG BUILDARCH

# Configure NativeAOT Build Prerequisites 
# https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/?tabs=linux-alpine%2Cnet8
# for alpine
RUN apk update && apk add clang build-base zlib-dev

WORKDIR /src
COPY --link nuget.config .
COPY ["src/webapi/webapi.csproj", "src/webapi/"]
COPY . .
WORKDIR "/src/src/webapi"

RUN if [ "${TARGETARCH}" = "${BUILDARCH}" ]; then \
      dotnet publish -f net9.0  "webapi.csproj" --use-current-runtime  -p:TargetFrameworks=net9.0 -o /app/publish; \
    else \
      apk add binutils-aarch64 --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community; \
      dotnet publish -f net9.0   "webapi.csproj" -r linux-musl-arm64  -p:TargetFrameworks=net9.0 -p:SysRoot=/crossrootfs/arm64 -p:ObjCopyName=aarch64-alpine-linux-musl-objcopy -o /app/publish; \
    fi

RUN rm /app/publish/*.dbg /app/publish/*.Development.json

FROM alpine

WORKDIR /app

COPY --from=build-env /app/publish .
USER $APP_UID
ENV TZ=Asia/Shanghai
WORKDIR /app
EXPOSE 8080
ENTRYPOINT ["./webapi"]
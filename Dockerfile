
# 此阶段用于生成服务项目
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/nightly/sdk:9.0-noble-aot AS build
ARG TARGETARCH
RUN apt-get update \
    && apt-get install -y \
        clang \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY --link nuget.config .
COPY ["src/webapi/webapi.csproj", "src/webapi/"]
RUN dotnet restore "src/webapi/webapi.csproj" -r linux-$TARGETARCH
COPY . .
WORKDIR "/src/src/webapi"
RUN dotnet publish -r linux-$TARGETARCH --no-restore "webapi.csproj"  -o /app/publish 

RUN rm /app/publish/*.dbg /app/publish/*.Development.json

# 此阶段在生产中使用，或在常规模式下从 VS 运行时使用(在不使用调试配置时为默认值)
#FROM mcr.microsoft.com/dotnet/nightly/runtime-deps:9.0-noble-chiseled-aot
FROM mcr.microsoft.com/dotnet/nightly/runtime-deps:9.0-noble
WORKDIR /app
COPY --from=build /app/publish .
USER $APP_UID
WORKDIR /app
EXPOSE 8080
ENTRYPOINT ["./webapi"]
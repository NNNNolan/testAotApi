# 请参阅 https://aka.ms/customizecontainer 以了解如何自定义调试容器，以及 Visual Studio 如何使用此 Dockerfile 生成映像以更快地进行调试。

# 此阶段用于在快速模式(默认为调试配置)下从 VS 运行时
FROM mcr.microsoft.com/dotnet/nightly/runtime-deps:9.0-alpine-aot AS base
USER $APP_UID
WORKDIR /app
EXPOSE 8080


# 此阶段用于生成服务项目
FROM mcr.microsoft.com/dotnet/nightly/sdk:9.0-alpine-aot AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["src/webapi/webapi.csproj", "src/webapi/"]
RUN dotnet restore "./src/webapi/webapi.csproj" -r linux-musl-$TARGETARCH
COPY . .
WORKDIR "/src/src/webapi"
# RUN dotnet build "./webapi.csproj" -c $BUILD_CONFIGURATION -o /app/build

# 此阶段用于发布要复制到最终阶段的服务项目
# FROM build AS publish
# ARG BUILD_CONFIGURATION=Release
# RUN dotnet publish "./webapi.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false -c $BUILD_CONFIGURATION \
RUN dotnet publish --no-restore "./webapi.csproj" \
    -o /app/publish \
    --self-contained true \
    -p:PublishSingleFile=true \
    -p:PublishTrimmed=true \
    -p:UseAppHost=true \
    -p:EnableCompressionInSingleFile=true

RUN rm /app/publish/*.dbg /app/publish/*.Development.json

# 此阶段在生产中使用，或在常规模式下从 VS 运行时使用(在不使用调试配置时为默认值)
FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["./webapi"]
# 基础参数定义
ARG DOTNET_VERSION=9.0
ARG LAUNCHING_FROM_VS
ARG FINAL_BASE_IMAGE=${LAUNCHING_FROM_VS:+aotdebug}

# 基础阶段 - 用于开发调试
FROM mcr.microsoft.com/dotnet/aspnet:${DOTNET_VERSION} AS base
WORKDIR /app
EXPOSE 8080

# 构建阶段
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_VERSION} AS build
# 安装必要的依赖
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        clang \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# 首先只复制项目文件并还原依赖
COPY ["src/webapi/webapi.csproj", "src/webapi/"]
RUN dotnet restore "./src/webapi/webapi.csproj"

# 复制整个解决方案
COPY . .
WORKDIR "/src/src/webapi"

# 构建项目
RUN dotnet build "./webapi.csproj" \
    -c $BUILD_CONFIGURATION \
    -o /app/build

# 发布阶段
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
# 发布为自包含应用，并启用 ReadyToRun 编译
RUN dotnet publish "./webapi.csproj" \
    -c $BUILD_CONFIGURATION \
    -o /app/publish \
    --self-contained true \
    -p:PublishSingleFile=true \
    -p:PublishTrimmed=true \
    -p:UseAppHost=true \
    -p:EnableCompressionInSingleFile=true

# 最终阶段 - 使用 runtime-deps
FROM ${FINAL_BASE_IMAGE:-mcr.microsoft.com/dotnet/runtime-deps:9.0} AS final
WORKDIR /app
EXPOSE 8080
COPY --from=publish /app/publish .
ENTRYPOINT ["./webapi"]
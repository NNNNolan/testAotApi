
# 此阶段用于生成服务项目
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG TARGETARCH
RUN apt-get update \
    && apt-get install -y \
        clang \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY --link nuget.config .
COPY ["src/webapi/webapi.csproj", "src/webapi/"]
RUN dotnet restore "./src/webapi/webapi.csproj" -r linux-musl-$TARGETARCH
COPY . .
WORKDIR "/src/src/webapi"
# RUN dotnet build "./webapi.csproj" -c $BUILD_CONFIGURATION -o /app/build

# 此阶段用于发布要复制到最终阶段的服务项目
# FROM build AS publish
# ARG BUILD_CONFIGURATION=Release
# RUN dotnet publish "./webapi.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false -c $BUILD_CONFIGURATION \
RUN dotnet publish --no-restore "./webapi.csproj" \ -c Release -r linux-musl-$TARGETARCH
    -o /app/publish 

RUN rm /app/publish/*.dbg /app/publish/*.Development.json

# 此阶段在生产中使用，或在常规模式下从 VS 运行时使用(在不使用调试配置时为默认值)
FROM mcr.microsoft.com/dotnet/runtime-deps:9.0
WORKDIR /app
COPY --from=build /app/publish .
USER $APP_UID
WORKDIR /app
EXPOSE 8080
ENTRYPOINT ["./webapi"]
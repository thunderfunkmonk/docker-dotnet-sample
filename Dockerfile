# syntax=docker/dockerfile:1
# set this above syntax parser directive to docker/dockerfile:1, which causes Builit to pull the latest stable version of the Dockerfile syntax before the build.

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/go/dockerfile-reference/

# Want to help us make this template better? Share your feedback here: https://forms.gle/ybq9Krt8jtBL3iCk7

################################################################################

# Learn about building .NET container images:
# https://github.com/dotnet/dotnet-docker/blob/main/samples/README.md

# Create a stage for building the application.
FROM --platform=$BUILDPLATFORM dhi.io/dotnet:10-sdk AS build

ENV BUILD_ENV_VAR_1=example1   
#only visible to build stage, not final stage

COPY . /source

WORKDIR /source/src

# This is the architecture you’re building for, which is passed in by the builder.
# Placing it here allows the previous steps to be cached across architectures.
ARG TARGETARCH

# Build the application.
# Leverage a cache mount to /root/.nuget/packages so that subsequent builds don't have to re-download packages.
# If TARGETARCH is "amd64", replace it with "x64" - "x64" is .NET's canonical name for this and "amd64" doesn't
#   work in .NET 6.0.
RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    dotnet publish -a ${TARGETARCH/amd64/x64} --use-current-runtime --self-contained false -o /app

# If you need to enable globalization and time zones:
# https://github.com/dotnet/dotnet-docker/blob/main/samples/enable-globalization.md
################################################################################
# Create a new stage for running the application that contains the minimal
# runtime dependencies for the application. This often uses a different base
# image from the build stage where the necessary files are copied from the build
# stage.
#
# The example below uses an aspnet alpine image as the foundation for running the app.
# It will also use whatever happens to be the most recent version of that tag when you
# build your Dockerfile. If reproducibility is important, consider using a more specific
# version (e.g., aspnet:7.0.10-alpine-3.18),
# or SHA (e.g., mcr.microsoft.com/dotnet/aspnet@sha256:f3d99f54d504a21d38e4cc2f13ff47d67235efeeb85c109d3d1ff1808b38d034).
FROM dhi.io/aspnetcore:10 AS final

#ENV APP_START_FOLDER=/app
#ENV APP_ENVIRONMENT=DEV
#instead, pulled from (overriden by) .env file in compose.yaml, which is a better way to set environment variables for the final stage, since it doesn't require rebuilding the image to change the value of the variable.
WORKDIR $APP_START_FOLDER

# Copy everything needed to run the app from the "build" stage.
COPY --from=build /app .

# Switch to a non-privileged user (defined in the base image) that the app will run under.
# See https://docs.docker.com/go/dockerfile-user-best-practices/
# and https://github.com/dotnet/dotnet-docker/discussions/4764
USER $APP_UID

ENTRYPOINT ["dotnet", "myWebApp.dll"]
#ENTRYPOINT ["/bin/bash", "-c", "echo hello"]
#RUN ["c:\\windows\\system32\\tasklist.exe"]
#RUN [ "echo", "$HOME" ]
#SHELL ["/bin/bash", "-c"]
#RUN echo hello
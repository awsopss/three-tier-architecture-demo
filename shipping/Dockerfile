# #
# # Build
# #
# FROM debian:10 AS build

# RUN apt-get update && apt-get -y install maven

# WORKDIR /opt/shipping

# COPY pom.xml /opt/shipping/
# RUN mvn dependency:resolve
# COPY src /opt/shipping/src/
# RUN mvn package

# #
# # Run
# #
# FROM openjdk:8-jdk

# EXPOSE 8080

# WORKDIR /opt/shipping

# ENV CART_ENDPOINT=cart:8080
# ENV DB_HOST=mysql

# COPY --from=build /opt/shipping/target/shipping-1.0.jar shipping.jar

# CMD [ "java", "-Xmn256m", "-Xmx768m", "-jar", "shipping.jar" ]

#
# Build Stage
#
FROM maven:3.6.3-jdk-8 AS build

WORKDIR /opt/shipping

# Copy only the necessary files for dependency resolution first
COPY pom.xml /opt/shipping/

# Resolve dependencies (caching this layer)
RUN mvn dependency:resolve

# Now copy the full source and package the application
COPY src /opt/shipping/src/
RUN mvn package

#
# Run Stage
#
FROM openjdk:8-jdk

WORKDIR /opt/shipping

# Expose port 8080
EXPOSE 8080

# Set environment variables
ENV CART_ENDPOINT=cart:8080
ENV DB_HOST=mysql

# Copy the jar from the build stage to the runtime stage
COPY --from=build /opt/shipping/target/shipping-1.0.jar shipping.jar

# Set the JVM options and run the application
CMD ["java", "-Xms256m", "-Xmx768m", "-jar", "shipping.jar"]

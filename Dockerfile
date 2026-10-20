FROM tomcat:10.1-jdk21-temurin AS build

WORKDIR /workspace
COPY src/main/java/ src/main/java/
COPY src/main/webapp/ src/main/webapp/

RUN mkdir -p /tmp/war/WEB-INF/classes \
    && cp -R src/main/webapp/. /tmp/war/ \
    && find src/main/java -type f -name '*.java' -print0 \
        | xargs -0 javac --release 21 -encoding UTF-8 \
            -classpath "$CATALINA_HOME/lib/servlet-api.jar" \
            -d /tmp/war/WEB-INF/classes \
    && jar --create --file /tmp/Internship_Portal.war -C /tmp/war .

FROM tomcat:10.1-jdk21-temurin

RUN sed -i 's/port="8080"/port="${http.port}"/' "$CATALINA_HOME/conf/server.xml"

COPY --from=build /tmp/Internship_Portal.war "$CATALINA_HOME/webapps/Internship_Portal.war"

EXPOSE 8080

CMD ["sh", "-c", "export CATALINA_OPTS=\"${CATALINA_OPTS:-} -Dhttp.port=${PORT:-8080}\"; exec catalina.sh run"]

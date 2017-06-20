+++
date = "2017-06-237T17:46:17+02:00"
draft = true
title = "Maven and Docker, some thoughts..."
author = ""
comments = true
image = "images/june-2017/mvn-docker.jpg"
menu = ""
share = ""
slug = "MavenAndDocker"
tags = [ "docker", "maven", "java" ]

+++


***

**[TL;DR]**

Various strategies are available when using Docker-based Integration test in the Java development lifecycle. This article describes and compares a Maven centric and a more loosely coupled strategy.

***

Integration tests with Docker is a dream come true. 

For years, I have been struggling to get hold of Test Environments where I could validate my software. Docker makes it easy and cheap. Further it allows validation on near Production configuration. 
It is also a powerful tool for efficient cooperation between developers and production. Ops people can actively participate to the design and configuration of the deployed application.

### The Maven Docker Plugin

As soon as I learned about Docker, I actively used it in my Java development. It allowed me to automatically test cases not easily tested otherwise with large databases shared with multiple developers. On my Oracle Database container, I could test complex database structure alteration (and roll back) for example. [Flyway](https://flywaydb.org/) and [DBunit](http://dbunit.sourceforge.net/) are fundamental tools to achieve efficient automation. 

**Flyway** is a handy database versioning tool. **DBunit** allows to setup tables and data before running tests and validate that the resulting data is the expected one.

Maven is now the mainstream Java build tool. Beside efficient dependency management, it combines many useful tools for managing unit tests, code quality checks or integration tests.  For a Java developer, integrating the setup of Docker containers in Maven comes naturally. The plugin I felt most comfortable with is [fabric8io/docker-maven-plugin](https://dmp.fabric8.io/). It is very complete and regularly maintained.

This plugin allows to execute the equivalent Docker commands (build, run, stop, etc) as Maven Goals and attach them to phases. What is usually done is to attach the `docker:build` and `docker:start` goals to the `pre-integration-test` phase and the `docker:stop` to the `post-integration-test` phase. In the example below, an Oracle database is started and configured before the actual integration tests are run (java test classes ending with IT). When the integration tests complete, the docker container is stopped. Note that the example below uses fixed ports and addresses. It is not Continuous Integration ready. But this is an other story.

{{< highlight xml >}}
<profile>
    <id>withIntegrationTest</id>
    <!--These tests can come in the way of somebody that doesn't have a docker ready environment. So it is better to give a way to skip them-->
    <build>
        <plugins>

            <!-- Integration test plugin (using defaults)-->       
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-failsafe-plugin</artifactId>
                <version>2.13</version>
                <executions>
                    <execution>
                        <id>integration-test</id>
                        <goals>
                            <goal>integration-test</goal>
                        </goals>
                    </execution>
                    <execution>
                        <id>verify</id>
                        <goals>
                            <goal>verify</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            
            <!-- Docker related stuff -->
            <plugin>
                <groupId>io.fabric8</groupId>
                <artifactId>docker-maven-plugin</artifactId>
                <version>${docker.maven.plugin.version}</version>
                <configuration>
                    <logDate>default</logDate>
                    <images>
                        <!-- Docker Image to use -->
                        <image>
                            <alias>ODS_DB</alias>
                            <!-- Docker Image-->
                            <name>alexeiled/docker-oracle-xe-11g:latest</name>
                            <run>
                                <ports>
                                    <port>49160:22</port>
                                    <port>49161:1521</port>
                                    <port>49162:8080</port>
                                </ports>
                                <wait>
                                    <log>DB server startup</log>
                                    <time>30000</time>
                                </wait>
                            </run>
                        </image>
                    </images>
                </configuration>
                <executions>
                    <execution>
                        <id>start</id>
                        <phase>pre-integration-test</phase>
                        <goals>
                            <goal>build</goal>
                            <goal>start</goal>
                        </goals>
                    </execution>
                    <execution>
                        <id>stop</id>
                        <phase>post-integration-test</phase>
                        <goals>
                            <goal>stop</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>

            <!-- Daatabase setup stuff -->
            <plugin>
                <groupId>org.flywaydb</groupId>
                <artifactId>flyway-maven-plugin</artifactId>
                <version>${flyway.maven.plugin.version}</version>
                <configuration>
                    <url>jdbc:oracle:thin:@//localhost:49161/xe</url>
                    <user>system</user>
                    <password>oracle</password>
                    <schemas>
                        <schema>FLYWAY</schema>
                    </schemas>
                    <baselineOnMigrate>true</baselineOnMigrate>
                </configuration>
                <executions>
                    <execution>
                        <id>dbSetup</id>
                        <phase>pre-integration-test</phase>
                        <goals>
                            <goal>migrate</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            
        </plugins>
    </build>
</profile> 
{{< /highlight >}}

This setup is very natural for someone used to work with Maven and familiar with its XML syntax. It easily answers the two main use cases: 

* run all tests (unit and integration) automatically with a single `mvn verify` or `mvn install` command.
* start and setup the integration environment for debugging with an IDE (`mvn docker:start`) and then tear it down (`mvn docker:stop`).

But I came to the conclusion that for more complex cases, this was leading to a dead end.

### Strong points

1. If Maven literate, its use is natural. No need to be a Docker expert.
2. It is easy to integrate in existing build (Maven) workflows
3. A single command will setup the Docker environment needed for Integration tests

### Weak points

1. Adds an extra layer on top of the Docker API that needs to be adapted at every new release (and we all know that the project is very prolific).
2. The plugin is not suited for handling complex infrastructure (as described in docker-compose files). It is tedious, verbose and especially in a "language" that is not well practiced outside of the Java Developer world. Note that there has been some effort to support docker-compose syntax as an descriptor for the plugin. But it keeps running behind the real product as it is a re-write of the original tool.
3. As a consequence of the above point, the plugin misses an important aspect of the Docker technology: being a DevOps enabler.

Strong coupling with a tool

Docker promotes the cooperation between the development and the infrastructure/operation world. While Devs can enter the world of infrastructure and Ops can participate early in the development cycle, each pole has its tools of the trade. Docker-compose files are the tools of the trade to describe complex docker infrastructure (container dependencies, networks, volumes, etc.)

With the plugin specific language we create a communication gap between the two entities. The goal should be that the Ops part of the project contributes to the infrastructure part in such a way that it is used from the early stages of Dev continuously up to the production. This is particularly true for Integration tests where the more Production-like the setup the better the quality of the testing.

The docker-compose file and tool should be used end to end.

The Docker Maven Plugin is best suited for simple integration tests (single container as a database as in the sample) and when continuous delivery is not the goal. 

## Maven plugin

* catching up with the Docker releases
* its own maven language
* Compose files are not portable
* poor integration of existing docker-compose
* easy to start as part of a maven goal
* best suited to simple infrastructure

## exec

* sinple integration
* portable 
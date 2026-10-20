# Internship Portal

An Eclipse Dynamic Web Project for managing student internships, staff reviews,
and administrative reports.

## Verified project stack

- Java 21 (Eclipse compiler compliance and project facet settings)
- Eclipse Dynamic Web Project
- Jakarta Servlet 6.0 / Jakarta EE web-app descriptor version 6.0
- Apache Tomcat 10.1 project runtime
- MySQL, accessed through JDBC
- MySQL Connector/J 9.7.0, included at
  `src/main/webapp/WEB-INF/lib/mysql-connector-j-9.7.0.jar`
- Java sources: `src/main/java`
- JSPs and web resources: `src/main/webapp`

The project Eclipse metadata includes a Tomcat 10.1 runtime target. This does
not include the Tomcat installation itself.

## Eclipse import and run prerequisites

1. Install Eclipse IDE with the Java and Web Tools Platform (WTP) features.
2. Install a Java 21 JDK and configure Eclipse to use it for this project.
3. Install Apache Tomcat 10.1 and configure it as an Eclipse server runtime.
4. Import the project into Eclipse as an existing project from its project
   directory. The checked-in `.project`, `.classpath`, and `.settings/`
   configure the Eclipse project, source path, Java version, web resources,
   and runtime target.
5. Configure a MySQL server and database compatible with the application
   before starting the web application.
6. Configure the required database environment variables for the process
   running Tomcat, then publish/run the project on the configured server.

**Not verified:** successful import or startup in another Eclipse installation,
the exact Eclipse distribution/plugins required, the installed JDK/Tomcat/MySQL
versions on another machine, and end-to-end application behavior.

## Database configuration

The application reads these environment variables in
`com.internship.DBConnector`:

- `DB_URL` — JDBC connection URL
- `DB_USER` — database username
- `DB_PASSWORD` — database password

Set them in the environment available to the Tomcat process. Do not commit
actual credentials or local environment files. No database credential values
are provided in this repository.

The repository includes
[`database/phase_8e_password_columns.sql`](database/phase_8e_password_columns.sql).
It changes the `password` columns in the existing `student`, `staff`, and
`admin` tables to `VARCHAR(255)`. The script documents that existing password
values are not rewritten; the application migrates a legacy credential after
a successful login. Its commented rollback is conditional and warns that it
can truncate longer values.

This is an existing-database migration, **not** a complete schema or fresh
database setup. The repository does not include a complete schema, seed data,
or verified database initialization procedure. The required tables and their
full column definitions, relationships, and initial administrative account
setup have not been verified here. Do not apply the migration to a database
without first confirming the existing schema and taking an appropriate
backup.

**Not verified:** a complete new-database installation path, the schema
expected by every application query, and a successful connection to a
configured MySQL instance.

## Dependencies and licensing

MySQL Connector/J is manually included under `WEB-INF/lib` and is required by
the current project setup. Tomcat provides the Servlet/JSP APIs. The JSP pages
load Bootstrap and Bootstrap Icons from jsDelivr at runtime.

The bundled Connector/J JAR contains Oracle licensing information, including
GPLv2 with additional permissions and the Universal FOSS Exception. Review the
license notice in the JAR and applicable distribution requirements before
redistributing it.

## Data and credentials

The application handles student/staff account information and internship
documents, including bank statements and stipend proof. Do not commit real
student/staff data, database dumps, passwords, credentials, uploaded
documents, or other personal information. The upload code uses a directory
under the Tomcat process user's home directory, outside the project by
default.

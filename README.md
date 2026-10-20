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
5. Follow the fresh database setup below and configure the required environment
   variables for the process running Tomcat.
6. Start Tomcat 10.1 in Eclipse and publish/run the project on that server.

**Not verified:** successful import or startup in another Eclipse installation,
the exact Eclipse distribution/plugins required, the installed JDK/Tomcat/MySQL
versions on another machine, and end-to-end application behavior.

## Fresh database setup

1. Create a new MySQL database using `utf8mb4`. For example, using your chosen
   database name:

   ```sql
   CREATE DATABASE internship_portal CHARACTER SET utf8mb4;
   ```

2. Open a MySQL client, create/select the database, and apply
   [`database/schema.sql`](database/schema.sql). For example, in the MySQL
   command-line client, run:

   ```sql
   CREATE DATABASE internship_portal CHARACTER SET utf8mb4;
   USE internship_portal;
   SOURCE path/to/Internship Portal/database/schema.sql;
   ```

   Replace the `SOURCE` path with the actual path to this project's schema
   file. The schema creates `staff`, `student`, `admin`, and `internship`,
   including their primary keys, foreign keys, and indexes.
3. Configure these environment variables for the operating-system process
   running Tomcat:

   - `DB_URL` — MySQL Connector/J JDBC URL for the database
   - `DB_USER` — database account
   - `DB_PASSWORD` — database account password

   Use a database account with only the privileges the application needs.
   Provide the values through the Tomcat service/runtime environment; do not
   put real credentials in this repository. Restart Tomcat after changing its
   environment.
4. Provision the first administrator securely as described below. No default
   administrator is created by the schema.

### Existing-database migration

[`database/phase_8e_password_columns.sql`](database/phase_8e_password_columns.sql)
is only for upgrading an existing database whose `student`, `staff`, and
`admin` password columns are still `VARCHAR(100)`. **Do not run it after
applying the fresh `database/schema.sql`**: the fresh schema already defines
those columns as `VARCHAR(255)`. The migration does not initialize a fresh
database and does not rewrite existing credential values.

### Provisioning the first administrator

The application has no admin registration flow and the schema intentionally
contains no seed account. Login selects the `admin` row by `admin_id`; the
`username` column is used as the display name.

Use a trusted, temporary local bootstrap utility that calls the existing
`com.internship.PasswordHasher.hash` implementation and inserts the resulting
PBKDF2 record with a JDBC `PreparedStatement` for:

```sql
INSERT INTO admin (admin_id, username, password) VALUES (?, ?, ?);
```

Have the utility read the new password interactively without echo (for
example, with Java `Console.readPassword()`), enforce the existing
12-character minimum, hash it in memory, and bind the identifier, display
name, and hash as parameters. Do not hardcode, log, pass on a command line, or
commit the plaintext password or hash. Keep the database connection settings
in the Tomcat/application environment, not in source. Remove the temporary
bootstrap utility and generated files after successful provisioning. No
initial admin identifier, name, or credential is supplied by this project.

### Schema compatibility and assumptions

The Java and JSP SQL references require the four tables and columns defined in
`database/schema.sql`. Java binds account IDs as strings; `internship_id` is
parsed/bound/read as an integer; internship dates use JDBC `DATE`. The source
does not verify the original account-ID formats or maximum lengths, most
column widths, all nullability rules, or an existing deployment's constraints.
The schema therefore makes explicit compatibility choices: 64-character
account IDs, 150-character names/departments and company names, 254-character
emails, 512-character stored document paths, and the nullable/required fields
shown in the DDL. Password width is established by the existing migration as
255 characters. `internship_id` is an auto-incrementing signed `INT` so new
submissions receive an identifier.

The `student.mentor_id` foreign key uses `ON DELETE SET NULL` to support
unassigned students and staff deletion. The internship-to-student foreign key
uses `ON DELETE CASCADE`, matching relational cleanup when deleting a student;
the application handles document files separately, and verify any orphan-file
cleanup/retention policy before production use. The indexes beyond primary
and foreign keys are performance choices based on observed filters and joins,
not constraints required by the SQL statements. Email uniqueness and database
`CHECK` constraints are not imposed because the source does not establish
those requirements.

The schema is a proposed fresh-install compatibility schema, not a verified
reconstruction of an undocumented historical schema. It has not been run
against a MySQL server or validated by an application integration test.

## Internship document storage

The application writes internship documents, including bank statements and
stipend proof, under `EEC_Internship_Uploads` in the Tomcat process user's home
directory. Deployment therefore requires persistent, writable, access-
controlled storage outside the repository and webroot, with appropriate
backup and retention controls. Protect this directory as sensitive personal
data.

## Dependencies and licensing

MySQL Connector/J is manually included under `WEB-INF/lib` and is required by
the current project setup. Tomcat provides the Servlet/JSP APIs. The JSP pages
load Bootstrap and Bootstrap Icons from jsDelivr at runtime.

The bundled Connector/J JAR contains Oracle licensing information, including
GPLv2 with additional permissions and the Universal FOSS Exception. Review the
license notice in the JAR and applicable distribution requirements before
redistributing it.

## Data and credentials

Do not commit real student/staff data, database dumps, passwords, credentials,
uploaded documents, or other personal information.

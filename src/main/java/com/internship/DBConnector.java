package com.internship;

import java.sql.Connection;
import java.sql.DriverManager;

public class DBConnector {

    public static Connection getConnection() {

        Connection con = null;

        String url = System.getenv("DB_URL");
        String user = System.getenv("DB_USER");
        String password = System.getenv("DB_PASSWORD");

        if (isBlank(url) || isBlank(user) || isBlank(password)) {
            System.err.println("Database configuration error.");
            return null;
        }

        try {

            Class.forName("com.mysql.cj.jdbc.Driver");

            con = DriverManager.getConnection(
                    url,
                    user,
                    password
            );

        }
        catch(Exception e) {

            System.err.println("Database connection error.");
        }

        return con;
    }

    private static boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}

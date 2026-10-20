package com.internship;

import java.sql.Connection;

public class TestConnection {

    public static void main(String[] args) {

        Connection con =
                DBConnector.getConnection();

        if(con != null) {

            System.out.println(
                    "Connection Successful"
            );
        }
        else {

            System.out.println(
                    "Connection Failed"
            );
        }
    }
}
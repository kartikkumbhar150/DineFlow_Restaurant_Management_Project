package com.project.spring.service.master;

import com.project.spring.model.master.MasterBusiness;
import com.project.spring.repo.master.MasterBusinessRepository;
import com.project.spring.repo.master.StaffUserRepository;
import com.project.spring.model.master.StaffUser;
import com.project.spring.config.MasterDatabaseProperties;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.util.Optional;
import java.util.UUID;

@Service
public class BusinessProvisionService {

    @Autowired
    private MasterBusinessRepository masterRepo;

    @Autowired
    private StaffUserRepository staffUserRepo;

    @Autowired
    private MasterDatabaseProperties masterDbProps;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder(12);

    public String createBusiness(String name, String password, String dbNamee, String ownerName,
                                 String userName, Long phoneNo, String email) {

        Optional<MasterBusiness> existing = masterRepo.findByDbName(dbNamee);
        if (existing.isPresent()) {
            throw new RuntimeException("Username already exists");
        }

        String baseName = name.trim().toLowerCase().replaceAll("[^a-z0-9]", "_");
        String dbName = "business_" + baseName + "_" + UUID.randomUUID().toString().substring(0, 3);

        createDatabase(dbName);
        initializeSchema(dbName);

        // Create one default row
        createDefaultBusinessRow(dbName, name, phoneNo, email);

        MasterBusiness business = new MasterBusiness();
        business.setBusinessName(name);
        business.setOwnerName(ownerName);
        business.setDbName(dbName);
        business.setPhoneNo(phoneNo);
        business.setEmail(email);

        masterRepo.save(business);

        StaffUser staffUser = new StaffUser();
        staffUser.setName(ownerName);
        staffUser.setUserName(userName);
        staffUser.setPassword(passwordEncoder.encode(password));
        staffUser.setDbName(dbName);
        staffUser.setRole("ADMIN");

        staffUserRepo.save(staffUser);

        return dbName;
    }

    private void createDatabase(String dbName) {
        String masterDbUrl = masterDbProps.getJdbcUrl();
        String dbUsername = masterDbProps.getUsername();
        String dbPassword = masterDbProps.getPassword();

        try (Connection conn = DriverManager.getConnection(masterDbUrl, dbUsername, dbPassword)) {
            Statement stmt = conn.createStatement();
            stmt.executeUpdate("CREATE DATABASE \"" + dbName + "\"");
            System.out.println("Created database: " + dbName);
        } catch (Exception e) {
            throw new RuntimeException("DB creation failed: " + e.getMessage(), e);
        }
    }

    private void initializeSchema(String dbName) {
    String tenantDbUrl = masterDbProps.getFirstUrl() + dbName + masterDbProps.getLastUrl();
    String dbUsername = masterDbProps.getUsername();
    String dbPassword = masterDbProps.getPassword();

    try (Connection conn = DriverManager.getConnection(tenantDbUrl, dbUsername, dbPassword)) {
        Statement stmt = conn.createStatement();

        String schema = """
            CREATE TABLE business (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                gst_number VARCHAR(20) UNIQUE,
                fssai_no VARCHAR(20) UNIQUE,
                address VARCHAR(200),
                gst_type INTEGER,
                licence_no VARCHAR(200) UNIQUE,
                phone_no VARCHAR(20),
                email VARCHAR(100),
                table_count INTEGER,
                logo_url VARCHAR(500) DEFAULT 'https://res.cloudinary.com/dummy/image/upload/v1234567890/default_logo.png'
            );

            CREATE TABLE products (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                description VARCHAR(200),
                category VARCHAR(100),
                subCategory VARCHAR(100),
                price INTEGER
            );

            CREATE TABLE orders (
                id BIGSERIAL PRIMARY KEY,
                is_completed BOOLEAN,
                table_number BIGINT
            );

            CREATE TABLE order_item (
                id SERIAL PRIMARY KEY,
                item_name VARCHAR(255),
                price INTEGER NOT NULL,
                quantity INTEGER NOT NULL,
                order_id BIGINT,
                product_id BIGINT,
                CONSTRAINT fk_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
                CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES products(id)
            );

            CREATE TABLE invoice (
                id SERIAL PRIMARY KEY,
                customer_name VARCHAR(255),
                customer_phoneno VARCHAR(20),
                date VARCHAR(255),
                invoice_number BIGINT,
                item_description VARCHAR(25555),
                payment_status VARCHAR(255),
                quantity INTEGER NOT NULL,
                sub_total DOUBLE PRECISION NOT NULL DEFAULT 0,
                sgst DOUBLE PRECISION NOT NULL DEFAULT 0,
                cgst DOUBLE PRECISION NOT NULL DEFAULT 0,
                grand_total DOUBLE PRECISION NOT NULL DEFAULT 0,
                total_amount DOUBLE PRECISION NOT NULL,
                gst_value DOUBLE PRECISION,
                business_id BIGINT,
                "time" VARCHAR(255),
                table_number BIGINT,
                business_gst_type BIGINT,
                order_id BIGINT
            );

            CREATE TABLE staff (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255),
                password VARCHAR(255) NOT NULL,
                role VARCHAR(255),
                user_name VARCHAR(255) NOT NULL UNIQUE
            );

            CREATE TABLE inventory (
                id SERIAL PRIMARY KEY,
                item_name VARCHAR(255),
                quantity INTEGER,
                unit VARCHAR(255),
                price BIGINT,
                date VARCHAR(255),
                time VARCHAR(255)
            );

            -- ======================
            -- 📌 PERFORMANCE INDEXES
            -- ======================

            -- Invoices
            CREATE INDEX IF NOT EXISTS idx_invoice_date       ON invoice (date);
            CREATE INDEX IF NOT EXISTS idx_invoice_number    ON invoice (invoice_number);
            CREATE INDEX IF NOT EXISTS idx_invoice_time      ON invoice ("time");
            CREATE INDEX IF NOT EXISTS idx_invoice_business  ON invoice (business_id);

            -- Orders
            CREATE INDEX IF NOT EXISTS idx_orders_table      ON orders (table_number);

            -- Order Items
            CREATE INDEX IF NOT EXISTS idx_orderitem_order   ON order_item (order_id);
            CREATE INDEX IF NOT EXISTS idx_orderitem_product ON order_item (product_id);

            -- Products
            CREATE INDEX IF NOT EXISTS idx_products_name     ON products (name);

            -- Staff
            CREATE INDEX IF NOT EXISTS idx_staff_username    ON staff (user_name);
            
            CREATE INDEX idx_orders_active_table    ON orders (table_number, is_completed);

            -- Inventory
            CREATE INDEX IF NOT EXISTS idx_inventory_date    ON inventory (date);
        """;

        String[] queries = schema.split(";");

        for (String q : queries) {
            String trimmed = q.trim();
            if (trimmed.isEmpty()) continue;
            stmt.executeUpdate(trimmed);
        }

        System.out.println("Initialized schema + indexes in DB: " + dbName);

    } catch (Exception e) {
        throw new RuntimeException(
                "Schema initialization failed in DB [" + dbName + "]: " + e.getMessage(), e);
    }
}


    private void createDefaultBusinessRow(String dbName, String name, Long phone, String email) {
        String tenantDbUrl = masterDbProps.getFirstUrl() + dbName + masterDbProps.getLastUrl();
        String dbUsername = masterDbProps.getUsername();
        String dbPassword = masterDbProps.getPassword();

        String sql = """
            INSERT INTO business
                (id, name, phone_no, email, gst_number, fssai_no, address, gst_type, licence_no, table_count, logo_url)
            VALUES
                (1, ?, ?, ?, '', '', '', 0, '', 0,
                 'https://res.cloudinary.com/drmfryblr/image/upload/v1766157548/grtlfwdybe8b5tmin9h4.png')
            ON CONFLICT (id) DO NOTHING;
        """;

        try (Connection conn = DriverManager.getConnection(tenantDbUrl, dbUsername, dbPassword)) {
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, name);
            pstmt.setLong(2, phone);
            pstmt.setString(3, email);
            pstmt.executeUpdate();

            System.out.println("Inserted default business row into: " + dbName);
        } catch (Exception e) {
            throw new RuntimeException("Failed inserting default business row in DB [" + dbName + "]: " + e.getMessage(), e);
        }
    }
}

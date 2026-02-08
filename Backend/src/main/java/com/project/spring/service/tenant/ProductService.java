package com.project.spring.service.tenant;

import com.project.spring.config.TenantContext;
import com.project.spring.exception.ResourceNotFoundException;
import com.project.spring.model.tenant.Product;
import com.project.spring.repo.tenant.OrderItemRepository;
import com.project.spring.repo.tenant.ProductRepository;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;

import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ProductService {

    private final ProductRepository productRepository;
    private final OrderItemRepository orderItemRepository;

    /* ================= CREATE ================= */

    @CacheEvict(
        value = {"products", "product"},
        key = "T(com.project.spring.config.TenantContext).getCurrentTenant()"
    )
    public Product createProduct(Product product) {
        return productRepository.save(product);
    }

    @CacheEvict(
        value = {"products", "product"},
        key = "T(com.project.spring.config.TenantContext).getCurrentTenant()"
    )
    public List<Product> createProduct(List<Product> products) {
        return productRepository.saveAll(products);
    }

    /* ================= READ ================= */

    @Cacheable(
        value = "products",
        key = "T(com.project.spring.config.TenantContext).getCurrentTenant()"
    )
    public List<Product> getAllProducts() {
        System.out.println(
            ">>> DB HIT: getAllProducts | tenant = " +
            TenantContext.getCurrentTenant()
        );
        return productRepository.findAll();
    }

    @Cacheable(
        value = "product",
        key = "T(com.project.spring.config.TenantContext).getCurrentTenant() + '::' + #productId"
    )
    public Product getProductById(Long productId) {
        System.out.println(
            ">>> DB HIT: getProductById " + productId +
            " | tenant = " + TenantContext.getCurrentTenant()
        );
        return productRepository.findById(productId)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                            "Product not found with ID: " + productId
                        ));
    }

    /* ================= UPDATE ================= */

    @CacheEvict(
        value = {"products", "product"},
        key = "T(com.project.spring.config.TenantContext).getCurrentTenant()"
    )
    public Product updateProduct(Long productId, Product product) {

        Product existing = getProductById(productId);
        existing.setName(product.getName());
        existing.setPrice(product.getPrice());
        existing.setDescription(product.getDescription());

        return productRepository.save(existing);
    }

    /* ================= DELETE ================= */

    @CacheEvict(
        value = {"products", "product"},
        key = "T(com.project.spring.config.TenantContext).getCurrentTenant()"
    )
    public void deleteProduct(Long productId) {
        productRepository.deleteById(productId);
    }

    /* ================= IMAGE PROCESS ================= */

    public List<Product> processProductsFromImage(MultipartFile file) throws Exception {

        File tempFile = File.createTempFile("upload-", ".jpg");
        file.transferTo(tempFile);

        ProcessBuilder pb = new ProcessBuilder(
                "python", "main.py", tempFile.getAbsolutePath()
        );
        pb.directory(new File(System.getProperty("user.dir") + "/python"));
        pb.redirectErrorStream(true);

        Process process = pb.start();

        StringBuilder outputBuilder = new StringBuilder();
        try (BufferedReader reader =
                     new BufferedReader(new InputStreamReader(process.getInputStream()))) {

            String line;
            while ((line = reader.readLine()) != null) {
                outputBuilder.append(line);
            }
        }

        if (process.waitFor() != 0) {
            throw new RuntimeException("Python script failed");
        }

        ObjectMapper mapper = new ObjectMapper();
        List<Product> products = mapper.readValue(
                outputBuilder.toString(),
                new TypeReference<List<Product>>() {}
        );

        tempFile.delete();
        return products;
    }

    /* ================= CSV PROCESS ================= */

    @Transactional
    @CacheEvict(
        value = {"products", "product"},
        key = "T(com.project.spring.config.TenantContext).getCurrentTenant()"
    )
    public List<Product> processProductsFromCsv(MultipartFile file) throws Exception {

        File tempFile = File.createTempFile("upload-", ".xlsx");
        file.transferTo(tempFile);

        ProcessBuilder pb = new ProcessBuilder(
                "python", "main2.py", tempFile.getAbsolutePath()
        );
        pb.directory(new File(System.getProperty("user.dir") + "/python"));
        pb.redirectErrorStream(true);

        Process process = pb.start();

        StringBuilder outputBuilder = new StringBuilder();
        try (BufferedReader reader =
                     new BufferedReader(new InputStreamReader(process.getInputStream()))) {

            String line;
            while ((line = reader.readLine()) != null) {
                outputBuilder.append(line);
            }
        }

        if (process.waitFor() != 0) {
            throw new RuntimeException("Python script failed");
        }

        ObjectMapper mapper = new ObjectMapper();
        List<Product> products = mapper.readValue(
                outputBuilder.toString(),
                new TypeReference<List<Product>>() {}
        );

        // SAFE: only current tenant DB
        orderItemRepository.deleteAllInBatch();
        productRepository.deleteAllInBatch();

        List<Product> savedProducts = productRepository.saveAll(products);
        tempFile.delete();

        return savedProducts;
    }
}

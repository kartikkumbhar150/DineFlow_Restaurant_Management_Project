package com.project.spring.service.tenant;

import com.project.spring.model.tenant.Product;
import com.project.spring.repo.tenant.OrderItemRepository;
import com.project.spring.repo.tenant.ProductRepository;

import jakarta.transaction.Transactional;

import com.project.spring.exception.ResourceNotFoundException;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.type.TypeReference;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
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

    @Autowired
    private ProductRepository productRepository;
    @Autowired 
    private OrderItemRepository orderItemRepository;

    @CacheEvict(value = {"products", "product"}, allEntries = true)
    public Product createProduct(Product product) {
        return productRepository.save(product);
    }


    @Cacheable(value = "products")
    public List<Product> getAllProducts() {
        System.out.println(">>> DB HIT: getAllProducts");
        return productRepository.findAll();
    }


    @Cacheable(value = "product", key = "#productId")
    public Product getProductById(Long productId) {
        System.out.println(">>> DB HIT: getProductById " + productId);
        return productRepository.findById(productId)
                .orElseThrow(() ->
                    new ResourceNotFoundException("Product not found with ID: " + productId));
    }


    @CacheEvict(value = {"products", "product"}, allEntries = true)
public Product updateProduct(Long productId, Product product) {
    Product existing = getProductById(productId);
    existing.setName(product.getName());
    existing.setPrice(product.getPrice());
    existing.setDescription(product.getDescription());
    return productRepository.save(existing);
}

    @CacheEvict(value = {"products", "product"}, allEntries = true)
    public void deleteProduct(Long productId) {
        productRepository.deleteById(productId);
    }

    @CacheEvict(value = {"products", "product"}, allEntries = true)
    public List<Product> createProduct(List<Product> products) {
        return productRepository.saveAll(products);
    }
    


    public List<Product> processProductsFromImage(MultipartFile file) throws Exception {
        // Save uploaded image temporarily
        File tempFile = File.createTempFile("upload-", ".jpg");
        file.transferTo(tempFile);
    
        // Run Python script
        ProcessBuilder pb = new ProcessBuilder(
                "python", "main.py", tempFile.getAbsolutePath()
        );
        pb.directory(new File(System.getProperty("user.dir") + "/python"));

        pb.redirectErrorStream(true);
    
        Process process = pb.start();
    
        StringBuilder outputBuilder = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                outputBuilder.append(line);
            }
        }
    
        int exitCode = process.waitFor();
        if (exitCode != 0) {
            throw new RuntimeException("Python script failed: " + outputBuilder);
        }
    
        // Parse JSON into Product list
        ObjectMapper mapper = new ObjectMapper();
        List<Product> products = mapper.readValue(outputBuilder.toString(), new TypeReference<List<Product>>() {});
    
        tempFile.delete();
    
        return products; // Return without saving
    }
    @Transactional
    @CacheEvict(value = {"products", "product"}, allEntries = true)
    public List<Product> processProductsFromCsv(MultipartFile file) throws Exception {
        File tempFile = File.createTempFile("upload-", ".xlsx");
        file.transferTo(tempFile);

        ProcessBuilder pb = new ProcessBuilder("python", "main2.py", tempFile.getAbsolutePath());
        pb.directory(new File(System.getProperty("user.dir") + "/python"));
        pb.redirectErrorStream(true);

        Process process = pb.start();
        StringBuilder outputBuilder = new StringBuilder();

        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) outputBuilder.append(line);
        }

        int exitCode = process.waitFor();
        if (exitCode != 0) throw new RuntimeException("Python script failed: " + outputBuilder);

        ObjectMapper mapper = new ObjectMapper();
        List<Product> products = mapper.readValue(outputBuilder.toString(), new TypeReference<List<Product>>() {});

        // Delete dependent entities first
        orderItemRepository.deleteAllInBatch();
        productRepository.deleteAllInBatch();

        // Save fresh data
        List<Product> savedProducts = productRepository.saveAll(products);

        tempFile.delete();
        return savedProducts;
    }

    
}

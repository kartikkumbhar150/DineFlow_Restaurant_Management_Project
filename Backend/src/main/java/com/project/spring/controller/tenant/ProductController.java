package com.project.spring.controller.tenant;

import com.project.spring.dto.ApiResponse;
import com.project.spring.model.tenant.Product;
import com.project.spring.service.tenant.ProductService;

import lombok.RequiredArgsConstructor;

import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import java.io.ByteArrayOutputStream;

import java.util.List;

@RestController
@RequestMapping("/api/v1/products")
@RequiredArgsConstructor
public class ProductController {

    private final ProductService productService;

    @PostMapping
    public ResponseEntity<ApiResponse<Product>> createProduct(@RequestBody Product product) {
        try {
            Product savedProduct = productService.createProduct(product);
            return ResponseEntity.ok(
                new ApiResponse<>("success", "Product created successfully", savedProduct)
            );
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Failed to create product: " + e.getMessage(), null)
            );
        }
    }
    @PostMapping("/bulk")
    public ResponseEntity<ApiResponse<List<Product>>> createProduct(@RequestBody List<Product> products) {
        try {
            List<Product> savedProducts = productService.createProduct(products);
            return ResponseEntity.ok(
                new ApiResponse<>("success", "Products created successfully", savedProducts)
            );
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Failed to create products: " + e.getMessage(), null)
            );
        }
    }
    @PostMapping(value = "/bulk/upload", consumes = "multipart/form-data")
    public ResponseEntity<?> uploadMenu(@RequestParam("file") MultipartFile file) {
        try {
            List<Product> products = productService.processProductsFromImage(file);
            return ResponseEntity.ok(new ApiResponse<>("success", "Products fetched successfully", products));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("failure", "Error: " + e.getMessage(), null));
        }
    }
    @PostMapping("/bulk/save")
    public ResponseEntity<ApiResponse<List<Product>>> saveProducts(@RequestBody List<Product> products) {
        try {
            List<Product> savedProducts = productService.createProduct(products);
            return ResponseEntity.ok(
                    new ApiResponse<>("success", "Products saved successfully", savedProducts)
            );
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                    new ApiResponse<>("failure", "Failed to save products: " + e.getMessage(), null)
            );
        }
    }



    

    @GetMapping("/{productId}")
    public ResponseEntity<ApiResponse<Product>> getProductById(@PathVariable Long productId) {
        try {
            Product product = productService.getProductById(productId);
            if (product != null) {
                return ResponseEntity.ok(
                    new ApiResponse<>("success", "Product found", product)
                );
            } else {
                return ResponseEntity.status(404).body(
                    new ApiResponse<>("failure", "Product not found", null)
                );
            }
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Error fetching product: " + e.getMessage(), null)
            );
        }
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<Product>>> getAllProducts() {
        try {
            List<Product> products = productService.getAllProducts();
            return ResponseEntity.ok(
                new ApiResponse<>("success", "All products fetched successfully", products)
            );
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Failed to fetch products: " + e.getMessage(), null)
            );
        }
    }
    @PostMapping(value = "/bulk/upload/csv", consumes = "multipart/form-data")
public ResponseEntity<?> uploadCsv(@RequestParam("file") MultipartFile file) {
    try {
        List<Product> products = productService.processProductsFromCsv(file);
        return ResponseEntity.ok(
            new ApiResponse<>("success", "Products replaced and uploaded successfully", products)
        );
    } catch (Exception e) {
        e.printStackTrace();
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ApiResponse<>("failure", "Error processing file: " + e.getMessage(), null));
    }
}



    @PutMapping("/{productId}")
    public ResponseEntity<ApiResponse<Product>> updateProduct(@PathVariable Long productId, @RequestBody Product product) {
        try {
            Product updatedProduct = productService.updateProduct(productId, product);
            return ResponseEntity.ok(
                new ApiResponse<>("success", "Product updated successfully", updatedProduct)
            );
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Failed to update product: " + e.getMessage(), null)
            );
        }
    }

    @DeleteMapping("/{productId}")
    public ResponseEntity<ApiResponse<Void>> deleteProduct(@PathVariable Long productId) {
        try {
            productService.deleteProduct(productId);
            return ResponseEntity.ok(
                new ApiResponse<>("success", "Product deleted successfully", null)
            );
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Failed to delete product: " + e.getMessage(), null)
            );
        }
    }

    // excel file ka hai ye 

    @GetMapping("/export/xlsx")
public ResponseEntity<byte[]> exportProductsToExcel() {
    try (Workbook workbook = new XSSFWorkbook()) {
        Sheet sheet = workbook.createSheet("Products");

        // Header row
        Row header = sheet.createRow(0);
        header.createCell(0).setCellValue("item");
        header.createCell(1).setCellValue("price");
        header.createCell(2).setCellValue("category");

        // Fetch products
        List<Product> products = productService.getAllProducts();

        int rowIdx = 1;
        for (Product product : products) {
            Row row = sheet.createRow(rowIdx++);
            row.createCell(0).setCellValue(product.getName());        // adjust if your field is different
            row.createCell(1).setCellValue(product.getPrice());
            row.createCell(2).setCellValue(product.getCategory());
        }

        // Write to byte array
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        workbook.write(out);

        return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=products.xlsx")
                .header("Content-Type",
                        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
                .body(out.toByteArray());

    } catch (Exception e) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(null);
    }
}

}

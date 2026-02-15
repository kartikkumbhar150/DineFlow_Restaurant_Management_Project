package com.project.spring.controller.tenant;

import com.project.spring.dto.ApiResponse;
import com.project.spring.model.tenant.Product;
import com.project.spring.service.tenant.ProductService;

import lombok.RequiredArgsConstructor;

import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayOutputStream;
import java.util.List;

@RestController
@RequestMapping("/api/v1/products")
@RequiredArgsConstructor
public class ProductController {

    private final ProductService productService;

    @PostMapping
    public ResponseEntity<ApiResponse<Product>> createProduct(@RequestBody Product product) {
        Product saved = productService.createProduct(product);
        return ResponseEntity.ok(
                new ApiResponse<>("success", "Product created successfully", saved)
        );
    }

    @PostMapping("/bulk/save")
    public ResponseEntity<ApiResponse<List<Product>>> createProduct(@RequestBody List<Product> products) {
        List<Product> saved = productService.createProduct(products);
        return ResponseEntity.ok(
                new ApiResponse<>("success", "Products created successfully", saved)
        );
    }

    @PostMapping(value = "/bulk/upload", consumes = "multipart/form-data")
    public ResponseEntity<?> uploadMenu(@RequestParam("file") MultipartFile file) throws Exception {
        return ResponseEntity.ok(
                new ApiResponse<>("success",
                        "Products fetched successfully",
                        productService.processProductsFromImage(file))
        );
    }

    @PostMapping(value = "/bulk/upload/csv", consumes = "multipart/form-data")
    public ResponseEntity<?> uploadCsv(@RequestParam("file") MultipartFile file) throws Exception {
        return ResponseEntity.ok(
                new ApiResponse<>("success",
                        "Products replaced and uploaded successfully",
                        productService.processProductsFromCsv(file))
        );
    }

    @GetMapping("/{productId}")
    public ResponseEntity<ApiResponse<Product>> getProductById(@PathVariable Long productId) {
        return ResponseEntity.ok(
                new ApiResponse<>("success",
                        "Product found",
                        productService.getProductById(productId))
        );
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<Product>>> getAllProducts() {
        return ResponseEntity.ok(
                new ApiResponse<>("success",
                        "All products fetched successfully",
                        productService.getAllProducts())
        );
    }

    @PutMapping("/{productId}")
    public ResponseEntity<ApiResponse<Product>> updateProduct(
            @PathVariable Long productId,
            @RequestBody Product product
    ) {
        return ResponseEntity.ok(
                new ApiResponse<>("success",
                        "Product updated successfully",
                        productService.updateProduct(productId, product))
        );
    }

    @DeleteMapping("/{productId}")
    public ResponseEntity<ApiResponse<Void>> deleteProduct(@PathVariable Long productId) {
        productService.deleteProduct(productId);
        return ResponseEntity.ok(
                new ApiResponse<>("success", "Product deleted successfully", null)
        );
    }

    /* ---------------- EXPORT EXCEL ---------------- */

    @GetMapping("/export/xlsx")
    public ResponseEntity<byte[]> exportProductsToExcel() throws Exception {

        try (Workbook workbook = new XSSFWorkbook()) {
            Sheet sheet = workbook.createSheet("Products");

            Row header = sheet.createRow(0);
            header.createCell(0).setCellValue("item");
            header.createCell(1).setCellValue("price");
            header.createCell(2).setCellValue("category");

            List<Product> products = productService.getAllProducts();

            int rowIdx = 1;
            for (Product product : products) {
                Row row = sheet.createRow(rowIdx++);
                row.createCell(0).setCellValue(product.getName());
                row.createCell(1).setCellValue(product.getPrice());
                row.createCell(2).setCellValue(product.getCategory());
            }

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            workbook.write(out);

            return ResponseEntity.ok()
                    .header("Content-Disposition", "attachment; filename=products.xlsx")
                    .header("Content-Type",
                            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
                    .body(out.toByteArray());
        }
    }
}

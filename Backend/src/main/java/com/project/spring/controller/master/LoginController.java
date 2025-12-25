package com.project.spring.controller.master;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.project.spring.dto.ApiResponse;
import com.project.spring.model.master.StaffUser;
import com.project.spring.service.master.StaffUserService;

@RestController
@RequestMapping("/api/v1/auth")
public class LoginController {

    private final StaffUserService staffUserService;

    public LoginController(StaffUserService staffUserService) {
        this.staffUserService = staffUserService;
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<String>> login(@RequestBody StaffUser user) {
        try {

            // 🔐 authenticate + ALWAYS generate a NEW JWT
            String token = staffUserService.verify(user);

            if ("fail".equalsIgnoreCase(token)) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(new ApiResponse<>("failure", "Invalid username or password", null));
            }

            return ResponseEntity.ok(
                    new ApiResponse<>("success", "Login successful", token)
            );

        } catch (Exception ex) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("failure",
                            "Login failed: " + ex.getMessage(), null));
        }
    }

    /**
     * Optional logout endpoint (frontend still MUST delete the token).
     * Implement token blacklist here only if needed.
     */
    @PostMapping("/logout")
public ResponseEntity<ApiResponse<Void>> logout(
        @RequestHeader(name = "Authorization") String authHeader) {

    try {
        // extract token from header
        String token = authHeader.replace("Bearer ", "").trim();

        // 1️⃣ delete token from DB
        staffUserService.clearToken(token);

        // 2️⃣ blacklist token (until it expires)
        staffUserService.blacklistToken(token);

        return ResponseEntity.ok(
                new ApiResponse<>("success", "Logged out", null)
        );

    } catch (Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ApiResponse<>("failure",
                        "Logout failed: " + ex.getMessage(), null));
    }
}

}

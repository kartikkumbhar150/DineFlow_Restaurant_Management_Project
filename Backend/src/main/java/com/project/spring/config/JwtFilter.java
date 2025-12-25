package com.project.spring.config;

import com.project.spring.model.master.StaffUser;
import com.project.spring.repo.master.StaffUserRepository;
import com.project.spring.service.master.JWTService;
import com.project.spring.service.master.MyStaffUserDetailsService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.data.redis.core.RedisTemplate;

import java.io.IOException;

@Component
public class JwtFilter extends OncePerRequestFilter {

    @Autowired
    private JWTService jwtService;

    @Autowired
    private MyStaffUserDetailsService userDetailsService;

    @Autowired
    private StaffUserRepository staffUserRepository;

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;   // 👈 added

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getServletPath();
        return path.startsWith("/api/v1/auth/")
                || "OPTIONS".equalsIgnoreCase(request.getMethod());
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        try {
            String authHeader = request.getHeader("Authorization");

            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                sendUnauthorized(response, "Missing or invalid Authorization header");
                return;
            }

            String token = authHeader.substring(7);

            // 🚫 1️⃣ BLOCK BLACKLISTED TOKENS
            if (Boolean.TRUE.equals(redisTemplate.hasKey("blacklist:" + token))) {
                sendUnauthorized(response, "Token is blacklisted");
                return;
            }

            String username = jwtService.extractUserName(token);
            String dbName = jwtService.extractdbName(token);

            if (dbName != null) {
                TenantContext.setCurrentTenant(dbName);
            } else {
                TenantContext.setCurrentTenant("master");
            }

            if (username != null &&
                    SecurityContextHolder.getContext().getAuthentication() == null) {

                StaffUser dbUser = staffUserRepository
                        .findByUserName(username)
                        .orElse(null);

                if (dbUser == null ||
                        !jwtService.isTokenValidForUser(token, dbUser)) {
                    sendUnauthorized(response, "Invalid or expired token");
                    return;
                }

                UserDetails userDetails =
                        userDetailsService.loadUserByUsername(username);

                UsernamePasswordAuthenticationToken authToken =
                        new UsernamePasswordAuthenticationToken(
                                userDetails, null, userDetails.getAuthorities());

                authToken.setDetails(
                        new WebAuthenticationDetailsSource().buildDetails(request));

                SecurityContextHolder.getContext().setAuthentication(authToken);
            }

            filterChain.doFilter(request, response);

        } finally {
            TenantContext.clear();
        }
    }

    private void sendUnauthorized(HttpServletResponse response, String message)
            throws IOException {

        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");

        response.getWriter().write("""
            {
              "status": "error",
              "message": "%s"
            }
            """.formatted(message));
    }
}

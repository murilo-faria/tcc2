package br.com.adminpool.config;

import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

@Configuration
public class SecurityConfig {
    @Bean
    UserDetailsService users(@Value("${APP_GESTOR_PASSWORD}") String gestor,
                            @Value("${APP_FUNCIONARIO_PASSWORD}") String funcionario) {
        if (gestor.length() < 10 || funcionario.length() < 10) {
            throw new IllegalArgumentException("Configure senhas de acesso com pelo menos 10 caracteres.");
        }
        var encoder = new BCryptPasswordEncoder();
        return new InMemoryUserDetailsManager(
            User.withUsername("gestorMurilo").password("{bcrypt}" + encoder.encode(gestor)).roles("GESTOR").build(),
            User.withUsername("funcionario1").password("{bcrypt}" + encoder.encode(funcionario)).roles("FUNCIONARIO").build());
    }

    @Bean
    SecurityFilterChain security(HttpSecurity http) throws Exception {
        // Credentials are sent explicitly by the app, never stored in cookies.
        // The non-simple header is mandatory, preventing browser-form CSRF.
        return http.cors(cors -> {}).csrf(csrf -> csrf.disable())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .requestCache(c -> c.disable())
            .formLogin(f -> f.disable()).logout(l -> l.disable())
            .httpBasic(b -> b.authenticationEntryPoint((req, res, ex) -> res.sendError(401)))
            .exceptionHandling(e -> e.authenticationEntryPoint((req, res, ex) -> res.sendError(401)))
            .authorizeHttpRequests(a -> a
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .requestMatchers(req -> !"AdminPool".equals(req.getHeader("X-Requested-With"))).denyAll()
                .requestMatchers("/api/auth/me").authenticated()
                .requestMatchers("/api/cobrancas/**", "/api/funcionarios/**", "/api/salarios/**").hasRole("GESTOR")
                .requestMatchers(HttpMethod.DELETE, "/api/**").hasRole("GESTOR")
                .requestMatchers(HttpMethod.POST, "/api/clientes/**", "/api/produtos/**").hasRole("GESTOR")
                .requestMatchers(HttpMethod.PUT, "/api/clientes/**", "/api/produtos/**").hasRole("GESTOR")
                .requestMatchers("/api/**").authenticated()
                .anyRequest().denyAll())
            .build();
    }

    @Bean
    UrlBasedCorsConfigurationSource corsConfigurationSource(
            @Value("${APP_ALLOWED_ORIGINS:https://tibumlimpezapiscinas.com.br,https://www.tibumlimpezapiscinas.com.br,https://tcc2-delta.vercel.app}") String origins) {
        var cors = new CorsConfiguration();
        cors.setAllowedOrigins(List.of(origins.split(",")));
        cors.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        cors.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-Requested-With"));
        cors.setAllowCredentials(false);
        var source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", cors);
        return source;
    }
}

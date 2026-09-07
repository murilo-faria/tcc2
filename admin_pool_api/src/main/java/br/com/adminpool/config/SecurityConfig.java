package br.com.adminpool.config;

import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import br.com.adminpool.repository.UsuarioRepository;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

@Configuration
public class SecurityConfig {
    @Bean
    PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(); }
    @Bean
    UserDetailsService users(ObjectProvider<UsuarioRepository> provider, @Value("${APP_GESTOR_PASSWORD}") String gestor, @Value("${APP_FUNCIONARIO_PASSWORD}") String funcionario) {
        return login -> {
            var usuarios=provider.getIfAvailable();
            if(usuarios!=null) return usuarios.findByLoginIgnoreCase(login).map(u -> org.springframework.security.core.userdetails.User.withUsername(u.getLogin()).password(u.getSenha()).roles(u.getPerfil().name()).disabled(!u.isAtivo()).build()).orElseThrow(() -> new org.springframework.security.core.userdetails.UsernameNotFoundException(login));
            String senha = login.equals("gestorMurilo") ? gestor : login.equals("funcionario1") ? funcionario : null;
            if(senha==null) throw new org.springframework.security.core.userdetails.UsernameNotFoundException(login);
            String papel=login.equals("gestorMurilo")?"GESTOR":"FUNCIONARIO";
            return org.springframework.security.core.userdetails.User.withUsername(login).password(passwordEncoder().encode(senha)).roles(papel).build();
        };
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
                .requestMatchers("/api/piscinas/**", "/api/salarios/**", "/api/funcionarios/**").authenticated()
                .requestMatchers("/api/cobrancas/**", "/api/funcionarios/**").hasRole("GESTOR")
                .requestMatchers(HttpMethod.DELETE, "/api/**").hasRole("GESTOR")
                .requestMatchers(HttpMethod.POST, "/api/clientes/**", "/api/produtos/**", "/api/piscinas/**").hasRole("GESTOR")
                .requestMatchers(HttpMethod.PUT, "/api/clientes/**", "/api/produtos/**", "/api/piscinas/**").hasRole("GESTOR")
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

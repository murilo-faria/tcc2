package br.com.adminpool.controller;

import java.util.Map;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AuthController {
    @GetMapping("/api/auth/me")
    public Map<String, String> me(Authentication auth) {
        String perfil = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_GESTOR"))
            ? "gestor" : "funcionario";
        return Map.of("usuario", auth.getName(), "perfil", perfil);
    }
}

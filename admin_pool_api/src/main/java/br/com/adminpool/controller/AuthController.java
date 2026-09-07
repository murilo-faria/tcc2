package br.com.adminpool.controller;

import java.util.Map;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import br.com.adminpool.repository.UsuarioRepository;

@RestController
public class AuthController {
    private final UsuarioRepository usuarios;
    public AuthController(UsuarioRepository usuarios) { this.usuarios = usuarios; }
    @GetMapping("/api/auth/me")
    public Map<String, String> me(Authentication auth) {
        String perfil = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_GESTOR"))
            ? "gestor" : "funcionario";
        String nome = usuarios.findByLoginIgnoreCase(auth.getName()).map(u -> u.getNome()).orElse(auth.getName());
        return Map.of("usuario", auth.getName(), "nome", nome, "perfil", perfil);
    }
}

package br.com.adminpool.config;

import br.com.adminpool.controller.AuthController;
import br.com.adminpool.repository.UsuarioRepository;
import br.com.adminpool.model.Usuario;
import br.com.adminpool.model.Perfil;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;
import java.util.Base64;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.mockito.Mockito.when;
import java.util.Optional;

@WebMvcTest(controllers=AuthController.class, properties={
    "APP_GESTOR_PASSWORD=test-gestor-password-123", "APP_FUNCIONARIO_PASSWORD=test-worker-password-123"
})
@Import(SecurityConfig.class)
class SecurityConfigTest {
    @Autowired MockMvc mvc;
    @MockBean UsuarioRepository usuarios;
    @org.junit.jupiter.api.BeforeEach void preparaUsuarios() {
        when(usuarios.findByLoginIgnoreCase(org.mockito.ArgumentMatchers.anyString())).thenAnswer(invocacao -> {
            String login = invocacao.getArgument(0);
            if (!login.equals("gestorMurilo") && !login.equals("funcionario1")) return Optional.empty();
            Usuario usuario = new Usuario();
            usuario.setLogin(login);
            usuario.setNome(login);
            usuario.setSenha(new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder().encode(
                    login.equals("gestorMurilo") ? "test-gestor-password-123" : "test-worker-password-123"));
            usuario.setPerfil(login.equals("gestorMurilo") ? Perfil.GESTOR : Perfil.FUNCIONARIO);
            return Optional.of(usuario);
        });
    }
    String basic(String user, String password) {
        return "Basic " + Base64.getEncoder().encodeToString((user+":"+password).getBytes(java.nio.charset.StandardCharsets.UTF_8));
    }
    @Test void anonymousCannotReadData() throws Exception {
        mvc.perform(get("/api/clientes").header("X-Requested-With","AdminPool")).andExpect(status().isUnauthorized());
    }
    @Test void wrongPasswordFails() throws Exception {
        mvc.perform(get("/api/auth/me").header("X-Requested-With","AdminPool")
            .header("Authorization",basic("gestorMurilo","1234"))).andExpect(status().isUnauthorized());
    }
    @Test void managerRoleComesFromServer() throws Exception {
        mvc.perform(get("/api/auth/me").header("X-Requested-With","AdminPool")
            .header("Authorization",basic("gestorMurilo","test-gestor-password-123")))
            .andExpect(status().isOk()).andExpect(jsonPath("$.perfil").value("gestor"));
    }
    @Test void employeeCannotDeleteClientsOrReadBilling() throws Exception {
        String auth=basic("funcionario1","test-worker-password-123");
        mvc.perform(delete("/api/clientes/1").header("X-Requested-With","AdminPool").header("Authorization",auth))
            .andExpect(status().isForbidden());
        mvc.perform(get("/api/cobrancas").header("X-Requested-With","AdminPool").header("Authorization",auth))
            .andExpect(status().isForbidden());
    }
    @Test void simpleBrowserRequestsCannotUseCredentials() throws Exception {
        mvc.perform(post("/api/clientes").header("Authorization",basic("gestorMurilo","test-gestor-password-123")))
            .andExpect(status().isForbidden());
    }
    @Test void corsAllowsSiteAndRejectsOtherOrigins() throws Exception {
        mvc.perform(options("/api/clientes").header("Origin","https://tibumlimpezapiscinas.com.br")
            .header("Access-Control-Request-Method","GET").header("Access-Control-Request-Headers","authorization,x-requested-with"))
            .andExpect(status().isOk()).andExpect(header().string("Access-Control-Allow-Origin","https://tibumlimpezapiscinas.com.br"));
        mvc.perform(options("/api/clientes").header("Origin","https://untrusted.example")
            .header("Access-Control-Request-Method","GET")).andExpect(status().isForbidden());
    }
}

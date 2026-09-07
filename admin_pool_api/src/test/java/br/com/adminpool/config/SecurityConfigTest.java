package br.com.adminpool.config;

import br.com.adminpool.controller.AuthController;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;
import java.util.Base64;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(controllers=AuthController.class, properties={
    "APP_GESTOR_PASSWORD=test-gestor-password-123", "APP_FUNCIONARIO_PASSWORD=test-worker-password-123"
})
@Import(SecurityConfig.class)
class SecurityConfigTest {
    @Autowired MockMvc mvc;
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

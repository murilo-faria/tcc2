package br.com.adminpool.service;

import br.com.adminpool.model.RegistroAuditoria;
import br.com.adminpool.repository.RegistroAuditoriaRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

@Service
public class AuditoriaService {
    private final RegistroAuditoriaRepository registros;
    private final ObjectMapper json;

    public AuditoriaService(RegistroAuditoriaRepository registros, ObjectMapper json) {
        this.registros = registros;
        this.json = json;
    }

    /**
     * Persiste somente operações concluídas. Senhas e credenciais jamais entram no histórico.
     */
    public void registrar(Authentication autenticacao, String acao, String recurso,
                          Object[] argumentos, Object retorno) {
        if (autenticacao == null || !autenticacao.isAuthenticated()) return;
        RegistroAuditoria registro = new RegistroAuditoria();
        registro.setUsuarioLogin(autenticacao.getName());
        registro.setAcao(acao);
        registro.setRecurso(limitar(recurso, 500));
        registro.setModulo(modulo(recurso));
        registro.setDadosInformados(limitar(serializar(argumentos), 4000));
        registro.setResultado(limitar(resumo(retorno), 1000));
        registros.save(registro);
    }

    private String modulo(String recurso) {
        String[] partes = recurso.split("/");
        return partes.length > 2 ? partes[2] : "sistema";
    }

    private String serializar(Object[] argumentos) {
        Map<String, Object> dados = new LinkedHashMap<>();
        int indice = 1;
        for (Object argumento : Arrays.asList(argumentos)) {
            if (argumento == null || argumento instanceof Authentication
                    || argumento instanceof jakarta.servlet.ServletRequest
                    || argumento instanceof jakarta.servlet.ServletResponse) continue;
            dados.put("argumento" + indice++, ocultarSegredos(json.valueToTree(argumento)));
        }
        try { return json.writeValueAsString(dados); }
        catch (JsonProcessingException excecao) { return "Dados da alteração não puderam ser serializados."; }
    }

    private JsonNode ocultarSegredos(JsonNode valor) {
        if (valor instanceof ObjectNode objeto) {
            objeto.fields().forEachRemaining(campo -> {
                String nome = campo.getKey().toLowerCase();
                if (nome.contains("senha") || nome.contains("password")) {
                    objeto.put(campo.getKey(), "[PROTEGIDO]");
                } else {
                    ocultarSegredos(campo.getValue());
                }
            });
        } else if (valor.isArray()) {
            valor.forEach(this::ocultarSegredos);
        }
        return valor;
    }

    private String resumo(Object retorno) {
        if (retorno == null) return "Operação concluída.";
        return retorno.getClass().getSimpleName();
    }

    private String limitar(String texto, int tamanho) {
        if (texto == null) return null;
        return texto.length() <= tamanho ? texto : texto.substring(0, tamanho - 3) + "...";
    }
}

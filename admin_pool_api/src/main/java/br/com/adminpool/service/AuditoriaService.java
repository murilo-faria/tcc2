package br.com.adminpool.service;

import br.com.adminpool.model.RegistroAuditoria;
import br.com.adminpool.model.ItemCobranca;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.ItemCobrancaRepository;
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
    private final ItemCobrancaRepository itensCobranca;
    private final ClienteRepository clientes;
    private final ObjectMapper json;

    public AuditoriaService(RegistroAuditoriaRepository registros,
                            ItemCobrancaRepository itensCobranca,
                            ClienteRepository clientes,
                            ObjectMapper json) {
        this.registros = registros;
        this.itensCobranca = itensCobranca;
        this.clientes = clientes;
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
        registro.setDescricao(limitar(descricao(acao, recurso), 500));
        registro.setDadosInformados(limitar(serializar(argumentos), 4000));
        registro.setResultado(limitar(resumo(retorno), 1000));
        registros.save(registro);
    }

    /**
     * Mantém a tela de auditoria compreensível sem retirar o registro técnico
     * disponível nos detalhes. Cobranças são tratadas explicitamente porque a
     * identificação do cliente e do lançamento é essencial para conferência.
     */
    private String descricao(String acao, String recurso) {
        String verbo = switch (acao) {
            case "POST" -> "Criou";
            case "PUT", "PATCH" -> "Alterou";
            case "DELETE" -> "Excluiu";
            default -> "Realizou alteração em";
        };
        if (!recurso.startsWith("/api/cobrancas/")) return verbo + " em " + nomeModulo(modulo(recurso));

        String[] partes = recurso.split("/");
        Long itemId = idApos(partes, "itens");
        if (itemId != null) {
            ItemCobranca item = itensCobranca.findById(itemId).orElse(null);
            if (item != null) {
                String cliente = item.getCobranca().getCliente().getNome();
                String lancamento = item.getDescricao();
                if (recurso.endsWith("/baixar")) return "Deu baixa em " + lancamento + " de " + cliente;
                if (recurso.endsWith("/estornar-baixa")) return "Estornou baixa de " + lancamento + " de " + cliente;
                if (recurso.endsWith("/valor")) return "Alterou valor de " + lancamento + " de " + cliente;
                return verbo + " " + lancamento + " de " + cliente;
            }
        }
        Long clienteId = idApos(partes, "clientes");
        if (clienteId != null) {
            String cliente = clientes.findById(clienteId).map(c -> c.getNome()).orElse("cliente removido");
            if (recurso.endsWith("/baixar-total")) return "Deu baixa total nas cobranças de " + cliente;
            if (recurso.endsWith("/baixar-parcial")) return "Deu baixa parcial nas cobranças de " + cliente;
            return verbo + " cobranças de " + cliente;
        }
        if (recurso.endsWith("/baixar")) return "Deu baixa em cobranças selecionadas";
        if (recurso.endsWith("/baixar-total")) return "Deu baixa total em cobranças selecionadas";
        return verbo + " em cobranças";
    }

    private Long idApos(String[] partes, String marcador) {
        for (int i = 0; i + 1 < partes.length; i++) {
            if (!marcador.equals(partes[i])) continue;
            try { return Long.valueOf(partes[i + 1]); }
            catch (NumberFormatException ignored) { return null; }
        }
        return null;
    }

    private String nomeModulo(String modulo) {
        return switch (modulo) {
            case "pedidos-produto" -> "pedidos";
            case "ordens-servico" -> "ordens de serviço";
            case "cloro-emergencial" -> "cloro emergencial";
            default -> modulo;
        };
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

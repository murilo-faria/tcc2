package br.com.adminpool.controller;

import br.com.adminpool.dto.NovaPiscinaRequest;
import br.com.adminpool.dto.AtualizarRotaRequest;
import br.com.adminpool.model.Piscina;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.PiscinaRepository;
import br.com.adminpool.repository.FuncionarioRepository;
import org.springframework.security.core.Authentication;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.DeleteMapping;

import java.util.List;
import java.math.BigDecimal;

@RestController
@RequestMapping("/api/piscinas")

public class PiscinaController {

    private final PiscinaRepository piscinas;
    private final ClienteRepository clientes;
    private final FuncionarioRepository funcionarios;

    public PiscinaController(PiscinaRepository piscinas, ClienteRepository clientes, FuncionarioRepository funcionarios) {
        this.piscinas = piscinas;
        this.clientes = clientes;
        this.funcionarios = funcionarios;
    }

    @GetMapping
    public List<Piscina> listar(Authentication auth) { return gestor(auth) ? piscinas.findAll() : piscinas.findByResponsavelUsuarioLoginIgnoreCaseOrderByNome(auth.getName()); }

    @GetMapping("/cliente/{clienteId}")
    public List<Piscina> listarPorCliente(@PathVariable Long clienteId, Authentication auth) {
        List<Piscina> lista = piscinas.findByClienteIdOrderByNome(clienteId);
        return gestor(auth) ? lista : lista.stream().filter(p -> p.getResponsavel()!=null && p.getResponsavel().getUsuario().getLogin().equalsIgnoreCase(auth.getName())).toList();
    }

    @PostMapping
    public ResponseEntity<Piscina> criar(@RequestBody NovaPiscinaRequest requisicao, Authentication auth) {
        if (!gestor(auth)) throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem cadastrar piscinas.");
        Piscina piscina = new Piscina();
        piscina.setCliente(clientes.findById(requisicao.clienteId()).orElseThrow());
        piscina.setNome(requisicao.nome());
        piscina.setTipo(requisicao.tipo());
        aplicarMedidas(piscina, requisicao, true);
        piscina.setEndereco(requisicao.endereco());
        if(requisicao.responsavelId()!=null) piscina.setResponsavel(funcionarios.findById(requisicao.responsavelId()).orElseThrow());
        piscina.setDiaAtendimento(requisicao.diaAtendimento());
        piscina.setObservacoes(requisicao.observacoes());
        piscina.setValorMensalidade(requisicao.valorMensalidade() == null ? BigDecimal.ZERO : requisicao.valorMensalidade());

        Piscina piscinaSalva = piscinas.save(piscina);
        return ResponseEntity.status(HttpStatus.CREATED).body(piscinaSalva);
    }
    @PutMapping("/{id}")
    public Piscina atualizar(@PathVariable Long id, @RequestBody NovaPiscinaRequest requisicao, Authentication auth) {
        if (!gestor(auth)) throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem editar piscinas.");
        Piscina piscina = piscinas.findById(id).orElseThrow();
        piscina.setCliente(clientes.findById(requisicao.clienteId()).orElseThrow());
        piscina.setNome(requisicao.nome()); piscina.setTipo(requisicao.tipo()); aplicarMedidas(piscina, requisicao, false); piscina.setEndereco(requisicao.endereco()); piscina.setDiaAtendimento(requisicao.diaAtendimento()); piscina.setObservacoes(requisicao.observacoes());
        piscina.setResponsavel(requisicao.responsavelId()==null ? null : funcionarios.findById(requisicao.responsavelId()).orElseThrow());
        piscina.setValorMensalidade(requisicao.valorMensalidade() == null ? piscina.getValorMensalidade() : requisicao.valorMensalidade());
        return piscinas.save(piscina);
    }
    @PutMapping("/{id}/rota")
    public Piscina atualizarRota(@PathVariable Long id, @RequestBody AtualizarRotaRequest requisicao, Authentication auth) {
        Piscina piscina = piscinas.findById(id).orElseThrow();
        boolean responsavel = piscina.getResponsavel() != null && piscina.getResponsavel().getUsuario().getLogin().equalsIgnoreCase(auth.getName());
        if (!gestor(auth) && !responsavel) throw new org.springframework.security.access.AccessDeniedException("Você só pode ajustar a sua própria rota.");
        if (requisicao.diaAtendimento() != null && !List.of("Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado").contains(requisicao.diaAtendimento()))
            throw new IllegalArgumentException("Escolha um dia de segunda a sábado.");
        piscina.setDiaAtendimento(requisicao.diaAtendimento());
        return piscinas.save(piscina);
    }
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id, Authentication auth) { if(!gestor(auth)) throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem excluir piscinas."); piscinas.deleteById(id); return ResponseEntity.noContent().build(); }
    private boolean gestor(Authentication a){return a.getAuthorities().stream().anyMatch(x->x.getAuthority().equals("ROLE_GESTOR"));}
    private BigDecimal medida(BigDecimal valor, String campo) {
        if (valor == null) return null;
        if (valor.compareTo(BigDecimal.ZERO) < 0) throw new IllegalArgumentException("A " + campo + " não pode ser negativa.");
        return valor;
    }
    private void aplicarMedidas(Piscina piscina, NovaPiscinaRequest requisicao, boolean nova) {
        BigDecimal comprimento = medida(requisicao.comprimento(), "comprimento");
        BigDecimal largura = medida(requisicao.largura(), "largura");
        BigDecimal profundidade = medida(requisicao.profundidade(), "profundidade");
        BigDecimal descontoEscada = medida(requisicao.descontoEscada(), "perda da escada");
        piscina.setComprimento(comprimento == null ? (nova ? BigDecimal.ZERO : piscina.getComprimento()) : comprimento);
        piscina.setLargura(largura == null ? (nova ? BigDecimal.ZERO : piscina.getLargura()) : largura);
        piscina.setProfundidade(profundidade == null ? (nova ? new BigDecimal("1.40") : piscina.getProfundidade()) : profundidade);
        piscina.setDescontoEscada(descontoEscada == null ? (nova ? new BigDecimal("15") : piscina.getDescontoEscada()) : descontoEscada);
        if (piscina.getDescontoEscada().compareTo(new BigDecimal("100")) > 0)
            throw new IllegalArgumentException("A perda da escada não pode ultrapassar 100%.");
        piscina.setVolumeLitros(piscina.getLitragemCalculada().intValue());
    }
}

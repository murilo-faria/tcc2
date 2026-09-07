package br.com.adminpool.controller;

import br.com.adminpool.dto.NovaPiscinaRequest;
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
        piscina.setVolumeLitros(requisicao.volumeLitros());
        piscina.setEndereco(requisicao.endereco());
        if(requisicao.responsavelId()!=null) piscina.setResponsavel(funcionarios.findById(requisicao.responsavelId()).orElseThrow());
        piscina.setObservacoes(requisicao.observacoes());

        Piscina piscinaSalva = piscinas.save(piscina);
        return ResponseEntity.status(HttpStatus.CREATED).body(piscinaSalva);
    }
    @PutMapping("/{id}")
    public Piscina atualizar(@PathVariable Long id, @RequestBody NovaPiscinaRequest requisicao, Authentication auth) {
        if (!gestor(auth)) throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem editar piscinas.");
        Piscina piscina = piscinas.findById(id).orElseThrow();
        piscina.setCliente(clientes.findById(requisicao.clienteId()).orElseThrow());
        piscina.setNome(requisicao.nome()); piscina.setTipo(requisicao.tipo()); piscina.setVolumeLitros(requisicao.volumeLitros()); piscina.setEndereco(requisicao.endereco()); piscina.setObservacoes(requisicao.observacoes());
        piscina.setResponsavel(requisicao.responsavelId()==null ? null : funcionarios.findById(requisicao.responsavelId()).orElseThrow());
        return piscinas.save(piscina);
    }
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id, Authentication auth) { if(!gestor(auth)) throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem excluir piscinas."); piscinas.deleteById(id); return ResponseEntity.noContent().build(); }
    private boolean gestor(Authentication a){return a.getAuthorities().stream().anyMatch(x->x.getAuthority().equals("ROLE_GESTOR"));}
}

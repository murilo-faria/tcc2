package br.com.adminpool.controller;

import br.com.adminpool.model.Cliente;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.service.CobrancaService;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import java.time.YearMonth;
import java.util.List;

@RestController
@RequestMapping("/api/clientes")
@CrossOrigin(originPatterns = "http://localhost:*")
public class ClienteController {
    private final ClienteRepository repo;
    private final CobrancaService cobrancas;
    public ClienteController(ClienteRepository repo, CobrancaService cobrancas) { this.repo = repo; this.cobrancas = cobrancas; }

    @GetMapping public List<Cliente> listar() { return repo.findAll(); }

    @PostMapping
    public ResponseEntity<Cliente> criar(@RequestBody Cliente cliente) {
        cliente.setId(null);
        cliente.setAtivo(true);
        Cliente salvo = repo.save(cliente);
        cobrancas.gerar(salvo, YearMonth.now());
        return ResponseEntity.status(HttpStatus.CREATED).body(salvo);
    }

    @PutMapping("/{id}") public Cliente atualizar(@PathVariable Long id, @RequestBody Cliente cliente) { cliente.setId(id); return repo.save(cliente); }
    @DeleteMapping("/{id}") public void excluir(@PathVariable Long id) { repo.deleteById(id); }
}

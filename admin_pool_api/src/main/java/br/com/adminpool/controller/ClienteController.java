package br.com.adminpool.controller;

import br.com.adminpool.model.Cliente;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.service.CobrancaService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.YearMonth;
import java.util.List;

@RestController
@RequestMapping("/api/clientes")

public class ClienteController {

    private final ClienteRepository clientes;
    private final CobrancaService cobrancas;

    public ClienteController(ClienteRepository clientes, CobrancaService cobrancas) {
        this.clientes = clientes;
        this.cobrancas = cobrancas;
    }

    @GetMapping
    public List<Cliente> listar() {
        return clientes.findAll();
    }

    @PostMapping
    public ResponseEntity<Cliente> criar(@RequestBody Cliente cliente) {
        cliente.setId(null);
        cliente.setAtivo(true);

        Cliente clienteSalvo = clientes.save(cliente);
        cobrancas.gerar(clienteSalvo, YearMonth.now());

        return ResponseEntity.status(HttpStatus.CREATED).body(clienteSalvo);
    }

    @PutMapping("/{id}")
    public Cliente atualizar(@PathVariable Long id, @RequestBody Cliente cliente) {
        cliente.setId(id);
        return clientes.save(cliente);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id) {
        clientes.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}

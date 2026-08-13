package br.com.adminpool.controller;

import br.com.adminpool.model.Produto;
import br.com.adminpool.repository.ProdutoRepository;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/produtos")
@CrossOrigin(originPatterns = "http://localhost:*")
public class ProdutoController {
    private final ProdutoRepository repo;
    public ProdutoController(ProdutoRepository repo) { this.repo = repo; }

    @GetMapping public List<Produto> listar() { return repo.findAll(); }
    @PostMapping public ResponseEntity<Produto> criar(@RequestBody Produto p) { return ResponseEntity.status(HttpStatus.CREATED).body(repo.save(p)); }
    @PutMapping("/{id}") public Produto atualizar(@PathVariable Long id, @RequestBody Produto p) { p.setId(id); return repo.save(p); }
    @DeleteMapping("/{id}") public ResponseEntity<Void> excluir(@PathVariable Long id) { repo.deleteById(id); return ResponseEntity.noContent().build(); }
}

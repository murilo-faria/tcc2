package br.com.adminpool.controller;

import br.com.adminpool.model.Produto;
import br.com.adminpool.repository.ProdutoRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Locale;
import java.text.Collator;

@RestController
@RequestMapping("/api/produtos")

public class ProdutoController {

    private final ProdutoRepository produtos;

    public ProdutoController(ProdutoRepository produtos) {
        this.produtos = produtos;
    }

    @GetMapping
    public List<Produto> listar() {
        Collator ordem = Collator.getInstance(Locale.forLanguageTag("pt-BR"));
        ordem.setStrength(Collator.PRIMARY);
        List<Produto> lista = new ArrayList<>(produtos.findAll());
        lista.sort(Comparator.comparing(Produto::getNome, ordem));
        return lista;
    }

    @PostMapping
    public ResponseEntity<Produto> criar(@RequestBody Produto produto) {
        Produto produtoSalvo = produtos.save(produto);
        return ResponseEntity.status(HttpStatus.CREATED).body(produtoSalvo);
    }

    @PutMapping("/{id}")
    public Produto atualizar(@PathVariable Long id, @RequestBody Produto produto) {
        produto.setId(id);
        return produtos.save(produto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id) {
        produtos.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}

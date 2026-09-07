package br.com.adminpool.controller;

import br.com.adminpool.dto.NovaPiscinaRequest;
import br.com.adminpool.model.Piscina;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.PiscinaRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/piscinas")

public class PiscinaController {

    private final PiscinaRepository piscinas;
    private final ClienteRepository clientes;

    public PiscinaController(PiscinaRepository piscinas, ClienteRepository clientes) {
        this.piscinas = piscinas;
        this.clientes = clientes;
    }

    @GetMapping("/cliente/{clienteId}")
    public List<Piscina> listarPorCliente(@PathVariable Long clienteId) {
        return piscinas.findByClienteIdOrderByNome(clienteId);
    }

    @PostMapping
    public ResponseEntity<Piscina> criar(@RequestBody NovaPiscinaRequest requisicao) {
        Piscina piscina = new Piscina();
        piscina.setCliente(clientes.findById(requisicao.clienteId()).orElseThrow());
        piscina.setNome(requisicao.nome());
        piscina.setTipo(requisicao.tipo());
        piscina.setVolumeLitros(requisicao.volumeLitros());
        piscina.setObservacoes(requisicao.observacoes());

        Piscina piscinaSalva = piscinas.save(piscina);
        return ResponseEntity.status(HttpStatus.CREATED).body(piscinaSalva);
    }
}

package br.com.adminpool.service;

import br.com.adminpool.model.Cliente;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.CobrancaRepository;
import br.com.adminpool.repository.ProdutoRepository;
import br.com.adminpool.model.CobrancaMensal;
import br.com.adminpool.model.Produto;
import br.com.adminpool.model.StatusCobranca;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import java.io.*;
import java.math.BigDecimal;
import java.time.YearMonth;

@Component
public class ImportadorClientes implements CommandLineRunner {
    private final ClienteRepository clientes;
    private final CobrancaRepository cobrancas;
    private final ProdutoRepository produtos;
    public ImportadorClientes(ClienteRepository clientes, CobrancaRepository cobrancas, ProdutoRepository produtos) { this.clientes = clientes; this.cobrancas = cobrancas; this.produtos = produtos; }
    @Override public void run(String... args) throws Exception {
        if (clientes.count() > 0) {
            clientes.findAll().forEach(cliente -> {
                cliente.setDiaVencimento(cliente.getNome().trim().equalsIgnoreCase("Rubia") ? 20 : 10);
                clientes.save(cliente);
            });
            gerarCobrancas(); gerarProdutos(); return;
        }
        try (BufferedReader leitor = new BufferedReader(new InputStreamReader(new ClassPathResource("clientes.csv").getInputStream()))) {
            String linha;
            while ((linha = leitor.readLine()) != null) {
                if (linha.isBlank() || linha.startsWith("nome;")) continue;
                String[] dados = linha.split(";");
                Cliente cliente = new Cliente();
                cliente.setNome(dados[0].trim());
                cliente.setValorMensalidade(new BigDecimal(dados[1].trim()));
                cliente.setDiaVencimento(cliente.getNome().trim().equalsIgnoreCase("Rubia") ? 20 : 10);
                cliente.setAtivo(true);
                clientes.save(cliente);
            }
        }
        gerarCobrancas(); gerarProdutos();
    }
    private void gerarCobrancas() { YearMonth mes = YearMonth.now(); String referencia = mes.toString(); clientes.findAll().forEach(cliente -> { if (!cobrancas.existsByClienteIdAndReferencia(cliente.getId(), referencia)) { CobrancaMensal c = new CobrancaMensal(); c.setCliente(cliente); c.setReferencia(referencia); c.setVencimento(mes.atDay(Math.min(cliente.getDiaVencimento(), mes.lengthOfMonth()))); c.setMensalidade(cliente.getValorMensalidade()); c.setTotal(cliente.getValorMensalidade()); c.setStatus(c.getVencimento().isBefore(java.time.LocalDate.now()) ? StatusCobranca.VENCIDO : StatusCobranca.PENDENTE); cobrancas.save(c); }}); }
    private void gerarProdutos() { adicionarProduto("Balde Cloro Genco 10 kg", "199.00", "230.00"); adicionarProduto("Barrilha", "20.00", "38.00"); adicionarProduto("Algicida manutenção", "19.50", "30.00"); adicionarProduto("Mangueira (metro)", "12.60", "14.00"); adicionarProduto("Tratamento semanal", "26.95", "40.00"); adicionarProduto("Balde de Proptoll", "150.00", "190.00"); adicionarProduto("pH Certo", "30.00", "40.00"); }
    private void adicionarProduto(String nome, String compra, String venda) { if (!produtos.existsByNomeIgnoreCase(nome)) { Produto p = new Produto(); p.setNome(nome); p.setPrecoCompra(new BigDecimal(compra)); p.setPrecoVenda(new BigDecimal(venda)); p.setEstoque(0); produtos.save(p); } }
}

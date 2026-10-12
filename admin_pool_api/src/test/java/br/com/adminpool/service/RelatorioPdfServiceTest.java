package br.com.adminpool.service;

import br.com.adminpool.dto.LinhaRelatorioPdf;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertTrue;

class RelatorioPdfServiceTest {

    @Test
    void geraUmArquivoPdfValido() {
        byte[] pdf = new RelatorioPdfService().gerar(
                "Relatório de teste", "Todos os registros",
                List.of(new LinhaRelatorioPdf("Cliente", "Item", "20/09/2026", new BigDecimal("10.00"))));

        assertTrue(pdf.length > 100);
        assertTrue(new String(pdf, 0, 4, StandardCharsets.US_ASCII).startsWith("%PDF"));
    }

    @Test
    void geraPedidoDeCapaNoMesmoFormatoBasicoDoRelatorio() {
        byte[] pdf = new RelatorioPdfService().gerarCapa(
                "Pedido #75", "Endereço não informado.",
                List.of(new LinhaRelatorioPdf("Allison", "Capa 300 micras", "2026-10-12", new BigDecimal("360.00"))));

        assertTrue(pdf.length > 100);
        assertTrue(new String(pdf, 0, 4, StandardCharsets.US_ASCII).startsWith("%PDF"));
    }
}

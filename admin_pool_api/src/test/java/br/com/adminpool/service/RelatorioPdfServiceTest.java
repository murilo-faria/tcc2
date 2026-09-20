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
}

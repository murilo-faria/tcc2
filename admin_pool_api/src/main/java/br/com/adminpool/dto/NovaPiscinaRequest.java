package br.com.adminpool.dto;

import java.math.BigDecimal;

/** Dados necessários para cadastrar uma piscina para um cliente. */
public record NovaPiscinaRequest(
        Long clienteId,
        String nome,
        String tipo,
        Integer volumeLitros,
        String endereco,
        Long responsavelId,
        String diaAtendimento,
        String observacoes,
        BigDecimal valorMensalidade,
        BigDecimal comprimento,
        BigDecimal largura) {
}

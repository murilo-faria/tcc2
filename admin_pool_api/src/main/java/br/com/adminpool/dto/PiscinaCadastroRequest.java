package br.com.adminpool.dto;

import java.math.BigDecimal;

/** Dados de uma piscina incluída junto ao cadastro de um cliente. */
public record PiscinaCadastroRequest(
        String nome,
        String tipo,
        BigDecimal comprimento,
        BigDecimal largura,
        BigDecimal profundidade,
        BigDecimal descontoEscada,
        String endereco,
        BigDecimal valorMensalidade,
        Long responsavelId,
        String diaAtendimento) {
}

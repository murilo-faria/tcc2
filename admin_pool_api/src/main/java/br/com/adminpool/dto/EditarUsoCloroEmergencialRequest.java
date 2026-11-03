package br.com.adminpool.dto;

import java.math.BigDecimal;

/** Dados editáveis de um lançamento ainda aberto de cloro emergencial. */
public record EditarUsoCloroEmergencialRequest(BigDecimal quantidadeKg, String descricao) {}

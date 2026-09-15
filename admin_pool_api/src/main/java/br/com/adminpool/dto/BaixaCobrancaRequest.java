package br.com.adminpool.dto;
import java.math.BigDecimal;
public record BaixaCobrancaRequest(BigDecimal valor, String formaPagamento) {}

package br.com.adminpool.dto;
import java.math.BigDecimal;
public record NovoUsoCloroEmergencialRequest(BigDecimal quantidadeKg, String descricao) {}

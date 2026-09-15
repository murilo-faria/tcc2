package br.com.adminpool.dto;
import br.com.adminpool.model.ResponsavelPagamento;
import java.math.BigDecimal;
public record ConcluirOrdemServicoRequest(BigDecimal valorCusto, BigDecimal valorCobrado, ResponsavelPagamento pagoPor, String formaPagamento) {}

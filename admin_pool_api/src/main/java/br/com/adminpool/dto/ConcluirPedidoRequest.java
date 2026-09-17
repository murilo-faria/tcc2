package br.com.adminpool.dto;
import br.com.adminpool.model.ResponsavelPagamento;
import java.math.BigDecimal;
public record ConcluirPedidoRequest(ResponsavelPagamento pagoPor, BigDecimal desconto) {}

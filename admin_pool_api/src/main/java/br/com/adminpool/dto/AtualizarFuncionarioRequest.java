package br.com.adminpool.dto;
import java.math.BigDecimal;
public record AtualizarFuncionarioRequest(String nome, String telefone, BigDecimal percentualMensalidade, String novaSenha) {}

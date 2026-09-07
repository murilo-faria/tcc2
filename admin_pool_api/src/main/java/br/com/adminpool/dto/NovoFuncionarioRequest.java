package br.com.adminpool.dto;
import java.math.BigDecimal;
public record NovoFuncionarioRequest(String nome, String login, String senha, String telefone, BigDecimal percentualMensalidade) {}

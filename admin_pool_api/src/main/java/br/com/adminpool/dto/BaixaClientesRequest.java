package br.com.adminpool.dto;

import java.util.List;

public record BaixaClientesRequest(List<Long> clienteIds, String formaPagamento) {}

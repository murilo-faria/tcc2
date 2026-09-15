package br.com.adminpool.dto;
import java.util.List;
public record BaixaItensRequest(List<Long> itemIds, String formaPagamento) {}

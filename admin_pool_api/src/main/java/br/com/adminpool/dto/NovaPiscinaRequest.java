package br.com.adminpool.dto;

/** Dados necessários para cadastrar uma piscina para um cliente. */
public record NovaPiscinaRequest(
        Long clienteId,
        String nome,
        String tipo,
        Integer volumeLitros,
        String observacoes) {
}

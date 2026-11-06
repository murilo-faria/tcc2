package br.com.adminpool.dto;

/** A lista pertence à piscina atendida, e não ao cliente inteiro. */
public record NovoCloroEmergencialRequest(Long clienteId, Long piscinaId) {}

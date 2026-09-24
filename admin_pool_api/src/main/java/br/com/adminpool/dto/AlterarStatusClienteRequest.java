package br.com.adminpool.dto;

/** Ativa ou pausa a geração de mensalidades futuras de um cliente. */
public record AlterarStatusClienteRequest(boolean ativo) {
}

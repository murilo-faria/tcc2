package br.com.adminpool.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record NovoClienteRequest(
        String nome, String cpfCnpj, String telefone, String endereco,
        BigDecimal valorMensalidade, Integer diaVencimento, LocalDate primeiroVencimento,
        String piscinaNome, String piscinaTipo, Integer piscinaVolumeLitros,
        String piscinaEndereco, Long responsavelId, String diaAtendimento) {}

package br.com.adminpool.dto;

import java.math.BigDecimal;

/** Linha simples usada na montagem dos relatórios em PDF. */
public class LinhaRelatorioPdf {
    private final String cliente;
    private final String descricao;
    private final String data;
    private final BigDecimal valor;

    public LinhaRelatorioPdf(String cliente, String descricao, String data, BigDecimal valor) {
        this.cliente = cliente;
        this.descricao = descricao;
        this.data = data;
        this.valor = valor;
    }

    public String getCliente() { return cliente; }
    public String getDescricao() { return descricao; }
    public String getData() { return data; }
    public BigDecimal getValor() { return valor; }
}

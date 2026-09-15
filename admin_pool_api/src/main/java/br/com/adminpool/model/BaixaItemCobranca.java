package br.com.adminpool.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "baixas_itens_cobranca")
public class BaixaItemCobranca {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(optional = false) @JoinColumn(name = "item_cobranca_id") private ItemCobranca item;
    @Column(nullable = false, precision = 12, scale = 2) private BigDecimal valor;
    @Column(nullable = false) private LocalDateTime dataPagamento = LocalDateTime.now();
    private String formaPagamento;
    private String grupoPagamento;
    public Long getId(){return id;} public void setId(Long v){id=v;}
    public ItemCobranca getItem(){return item;} public void setItem(ItemCobranca v){item=v;}
    public BigDecimal getValor(){return valor;} public void setValor(BigDecimal v){valor=v;}
    public LocalDateTime getDataPagamento(){return dataPagamento;} public void setDataPagamento(LocalDateTime v){dataPagamento=v;}
    public String getFormaPagamento(){return formaPagamento;} public void setFormaPagamento(String v){formaPagamento=v;}
    public String getGrupoPagamento(){return grupoPagamento;} public void setGrupoPagamento(String v){grupoPagamento=v;}
}

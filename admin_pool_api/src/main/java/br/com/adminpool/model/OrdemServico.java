package br.com.adminpool.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "ordens_servico")
public class OrdemServico {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(optional = false) private Cliente cliente;
    @ManyToOne private Piscina piscina;
    @Column(nullable = false, length = 2000) private String descricao;
    private LocalDate dataServico = LocalDate.now();
    @Column(nullable = false, precision = 12, scale = 2) private BigDecimal valorAdicional = BigDecimal.ZERO;
    private String status = "ABERTA";
    public Long getId(){return id;} public void setId(Long v){id=v;}
    public Cliente getCliente(){return cliente;} public void setCliente(Cliente v){cliente=v;}
    public Piscina getPiscina(){return piscina;} public void setPiscina(Piscina v){piscina=v;}
    public String getDescricao(){return descricao;} public void setDescricao(String v){descricao=v;}
    public LocalDate getDataServico(){return dataServico;} public void setDataServico(LocalDate v){dataServico=v;}
    public BigDecimal getValorAdicional(){return valorAdicional;} public void setValorAdicional(BigDecimal v){valorAdicional=v;}
    public String getStatus(){return status;} public void setStatus(String v){status=v;}
}

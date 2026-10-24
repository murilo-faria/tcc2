package br.com.adminpool.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "usos_cloro_emergencial")
public class UsoCloroEmergencial {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @JsonIgnore @ManyToOne(optional = false) @JoinColumn(name = "cloro_emergencial_id")
    private CloroEmergencial lista;
    @Column(nullable = false, precision = 10, scale = 2) private BigDecimal quantidadeKg;
    @Column(length = 1000) private String descricao;
    @Column(nullable = false) private LocalDate dataUso = LocalDate.now();

    public Long getId(){ return id; } public void setId(Long v){ id=v; }
    public CloroEmergencial getLista(){ return lista; } public void setLista(CloroEmergencial v){ lista=v; }
    public BigDecimal getQuantidadeKg(){ return quantidadeKg; } public void setQuantidadeKg(BigDecimal v){ quantidadeKg=v; }
    public String getDescricao(){ return descricao; } public void setDescricao(String v){ descricao=v; }
    public LocalDate getDataUso(){ return dataUso; } public void setDataUso(LocalDate v){ dataUso=v; }
}

package br.com.adminpool.model;

import jakarta.persistence.*;

@Entity
@Table(name = "roteiro_atendimentos", uniqueConstraints = @UniqueConstraint(columnNames = {"cliente_id", "dia_atendimento"}))
public class RoteiroAtendimento {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(optional = false) @JoinColumn(name = "cliente_id") private Cliente cliente;
    @Column(name = "dia_atendimento", nullable = false, length = 20) private String diaAtendimento;
    public Long getId(){ return id; } public void setId(Long v){ id=v; }
    public Cliente getCliente(){ return cliente; } public void setCliente(Cliente v){ cliente=v; }
    public String getDiaAtendimento(){ return diaAtendimento; } public void setDiaAtendimento(String v){ diaAtendimento=v; }
}

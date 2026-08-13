package br.com.adminpool.model;

import jakarta.persistence.*;

@Entity
@Table(name = "piscinas")
public class Piscina {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(optional = false) @JoinColumn(name = "cliente_id") private Cliente cliente;
    @Column(nullable = false) private String nome;
    private String tipo;
    private Integer volumeLitros;
    @Column(length = 2000) private String observacoes;
    public Long getId(){return id;} public void setId(Long v){id=v;}
    public Cliente getCliente(){return cliente;} public void setCliente(Cliente v){cliente=v;}
    public String getNome(){return nome;} public void setNome(String v){nome=v;}
    public String getTipo(){return tipo;} public void setTipo(String v){tipo=v;}
    public Integer getVolumeLitros(){return volumeLitros;} public void setVolumeLitros(Integer v){volumeLitros=v;}
    public String getObservacoes(){return observacoes;} public void setObservacoes(String v){observacoes=v;}
}

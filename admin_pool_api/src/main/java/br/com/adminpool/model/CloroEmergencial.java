package br.com.adminpool.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/** Lista mensal de cloro usado excepcionalmente para um cliente. */
@Entity
@Table(name = "cloros_emergenciais", uniqueConstraints =
        @UniqueConstraint(columnNames = {"cliente_id", "referencia"}))
public class CloroEmergencial {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(optional = false) @JoinColumn(name = "cliente_id") private Cliente cliente;
    @ManyToOne @JoinColumn(name = "criado_por_id") private Funcionario criadoPor;
    @Column(nullable = false, length = 7) private String referencia;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30)
    private StatusCloroEmergencial status = StatusCloroEmergencial.ABERTA;
    @Column(nullable = false, precision = 12, scale = 2) private BigDecimal valorCobrado = BigDecimal.ZERO;
    private LocalDate dataConclusao;
    @OneToMany(mappedBy = "lista", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("dataUso ASC, id ASC") private List<UsoCloroEmergencial> usos = new ArrayList<>();

    public Long getId(){ return id; } public void setId(Long v){ id=v; }
    public Cliente getCliente(){ return cliente; } public void setCliente(Cliente v){ cliente=v; }
    public Funcionario getCriadoPor(){ return criadoPor; } public void setCriadoPor(Funcionario v){ criadoPor=v; }
    public String getReferencia(){ return referencia; } public void setReferencia(String v){ referencia=v; }
    public StatusCloroEmergencial getStatus(){ return status; } public void setStatus(StatusCloroEmergencial v){ status=v; }
    public BigDecimal getValorCobrado(){ return valorCobrado; } public void setValorCobrado(BigDecimal v){ valorCobrado=v; }
    public LocalDate getDataConclusao(){ return dataConclusao; } public void setDataConclusao(LocalDate v){ dataConclusao=v; }
    public List<UsoCloroEmergencial> getUsos(){ return usos; } public void setUsos(List<UsoCloroEmergencial> v){ usos=v; }
}

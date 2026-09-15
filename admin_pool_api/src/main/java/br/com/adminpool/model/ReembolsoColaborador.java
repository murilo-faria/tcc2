package br.com.adminpool.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "reembolsos_colaborador")
public class ReembolsoColaborador {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(optional = false) private Funcionario funcionario;
    @OneToOne(optional = false) private OrdemServico ordemServico;
    @Column(nullable = false) private String descricao;
    @Column(nullable = false, precision = 12, scale = 2) private BigDecimal valor;
    @Column(nullable = false) private LocalDate dataLancamento = LocalDate.now();
    @Enumerated(EnumType.STRING) @Column(nullable = false) private StatusReembolso status = StatusReembolso.PENDENTE;
    private LocalDate dataPagamento;
    public Long getId(){return id;} public void setId(Long v){id=v;}
    public Funcionario getFuncionario(){return funcionario;} public void setFuncionario(Funcionario v){funcionario=v;}
    public OrdemServico getOrdemServico(){return ordemServico;} public void setOrdemServico(OrdemServico v){ordemServico=v;}
    public String getDescricao(){return descricao;} public void setDescricao(String v){descricao=v;}
    public BigDecimal getValor(){return valor;} public void setValor(BigDecimal v){valor=v;}
    public LocalDate getDataLancamento(){return dataLancamento;} public void setDataLancamento(LocalDate v){dataLancamento=v;}
    public StatusReembolso getStatus(){return status;} public void setStatus(StatusReembolso v){status=v;}
    public LocalDate getDataPagamento(){return dataPagamento;} public void setDataPagamento(LocalDate v){dataPagamento=v;}
}

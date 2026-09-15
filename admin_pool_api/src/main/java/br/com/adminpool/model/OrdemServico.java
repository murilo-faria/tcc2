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
    @ManyToOne @JoinColumn(name="criado_por_id") private Funcionario criadoPor;
    @Column(nullable=false,precision=12,scale=2) private BigDecimal valorCusto=BigDecimal.ZERO;
    @Column(nullable=false,precision=12,scale=2) private BigDecimal valorCobrado=BigDecimal.ZERO;
    @Enumerated(EnumType.STRING) private ResponsavelPagamento pagoPor;
    private boolean financeiroLancado=false;
    private LocalDate dataConclusao;
    public Long getId(){return id;} public void setId(Long v){id=v;}
    public Cliente getCliente(){return cliente;} public void setCliente(Cliente v){cliente=v;}
    public Piscina getPiscina(){return piscina;} public void setPiscina(Piscina v){piscina=v;}
    public String getDescricao(){return descricao;} public void setDescricao(String v){descricao=v;}
    public LocalDate getDataServico(){return dataServico;} public void setDataServico(LocalDate v){dataServico=v;}
    public BigDecimal getValorAdicional(){return valorAdicional;} public void setValorAdicional(BigDecimal v){valorAdicional=v;}
    public String getStatus(){return status;} public void setStatus(String v){status=v;}
    public Funcionario getCriadoPor(){return criadoPor;} public void setCriadoPor(Funcionario v){criadoPor=v;}
    public BigDecimal getValorCusto(){return valorCusto;} public void setValorCusto(BigDecimal v){valorCusto=v;}
    public BigDecimal getValorCobrado(){return valorCobrado;} public void setValorCobrado(BigDecimal v){valorCobrado=v;}
    public ResponsavelPagamento getPagoPor(){return pagoPor;} public void setPagoPor(ResponsavelPagamento v){pagoPor=v;}
    public boolean isFinanceiroLancado(){return financeiroLancado;} public void setFinanceiroLancado(boolean v){financeiroLancado=v;}
    public LocalDate getDataConclusao(){return dataConclusao;} public void setDataConclusao(LocalDate v){dataConclusao=v;}
}

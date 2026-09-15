package br.com.adminpool.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "itens_cobranca")
public class ItemCobranca {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @JsonIgnore @ManyToOne(optional = false) @JoinColumn(name = "cobranca_id") private CobrancaMensal cobranca;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private TipoLancamentoCobranca tipo;
    @Column(nullable = false) private String descricao;
    private Long origemId;
    @Column(nullable = false) private LocalDate dataLancamento = LocalDate.now();
    @Column(nullable = false, precision = 12, scale = 2) private BigDecimal valorOriginal;
    @Column(nullable = false, precision = 12, scale = 2) private BigDecimal valorPago = BigDecimal.ZERO;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private StatusItemCobranca status = StatusItemCobranca.PENDENTE;
    private LocalDate dataUltimoPagamento;

    public BigDecimal getSaldoPendente(){return valorOriginal.subtract(valorPago == null ? BigDecimal.ZERO : valorPago).max(BigDecimal.ZERO);}
    public String getReferencia(){return cobranca == null ? null : cobranca.getReferencia();}
    public LocalDate getVencimento(){return cobranca == null ? null : cobranca.getVencimento();}
    public Long getClienteId(){return cobranca == null ? null : cobranca.getCliente().getId();}
    public Long getId(){return id;} public void setId(Long v){id=v;}
    public CobrancaMensal getCobranca(){return cobranca;} public void setCobranca(CobrancaMensal v){cobranca=v;}
    public TipoLancamentoCobranca getTipo(){return tipo;} public void setTipo(TipoLancamentoCobranca v){tipo=v;}
    public String getDescricao(){return descricao;} public void setDescricao(String v){descricao=v;}
    public Long getOrigemId(){return origemId;} public void setOrigemId(Long v){origemId=v;}
    public LocalDate getDataLancamento(){return dataLancamento;} public void setDataLancamento(LocalDate v){dataLancamento=v;}
    public BigDecimal getValorOriginal(){return valorOriginal;} public void setValorOriginal(BigDecimal v){valorOriginal=v;}
    public BigDecimal getValorPago(){return valorPago;} public void setValorPago(BigDecimal v){valorPago=v;}
    public StatusItemCobranca getStatus(){return status;} public void setStatus(StatusItemCobranca v){status=v;}
    public LocalDate getDataUltimoPagamento(){return dataUltimoPagamento;} public void setDataUltimoPagamento(LocalDate v){dataUltimoPagamento=v;}
}

package br.com.adminpool.model;
import jakarta.persistence.*; import java.math.BigDecimal; import java.time.LocalDate;
@Entity @Table(name="vales_colaborador") public class ValeColaborador {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 @ManyToOne(optional=false) private Funcionario funcionario;
 @Column(nullable=false) private String tipo;
 @Column(nullable=false,precision=12,scale=2) private BigDecimal valor;
 @Column(nullable=false) private LocalDate dataLancamento;
 @Column(length=500) private String observacao;
 public Long getId(){return id;} public Funcionario getFuncionario(){return funcionario;} public void setFuncionario(Funcionario v){funcionario=v;} public String getTipo(){return tipo;} public void setTipo(String v){tipo=v;} public BigDecimal getValor(){return valor;} public void setValor(BigDecimal v){valor=v;} public LocalDate getDataLancamento(){return dataLancamento;} public void setDataLancamento(LocalDate v){dataLancamento=v;} public String getObservacao(){return observacao;} public void setObservacao(String v){observacao=v;}
}

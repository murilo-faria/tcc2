package br.com.adminpool.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.math.RoundingMode;

@Entity
@Table(name = "piscinas")
public class Piscina {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(optional = false) @JoinColumn(name = "cliente_id") private Cliente cliente;
    @Column(nullable = false) private String nome;
    private String tipo;
    private Integer volumeLitros;
    @Column(precision = 10, scale = 2) private BigDecimal comprimento;
    @Column(precision = 10, scale = 2) private BigDecimal largura;
    @Column(precision = 10, scale = 2) private BigDecimal profundidade = new BigDecimal("1.40");
    @Column(precision = 5, scale = 2) private BigDecimal descontoEscada = new BigDecimal("15.00");
    @Column(precision = 12, scale = 2) private BigDecimal valorMensalidade = BigDecimal.ZERO;
    @Column(length = 500) private String endereco;
    @ManyToOne @JoinColumn(name = "responsavel_id") private Funcionario responsavel;
    @Column(length = 20) private String diaAtendimento;
    @Column(length = 2000) private String observacoes;
    public Long getId(){return id;} public void setId(Long v){id=v;}
    public Cliente getCliente(){return cliente;} public void setCliente(Cliente v){cliente=v;}
    public String getNome(){return nome;} public void setNome(String v){nome=v;}
    public String getTipo(){return tipo;} public void setTipo(String v){tipo=v;}
    public Integer getVolumeLitros(){return volumeLitros;} public void setVolumeLitros(Integer v){volumeLitros=v;}
    public BigDecimal getComprimento(){return comprimento;} public void setComprimento(BigDecimal v){comprimento=v;}
    public BigDecimal getLargura(){return largura;} public void setLargura(BigDecimal v){largura=v;}
    public BigDecimal getProfundidade(){return profundidade;} public void setProfundidade(BigDecimal v){profundidade=v;}
    public BigDecimal getDescontoEscada(){return descontoEscada;} public void setDescontoEscada(BigDecimal v){descontoEscada=v;}
    @Transient public BigDecimal getMetragemQuadrada(){return comprimento == null || largura == null ? BigDecimal.ZERO : comprimento.multiply(largura);}
    @Transient public BigDecimal getLitragemCalculada(){
        BigDecimal profundidadeUsada = profundidade == null ? new BigDecimal("1.40") : profundidade;
        BigDecimal descontoUsado = descontoEscada == null ? new BigDecimal("15.00") : descontoEscada;
        return getMetragemQuadrada().multiply(profundidadeUsada).multiply(new BigDecimal("1000"))
                .multiply(BigDecimal.ONE.subtract(descontoUsado.divide(new BigDecimal("100"))))
                .setScale(0, RoundingMode.HALF_UP);
    }
    public BigDecimal getValorMensalidade(){return valorMensalidade;} public void setValorMensalidade(BigDecimal v){valorMensalidade=v;}
    public String getEndereco(){return endereco;} public void setEndereco(String v){endereco=v;}
    public Funcionario getResponsavel(){return responsavel;} public void setResponsavel(Funcionario v){responsavel=v;}
    public String getDiaAtendimento(){return diaAtendimento;} public void setDiaAtendimento(String v){diaAtendimento=v;}
    public String getObservacoes(){return observacoes;} public void setObservacoes(String v){observacoes=v;}
}

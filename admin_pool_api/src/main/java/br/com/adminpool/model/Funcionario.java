package br.com.adminpool.model;
import jakarta.persistence.*; import java.math.BigDecimal;
@Entity @Table(name="funcionarios")
public class Funcionario {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 @OneToOne(optional=false) @JoinColumn(name="usuario_id",unique=true) private Usuario usuario;
 @Column(nullable=false,precision=5,scale=2) private BigDecimal percentualMensalidade=new BigDecimal("75.00"); private String telefone;
 public Long getId(){return id;} public void setId(Long v){id=v;} public Usuario getUsuario(){return usuario;} public void setUsuario(Usuario v){usuario=v;} public BigDecimal getPercentualMensalidade(){return percentualMensalidade;} public void setPercentualMensalidade(BigDecimal v){percentualMensalidade=v;} public String getTelefone(){return telefone;} public void setTelefone(String v){telefone=v;}
}

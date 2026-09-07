package br.com.adminpool.model;
import jakarta.persistence.*; import java.math.BigDecimal;
@Entity @Table(name="produtos")
public class Produto {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id; @Column(nullable=false,unique=true) private String nome;
 @Column(nullable=false,precision=12,scale=2) private BigDecimal precoCompra; @Column(nullable=false,precision=12,scale=2) private BigDecimal precoVenda; @Column(nullable=false) private Integer estoque=0;
 public Long getId(){return id;} public void setId(Long v){id=v;} public String getNome(){return nome;} public void setNome(String v){nome=v;} public BigDecimal getPrecoCompra(){return precoCompra;} public void setPrecoCompra(BigDecimal v){precoCompra=v;} public BigDecimal getPrecoVenda(){return precoVenda;} public void setPrecoVenda(BigDecimal v){precoVenda=v;} public Integer getEstoque(){return estoque;} public void setEstoque(Integer v){estoque=v;}
}

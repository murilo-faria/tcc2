package br.com.adminpool.model;
import jakarta.persistence.*; import java.math.BigDecimal; import java.time.LocalDate;
@Entity @Table(name="pedidos_produto")
public class PedidoProduto {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id; @ManyToOne(optional=false) private Cliente cliente; @ManyToOne private Produto produto; @Column(nullable=false) private Integer quantidade; @Column(nullable=false,precision=12,scale=2) private BigDecimal valorUnitario; private LocalDate dataPedido=LocalDate.now(); private String status="SOLICITADO";
 public Long getId(){return id;} public void setId(Long v){id=v;} public Cliente getCliente(){return cliente;} public void setCliente(Cliente v){cliente=v;} public Produto getProduto(){return produto;} public void setProduto(Produto v){produto=v;} public Integer getQuantidade(){return quantidade;} public void setQuantidade(Integer v){quantidade=v;} public BigDecimal getValorUnitario(){return valorUnitario;} public void setValorUnitario(BigDecimal v){valorUnitario=v;} public LocalDate getDataPedido(){return dataPedido;} public void setDataPedido(LocalDate v){dataPedido=v;} public String getStatus(){return status;} public void setStatus(String v){status=v;}
}

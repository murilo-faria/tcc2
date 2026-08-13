package br.com.adminpool.model;
import jakarta.persistence.*; import java.math.BigDecimal;
@Entity @Table(name="clientes")
public class Cliente {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id; @Column(nullable=false) private String nome; private String cpfCnpj; private String telefone; private String endereco;
 @Column(nullable=false,precision=12,scale=2) private BigDecimal valorMensalidade; private Integer diaVencimento;
 @ManyToOne @JoinColumn(name="funcionario_id") private Funcionario funcionario; private boolean ativo=true;
 public Long getId(){return id;} public void setId(Long v){id=v;} public String getNome(){return nome;} public void setNome(String v){nome=v;} public String getCpfCnpj(){return cpfCnpj;} public void setCpfCnpj(String v){cpfCnpj=v;} public String getTelefone(){return telefone;} public void setTelefone(String v){telefone=v;} public String getEndereco(){return endereco;} public void setEndereco(String v){endereco=v;} public BigDecimal getValorMensalidade(){return valorMensalidade;} public void setValorMensalidade(BigDecimal v){valorMensalidade=v;} public Integer getDiaVencimento(){return diaVencimento;} public void setDiaVencimento(Integer v){diaVencimento=v;} public Funcionario getFuncionario(){return funcionario;} public void setFuncionario(Funcionario v){funcionario=v;} public boolean isAtivo(){return ativo;} public void setAtivo(boolean v){ativo=v;}
}

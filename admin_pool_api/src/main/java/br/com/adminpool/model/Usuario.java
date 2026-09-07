package br.com.adminpool.model;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
@Entity @Table(name="usuarios")
public class Usuario {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 @Column(nullable=false) private String nome;
 @Column(nullable=false,unique=true) private String email;
 @Column(unique=true) private String login;
 @JsonIgnore @Column(nullable=false) private String senha;
 @Enumerated(EnumType.STRING) @Column(nullable=false) private Perfil perfil;
 private boolean ativo=true;
 public Long getId(){return id;} public void setId(Long v){id=v;} public String getNome(){return nome;} public void setNome(String v){nome=v;} public String getEmail(){return email;} public void setEmail(String v){email=v;} public String getLogin(){return login;} public void setLogin(String v){login=v;} public String getSenha(){return senha;} public void setSenha(String v){senha=v;} public Perfil getPerfil(){return perfil;} public void setPerfil(Perfil v){perfil=v;} public boolean isAtivo(){return ativo;} public void setAtivo(boolean v){ativo=v;}
}

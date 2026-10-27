package br.com.adminpool.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/** Registro imutável de alterações administrativas e financeiras realizadas pela API. */
@Entity
@Table(name = "registros_auditoria")
public class RegistroAuditoria {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, length = 100)
    private String usuarioLogin;
    @Column(nullable = false, length = 20)
    private String acao;
    @Column(nullable = false, length = 100)
    private String modulo;
    @Column(nullable = false, length = 500)
    private String recurso;
    @Column(nullable = false)
    private LocalDateTime dataHora = LocalDateTime.now();
    @Column(length = 4000)
    private String dadosInformados;
    @Column(length = 1000)
    private String resultado;

    public Long getId(){ return id; } public void setId(Long valor){ id=valor; }
    public String getUsuarioLogin(){ return usuarioLogin; } public void setUsuarioLogin(String valor){ usuarioLogin=valor; }
    public String getAcao(){ return acao; } public void setAcao(String valor){ acao=valor; }
    public String getModulo(){ return modulo; } public void setModulo(String valor){ modulo=valor; }
    public String getRecurso(){ return recurso; } public void setRecurso(String valor){ recurso=valor; }
    public LocalDateTime getDataHora(){ return dataHora; } public void setDataHora(LocalDateTime valor){ dataHora=valor; }
    public String getDadosInformados(){ return dadosInformados; } public void setDadosInformados(String valor){ dadosInformados=valor; }
    public String getResultado(){ return resultado; } public void setResultado(String valor){ resultado=valor; }
}

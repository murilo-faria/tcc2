package br.com.adminpool.service;
import br.com.adminpool.model.*; import br.com.adminpool.repository.*; import java.math.BigDecimal; import org.springframework.beans.factory.annotation.Value; import org.springframework.boot.ApplicationArguments; import org.springframework.boot.ApplicationRunner; import org.springframework.security.crypto.password.PasswordEncoder; import org.springframework.stereotype.Component;
@Component public class ContaInicialService implements ApplicationRunner {
 private final UsuarioRepository usuarios; private final FuncionarioRepository funcionarios; private final PasswordEncoder encoder; @Value("${APP_GESTOR_PASSWORD}") String gestor; @Value("${APP_FUNCIONARIO_PASSWORD}") String funcionario;
 public ContaInicialService(UsuarioRepository u, FuncionarioRepository f, PasswordEncoder e){usuarios=u;funcionarios=f;encoder=e;}
 public void run(ApplicationArguments a){ criarGestor(); criarFuncionario(); }
 private Usuario usuario(String login,String nome,String senha,Perfil perfil){return usuarios.findByLoginIgnoreCase(login).orElseGet(()->{Usuario u=new Usuario();u.setLogin(login);u.setNome(nome);u.setEmail(login+"@adminpool.local");u.setSenha(encoder.encode(senha));u.setPerfil(perfil);u.setAtivo(true);return usuarios.save(u);});}
 private void criarGestor(){usuario("gestorMurilo","Murilo",gestor,Perfil.GESTOR);}
 private void criarFuncionario(){Usuario u=usuario("funcionario1","Funcionário 1",funcionario,Perfil.FUNCIONARIO);if(funcionarios.findByUsuarioLoginIgnoreCase("funcionario1").isEmpty()){Funcionario f=new Funcionario();f.setUsuario(u);f.setPercentualMensalidade(new BigDecimal("75.00"));funcionarios.save(f);}}
}

package br.com.adminpool.controller;

import br.com.adminpool.dto.NovoFuncionarioRequest;
import br.com.adminpool.dto.RedefinirSenhaRequest;
import br.com.adminpool.dto.AtualizarFuncionarioRequest;
import br.com.adminpool.model.Funcionario;
import br.com.adminpool.model.Perfil;
import br.com.adminpool.model.Usuario;
import br.com.adminpool.repository.FuncionarioRepository;
import br.com.adminpool.repository.UsuarioRepository;
import java.math.BigDecimal;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/funcionarios")
public class FuncionarioController {
 private final FuncionarioRepository funcionarios; private final UsuarioRepository usuarios; private final PasswordEncoder encoder;
 public FuncionarioController(FuncionarioRepository f, UsuarioRepository u, PasswordEncoder e){funcionarios=f;usuarios=u;encoder=e;}
 @GetMapping public List<Funcionario> listar(Authentication auth){gestor(auth);return funcionarios.findAll();}
 @PostMapping public ResponseEntity<Funcionario> criar(@RequestBody NovoFuncionarioRequest r, Authentication auth){gestor(auth);
  if(r.nome()==null||r.nome().isBlank()||r.login()==null||r.login().isBlank()||r.senha()==null||r.senha().length()<6) throw new IllegalArgumentException("Informe nome, usuário e uma senha com ao menos 6 caracteres.");
  if(usuarios.findByLoginIgnoreCase(r.login()).isPresent()) throw new IllegalArgumentException("Este usuário já existe.");
  Usuario u=new Usuario();u.setNome(r.nome().trim());u.setLogin(r.login().trim());u.setEmail(r.login().trim()+"@adminpool.local");u.setSenha(encoder.encode(r.senha()));u.setPerfil(Perfil.FUNCIONARIO);u.setAtivo(true);usuarios.save(u);
  Funcionario f=new Funcionario();f.setUsuario(u);f.setTelefone(r.telefone());f.setPercentualMensalidade(r.percentualMensalidade()==null?new BigDecimal("75.00"):r.percentualMensalidade());
  return ResponseEntity.status(HttpStatus.CREATED).body(funcionarios.save(f));
 }
 @PutMapping("/{id}") public Funcionario atualizar(@PathVariable Long id, @RequestBody AtualizarFuncionarioRequest r, Authentication auth){gestor(auth);Funcionario f=funcionarios.findById(id).orElseThrow();if(r.nome()!=null&&!r.nome().isBlank())f.getUsuario().setNome(r.nome().trim());f.setTelefone(r.telefone());if(r.percentualMensalidade()!=null)f.setPercentualMensalidade(r.percentualMensalidade());if(r.novaSenha()!=null&&!r.novaSenha().isBlank()){if(r.novaSenha().length()<6)throw new IllegalArgumentException("A senha deve ter ao menos 6 caracteres.");f.getUsuario().setSenha(encoder.encode(r.novaSenha()));}usuarios.save(f.getUsuario());return funcionarios.save(f);}
 @PutMapping("/{id}/senha") public ResponseEntity<Void> redefinirSenha(@PathVariable Long id, @RequestBody RedefinirSenhaRequest r, Authentication auth){gestor(auth);if(r.novaSenha()==null||r.novaSenha().length()<6)throw new IllegalArgumentException("A senha deve ter ao menos 6 caracteres.");Funcionario f=funcionarios.findById(id).orElseThrow();f.getUsuario().setSenha(encoder.encode(r.novaSenha()));usuarios.save(f.getUsuario());return ResponseEntity.noContent().build();}
 private void gestor(Authentication auth){if(auth.getAuthorities().stream().noneMatch(a->a.getAuthority().equals("ROLE_GESTOR")))throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem administrar funcionários.");}
}

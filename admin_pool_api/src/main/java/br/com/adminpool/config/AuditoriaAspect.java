package br.com.adminpool.config;

import br.com.adminpool.service.AuditoriaService;
import jakarta.servlet.http.HttpServletRequest;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.http.HttpMethod;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

/** Intercepta mutações concluídas dos controladores, sem registrar leituras ou falhas. */
@Aspect
@Component
public class AuditoriaAspect {
    private final AuditoriaService auditoria;
    private final HttpServletRequest requisicao;

    public AuditoriaAspect(AuditoriaService auditoria, HttpServletRequest requisicao) {
        this.auditoria = auditoria;
        this.requisicao = requisicao;
    }

    @Around("within(@org.springframework.web.bind.annotation.RestController *)")
    public Object auditarMutacao(ProceedingJoinPoint chamada) throws Throwable {
        Object retorno = chamada.proceed();
        String metodo = requisicao.getMethod();
        if (HttpMethod.POST.matches(metodo) || HttpMethod.PUT.matches(metodo)
                || HttpMethod.PATCH.matches(metodo) || HttpMethod.DELETE.matches(metodo)) {
            Authentication autenticacao = SecurityContextHolder.getContext().getAuthentication();
            auditoria.registrar(autenticacao, metodo, requisicao.getRequestURI(), chamada.getArgs(), retorno);
        }
        return retorno;
    }
}

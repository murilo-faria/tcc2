package br.com.adminpool.config;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

/** Retorna mensagens de regra de negócio que a tela consegue apresentar. */
@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler({IllegalArgumentException.class, IllegalStateException.class})
    public ResponseEntity<Map<String, String>> regraDeNegocio(RuntimeException erro) {
        return ResponseEntity.badRequest().body(Map.of("message", erro.getMessage()));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Map<String, String>> vinculoImpedido(DataIntegrityViolationException erro) {
        return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of(
                "message", "Não foi possível excluir porque este cadastro possui histórico vinculado."
        ));
    }
}

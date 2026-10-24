package br.com.adminpool.dto;
import java.math.BigDecimal;
public record FinalizarCloroEmergencialRequest(String destino, BigDecimal valorCobrado) {}

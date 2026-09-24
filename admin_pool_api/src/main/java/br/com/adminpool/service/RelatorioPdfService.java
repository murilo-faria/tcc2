package br.com.adminpool.service;

import br.com.adminpool.dto.LinhaRelatorioPdf;
import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.awt.Color;
import java.math.BigDecimal;
import java.text.NumberFormat;
import java.util.List;
import java.util.Locale;

@Service
public class RelatorioPdfService {
    private static final Color AZUL = new Color(21, 101, 192);
    private static final Color CINZA_CLARO = new Color(238, 242, 247);
    private static final Locale BRASIL = Locale.of("pt", "BR");

    public byte[] gerar(String titulo, String filtros, List<LinhaRelatorioPdf> linhas) {
        try (ByteArrayOutputStream arquivo = new ByteArrayOutputStream()) {
            Document documento = new Document(PageSize.A4, 40, 40, 35, 35);
            PdfWriter.getInstance(documento, arquivo);
            documento.open();

            documento.add(new Paragraph("Admin Pool", fonte(18, Font.BOLD, AZUL)));
            documento.add(new Paragraph(titulo, fonte(14, Font.BOLD, Color.DARK_GRAY)));
            documento.add(new Paragraph(filtros, fonte(9, Font.NORMAL, Color.DARK_GRAY)));
            documento.add(new Paragraph(" "));

            PdfPTable tabela = new PdfPTable(new float[]{1.45f, 2.55f, 1.05f, 1.15f});
            tabela.setWidthPercentage(100);
            tabela.setHeaderRows(1);
            adicionarCabecalho(tabela, "CLIENTE", Element.ALIGN_LEFT);
            adicionarCabecalho(tabela, "DESCRIÇÃO", Element.ALIGN_LEFT);
            adicionarCabecalho(tabela, "DATA", Element.ALIGN_LEFT);
            adicionarCabecalho(tabela, "VALOR", Element.ALIGN_RIGHT);

            for (LinhaRelatorioPdf linha : linhas) {
                adicionarCelula(tabela, linha.getCliente(), Element.ALIGN_LEFT);
                adicionarCelula(tabela, linha.getDescricao(), Element.ALIGN_LEFT);
                adicionarCelula(tabela, linha.getData(), Element.ALIGN_LEFT);
                adicionarCelula(tabela, formatarValor(linha.getValor()), Element.ALIGN_RIGHT);
            }

            documento.add(tabela);
            documento.close();
            return arquivo.toByteArray();
        } catch (DocumentException e) {
            throw new IllegalStateException("Não foi possível gerar o PDF.", e);
        } catch (Exception e) {
            throw new IllegalStateException("Não foi possível preparar o PDF.", e);
        }
    }

    private Font fonte(int tamanho, int estilo, Color cor) {
        return new Font(Font.HELVETICA, tamanho, estilo, cor);
    }

    private void adicionarCabecalho(PdfPTable tabela, String texto, int alinhamento) {
        PdfPCell celula = new PdfPCell(new Phrase(texto, fonte(9, Font.BOLD, Color.WHITE)));
        celula.setBackgroundColor(AZUL);
        celula.setHorizontalAlignment(alinhamento);
        celula.setPadding(6);
        celula.setBorderColor(AZUL);
        tabela.addCell(celula);
    }

    private void adicionarCelula(PdfPTable tabela, String texto, int alinhamento) {
        PdfPCell celula = new PdfPCell(new Phrase(texto == null ? "" : texto, fonte(9, Font.NORMAL, Color.DARK_GRAY)));
        celula.setBackgroundColor(CINZA_CLARO);
        celula.setHorizontalAlignment(alinhamento);
        celula.setPadding(6);
        celula.setBorderColor(Color.WHITE);
        tabela.addCell(celula);
    }

    private String formatarValor(BigDecimal valor) {
        return NumberFormat.getCurrencyInstance(BRASIL).format(valor == null ? BigDecimal.ZERO : valor);
    }
}

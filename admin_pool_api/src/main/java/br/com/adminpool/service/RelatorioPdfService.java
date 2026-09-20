package br.com.adminpool.service;

import br.com.adminpool.dto.LinhaRelatorioPdf;
import net.sf.jasperreports.engine.*;
import net.sf.jasperreports.engine.data.JRBeanCollectionDataSource;
import net.sf.jasperreports.engine.design.*;
import net.sf.jasperreports.engine.type.HorizontalTextAlignEnum;
import net.sf.jasperreports.engine.type.OrientationEnum;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class RelatorioPdfService {
    public byte[] gerar(String titulo, String filtros, List<LinhaRelatorioPdf> linhas) {
        try {
            JasperDesign design = new JasperDesign();
            design.setName("relatorio_admin_pool");
            design.setPageWidth(595);
            design.setPageHeight(842);
            design.setColumnWidth(515);
            design.setLeftMargin(40);
            design.setRightMargin(40);
            design.setTopMargin(35);
            design.setBottomMargin(35);
            design.setOrientation(OrientationEnum.PORTRAIT);
            for (String campo : List.of("cliente", "descricao", "data", "valor")) {
                JRDesignField field = new JRDesignField();
                field.setName(campo);
                field.setValueClass(campo.equals("valor") ? BigDecimal.class : String.class);
                design.addField(field);
            }
            JRDesignBand cabecalho = new JRDesignBand(); cabecalho.setHeight(75);
            cabecalho.addElement(text("Admin Pool", 0, 0, 515, 23, 18, true, Color.decode("#1565C0")));
            cabecalho.addElement(text(titulo, 0, 27, 515, 19, 14, true, Color.DARK_GRAY));
            cabecalho.addElement(text(filtros, 0, 49, 515, 16, 9, false, Color.DARK_GRAY));
            design.setTitle(cabecalho);
            JRDesignBand colunas = new JRDesignBand(); colunas.setHeight(22);
            int[] x = {0, 125, 350, 430}; int[] w = {125, 225, 80, 85};
            String[] nomes = {"CLIENTE", "DESCRIÇÃO", "DATA", "VALOR"};
            for (int i=0;i<nomes.length;i++) colunas.addElement(text(nomes[i], x[i], 2, w[i], 18, 9, true, Color.WHITE, Color.decode("#1565C0")));
            design.setColumnHeader(colunas);
            JRDesignBand detalhe = new JRDesignBand(); detalhe.setHeight(24);
            detalhe.addElement(field("cliente",0,3,125,18,9));
            detalhe.addElement(field("descricao",125,3,225,18,9));
            detalhe.addElement(field("data",350,3,80,18,9));
            JRDesignTextField valor = field("valor",430,3,85,18,9); valor.setPattern("R$ #,##0.00"); valor.setHorizontalTextAlign(HorizontalTextAlignEnum.RIGHT); detalhe.addElement(valor);
            ((JRDesignSection) design.getDetailSection()).addBand(detalhe);
            JasperPrint print = JasperFillManager.fillReport(JasperCompileManager.compileReport(design), new HashMap<>(), new JRBeanCollectionDataSource(linhas));
            return JasperExportManager.exportReportToPdf(print);
        } catch (JRException e) { throw new IllegalStateException("Não foi possível gerar o PDF.", e); }
    }
    private JRDesignStaticText text(String value,int x,int y,int w,int h,int size,boolean bold,Color color) { return text(value,x,y,w,h,size,bold,color,null); }
    private JRDesignStaticText text(String value,int x,int y,int w,int h,int size,boolean bold,Color color,Color fundo) { JRDesignStaticText t=new JRDesignStaticText(); t.setX(x);t.setY(y);t.setWidth(w);t.setHeight(h);t.setText(value);t.setFontSize((float)size);t.setBold(bold);t.setForecolor(color); if(fundo!=null){t.setBackcolor(fundo);t.setMode(net.sf.jasperreports.engine.type.ModeEnum.OPAQUE);} return t; }
    private JRDesignTextField field(String nome,int x,int y,int w,int h,int size) { JRDesignTextField t=new JRDesignTextField();t.setX(x);t.setY(y);t.setWidth(w);t.setHeight(h);t.setFontSize((float)size);t.setExpression(new JRDesignExpression("$F{"+nome+"}")); return t; }
}

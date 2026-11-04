import os
import re
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(
        f'<w:tcMar {nsdecls("w")}>'
        f'<w:top w:w="{top}" w:type="dxa"/>'
        f'<w:bottom w:w="{bottom}" w:type="dxa"/>'
        f'<w:left w:w="{left}" w:type="dxa"/>'
        f'<w:right w:w="{right}" w:type="dxa"/>'
        f'</w:tcMar>'
    )
    tcPr.append(tcMar)

def create_styled_document(md_path, docx_path):
    doc = Document()
    
    # Thiết lập lề trang tiêu chuẩn (1 inch = 2.54 cm)
    for section in doc.sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)
        section.different_first_page_header_footer = True
        
        # Header & Footer cho các trang sau
        header = section.header
        hp = header.paragraphs[0]
        hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        hrun = hp.add_run("Báo cáo Nâng cấp Cloud QLTLHT • Flutter - Firebase - Supabase")
        hrun.font.size = Pt(8.5)
        hrun.font.color.rgb = RGBColor(128, 128, 128)

        footer = section.footer
        fp = footer.paragraphs[0]
        fp.alignment = WD_ALIGN_PARAGRAPH.CENTER
        frun = fp.add_run("Hệ thống Quản lý Tài liệu Học tập Đa nền tảng")
        frun.font.size = Pt(8.5)
        frun.font.color.rgb = RGBColor(128, 128, 128)

    # Đọc nội dung markdown
    with open(md_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    in_code_block = False
    code_lang = ""
    code_lines = []
    
    in_table = False
    table_rows = []

    def flush_table():
        nonlocal in_table, table_rows
        if not table_rows:
            in_table = False
            return
        
        # Parse table cells
        parsed_rows = []
        for r in table_rows:
            # Bỏ qua separator row |:---|:---|
            if re.match(r'^\s*\|?\s*:?-+:?\s*\|', r):
                continue
            cells = [c.strip() for c in r.strip().strip('|').split('|')]
            if cells and any(cells):
                parsed_rows.append(cells)
                
        if not parsed_rows:
            in_table = False
            table_rows = []
            return

        col_count = max(len(row) for row in parsed_rows)
        table = doc.add_table(rows=len(parsed_rows), cols=col_count)
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        
        # Apply style
        for r_idx, row_data in enumerate(parsed_rows):
            is_header = (r_idx == 0)
            row = table.rows[r_idx]
            # Set cantSplit
            trPr = row._tr.get_or_add_trPr()
            trPr.append(parse_xml(f'<w:cantSplit {nsdecls("w")}/>'))
            
            for c_idx in range(col_count):
                cell = row.cells[c_idx]
                cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
                val = row_data[c_idx] if c_idx < len(row_data) else ""
                
                # Format cell text
                cell.text = ""
                p = cell.paragraphs[0]
                p.paragraph_format.space_before = Pt(3)
                p.paragraph_format.space_after = Pt(3)
                p.paragraph_format.line_spacing = 1.15
                
                run = p.add_run(val)
                run.font.name = 'Calibri'
                
                if is_header:
                    run.bold = True
                    run.font.size = Pt(9.5)
                    run.font.color.rgb = RGBColor(255, 255, 255)
                    set_cell_background(cell, "1F497D") # Navy blue header
                    set_cell_margins(cell, top=140, bottom=140, left=140, right=140)
                    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                else:
                    run.font.size = Pt(9)
                    run.font.color.rgb = RGBColor(30, 30, 30)
                    bg_color = "F2F5F9" if r_idx % 2 == 1 else "FFFFFF"
                    set_cell_background(cell, bg_color)
                    set_cell_margins(cell, top=100, bottom=100, left=140, right=140)
                    if c_idx == 0 or val in ["PASS", "FAIL"]:
                        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                        if val == "PASS":
                            run.bold = True
                            run.font.color.rgb = RGBColor(0, 128, 0)
                    else:
                        p.alignment = WD_ALIGN_PARAGRAPH.LEFT

        doc.add_paragraph() # Spacer
        table_rows = []
        in_table = False

    def flush_code():
        nonlocal in_code_block, code_lines, code_lang
        if not code_lines:
            in_code_block = False
            return
        
        code_text = "".join(code_lines).rstrip()
        
        # Tạo box chứa code (Table 1x1 bo viền, nền xám nhạt)
        tbl = doc.add_table(rows=1, cols=1)
        tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
        cell = tbl.cell(0, 0)
        set_cell_background(cell, "F4F6F9")
        set_cell_margins(cell, top=120, bottom=120, left=180, right=180)
        
        # Border xám
        tcPr = cell._tc.get_or_add_tcPr()
        borders = parse_xml(
            f'<w:tcBorders {nsdecls("w")}>'
            f'<w:top w:val="single" w:sz="6" w:space="0" w:color="D0D7DE"/>'
            f'<w:left w:val="single" w:sz="18" w:space="0" w:color="1F497D"/>'
            f'<w:bottom w:val="single" w:sz="6" w:space="0" w:color="D0D7DE"/>'
            f'<w:right w:val="single" w:sz="6" w:space="0" w:color="D0D7DE"/>'
            f'</w:tcBorders>'
        )
        tcPr.append(borders)
        
        cp = cell.paragraphs[0]
        cp.paragraph_format.space_before = Pt(2)
        cp.paragraph_format.space_after = Pt(2)
        cp.paragraph_format.line_spacing = 1.05
        
        crun = cp.add_run(code_text)
        crun.font.name = 'Consolas'
        crun.font.size = Pt(8.5)
        crun.font.color.rgb = RGBColor(36, 41, 47)
        
        doc.add_paragraph() # Spacer
        code_lines = []
        in_code_block = False

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Xử lý code blocks ```
        if stripped.startswith("```"):
            if in_code_block:
                flush_code()
            else:
                if in_table:
                    flush_table()
                in_code_block = True
                code_lang = stripped[3:].strip()
                code_lines = []
            i += 1
            continue

        if in_code_block:
            code_lines.append(line)
            i += 1
            continue

        # Xử lý bảng table
        if stripped.startswith("|") and stripped.endswith("|"):
            if not in_table:
                in_table = True
                table_rows = []
            table_rows.append(stripped)
            i += 1
            continue
        else:
            if in_table:
                flush_table()

        # Bỏ qua đường kẻ ngang ---
        if stripped.startswith("---"):
            i += 1
            continue

        # Headings
        if stripped.startswith("# "):
            title_text = stripped[2:].strip()
            p = doc.add_paragraph()
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p.paragraph_format.space_before = Pt(18)
            p.paragraph_format.space_after = Pt(8)
            run = p.add_run(title_text)
            run.font.name = 'Calibri'
            run.font.size = Pt(20)
            run.bold = True
            run.font.color.rgb = RGBColor(31, 73, 125) # Navy
            i += 1
            continue

        if stripped.startswith("## "):
            h2_text = stripped[3:].strip()
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(14)
            p.paragraph_format.space_after = Pt(6)
            run = p.add_run(h2_text)
            run.font.name = 'Calibri'
            run.font.size = Pt(14)
            run.bold = True
            run.font.color.rgb = RGBColor(27, 85, 155)
            i += 1
            continue

        if stripped.startswith("### "):
            h3_text = stripped[4:].strip()
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(10)
            p.paragraph_format.space_after = Pt(4)
            run = p.add_run(h3_text)
            run.font.name = 'Calibri'
            run.font.size = Pt(12)
            run.bold = True
            run.font.color.rgb = RGBColor(40, 110, 180)
            i += 1
            continue

        # Danh sách bullet / numbered
        if stripped.startswith("- ") or stripped.startswith("* "):
            item_text = stripped[2:].strip()
            p = doc.add_paragraph(style='List Bullet')
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            p.paragraph_format.line_spacing = 1.15
            
            # Xử lý bold trong text
            parts = re.split(r'(\*\*.*?\*\*)', item_text)
            for part in parts:
                if part.startswith('**') and part.endswith('**'):
                    r = p.add_run(part[2:-2])
                    r.bold = True
                else:
                    # Clean markdown links [text](url) -> text
                    clean_part = re.sub(r'\[(.*?)\]\(.*?\)', r'\1', part)
                    clean_part = clean_part.replace('`', '')
                    r = p.add_run(clean_part)
                r.font.name = 'Calibri'
                r.font.size = Pt(10.5)
            i += 1
            continue

        # Paragraph bình thường
        if stripped:
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(3)
            p.paragraph_format.space_after = Pt(4)
            p.paragraph_format.line_spacing = 1.2
            
            parts = re.split(r'(\*\*.*?\*\*)', stripped)
            for part in parts:
                if part.startswith('**') and part.endswith('**'):
                    r = p.add_run(part[2:-2])
                    r.bold = True
                else:
                    clean_part = re.sub(r'\[(.*?)\]\(.*?\)', r'\1', part)
                    clean_part = clean_part.replace('`', '')
                    r = p.add_run(clean_part)
                r.font.name = 'Calibri'
                r.font.size = Pt(10.5)
        
        i += 1

    if in_table:
        flush_table()
    if in_code_block:
        flush_code()

    doc.save(docx_path)
    print(f"Successfully generated DOCX at: {docx_path}")

if __name__ == "__main__":
    md_file = r"c:\Users\Admin\Desktop\code\android\QLTLHT\BAO_CAO_NANG_CAP_CLOUD_QLTLHT.md"
    docx_file = r"c:\Users\Admin\Desktop\code\android\QLTLHT\BAO_CAO_NANG_CAP_CLOUD_QLTLHT.docx"
    create_styled_document(md_file, docx_file)

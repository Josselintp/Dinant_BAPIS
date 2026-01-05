*&---------------------------------------------------------------------*
*& Report ZR_MM_MQA_D_DESCARGA_SALDOS
*&---------------------------------------------------------------------*
*& Descarga Saldos Centro y almacenes
*&---------------------------------------------------------------------*
REPORT zr_mm_mqa_d_descarga_saldos.
TABLES: t001w, mard, mara .

TYPE-POOLS: slis.
*Catalogo
DATA:    gt_fieldcat      TYPE  slis_t_fieldcat_alv.
DATA:    gs_fieldcat      TYPE slis_fieldcat_alv.
DATA:    gs_layout        TYPE slis_layout_alv.

CONSTANTS: lc_cantreg TYPE i VALUE 500000.
CONSTANTS: gc_v_serv_dir_mat_data TYPE tvarvc-name VALUE 'ZMM_RUTA_DIR_ARCH_DESC_MAT'.

DATA: gs_saldos TYPE zmm_s_mqa_descarga_saldos,
      lt_saldos TYPE TABLE OF zmm_s_mqa_descarga_saldos,
      ls_saldos TYPE zmm_s_mqa_descarga_saldos_01,
      gt_saldos TYPE TABLE OF zmm_s_mqa_descarga_saldos_01,
      gt_final  TYPE TABLE OF zmm_s_mqa_descarga_saldos_01.

TYPES: BEGIN OF gty_log.
         TYPES icon TYPE char4.
         INCLUDE TYPE zmm_s_mqa_descarga_saldos.
         TYPES texto TYPE char120.
TYPES: END OF gty_log.

DATA: ti_log TYPE TABLE OF gty_log,
      ls_log TYPE gty_log.

DATA: it_return TYPE TABLE OF bapiret2,
      ls_return TYPE bapiret2.

DATA: gv_fecha TYPE char8,
      gv_cont  TYPE i,
      gv_cntrg TYPE i.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS s_matnr FOR mard-matnr.
SELECT-OPTIONS s_werks FOR t001w-werks NO INTERVALS.
SELECT-OPTIONS s_lgort FOR mard-lgort NO INTERVALS.
PARAMETERS: p_meins TYPE MARA-meins.
*PARAMETERS: p_meins TYPE meins.
SELECTION-SCREEN SKIP 1.
PARAMETERS: p_file LIKE rlgrap-filename OBLIGATORY.
SELECTION-SCREEN SKIP 1.
PARAMETERS: p_chkbox AS CHECKBOX DEFAULT ''.
SELECTION-SCREEN END OF BLOCK b1.


INCLUDE zr_mm_mqa_d_desc_saldos_f01.

INITIALIZATION.
  SELECT SINGLE low INTO p_file FROM tvarvc WHERE name = gc_v_serv_dir_mat_data.

AT SELECTION-SCREEN OUTPUT.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  PERFORM f_abrir_ruta.

START-OF-SELECTION.
*--- si se encuentran datos se descarga la información
  PERFORM f_get_data.
  PERFORM validaciones_matnr.

  IF  gt_saldos[] IS NOT INITIAL.
    DATA(lv_no_lines) = lines( gt_saldos ).
    DATA(lv_resto) = lv_no_lines.

    IF ( lv_no_lines < lc_cantreg ). " Si la cant de registros no supera los 500000 registros
      ADD 1 TO gv_cont.
      gv_cntrg = lv_no_lines.
      gt_final[] = gt_saldos[].
      PERFORM f_dsc_file.

    ELSE." Si la cant de registros supera los 500000 registros
      LOOP AT gt_saldos INTO DATA(ls_reginf).
        DATA(lv_tabix) = sy-tabix.

        IF ( gv_cntrg = lc_cantreg ).

          ADD 1 TO gv_cont.
          PERFORM f_dsc_file.

          CLEAR gv_cntrg.
          lv_resto = lv_no_lines - lv_tabix.

          CLEAR gt_final.
          REFRESH gt_final.

          APPEND ls_saldos TO gt_final.
          gv_cntrg = gv_cntrg + 1.
        ELSE.
          IF lv_resto <= lc_cantreg.
            IF lv_resto EQ 1.
              APPEND ls_saldos TO gt_final.
              gv_cntrg = gv_cntrg + 1.

              ADD 1 TO gv_cont.
              PERFORM f_dsc_file.

              CLEAR gt_final.
              REFRESH gt_final.
            ELSE.
              APPEND ls_saldos TO gt_final.
              gv_cntrg = gv_cntrg + 1.
              lv_resto = lv_resto - 1.
            ENDIF.
          ELSE.
            APPEND ls_saldos TO gt_final.
            gv_cntrg = gv_cntrg + 1.
          ENDIF.
        ENDIF.
      ENDLOOP.

    ENDIF.
    IF p_chkbox EQ abap_true.
      PERFORM f_layout.
      PERFORM f_fieldcat.
      PERFORM f_call_alv.
    ENDIF.
  ELSE.
    MESSAGE 'No existen datos para su seleccion' TYPE 'I'.
    EXIT.
  ENDIF.


*INCLUDEE 

*&---------------------------------------------------------------------*
*&  Include           ZR_MM_MQA_D_DESC_REG_INFO_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form f_abrir_ruta
*&---------------------------------------------------------------------*
*& text Descarga Saldos Centro y almacenes
*&---------------------------------------------------------------------*
FORM f_abrir_ruta.
  DATA: lv_path         TYPE string.

  CALL METHOD cl_gui_frontend_services=>directory_browse
    EXPORTING
      window_title    = 'Seleccionar un directorio'
    CHANGING
      selected_folder = lv_path
    EXCEPTIONS
      OTHERS          = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
               RAISING error_with_gui.
  ENDIF.
  IF lv_path IS NOT INITIAL.
    CONCATENATE lv_path '\' INTO p_file.
  ENDIF.

ENDFORM.



*&---------------------------------------------------------------------*
*& Form f_get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM f_get_data.
*
  DATA pack_decimals TYPE p  DECIMALS 2.


  DATA: lt_eina TYPE TABLE OF eina,
        lt_eine TYPE TABLE OF eine,
        ls_eina TYPE eina,
        ls_eine TYPE eine.
  DATA: lv_lines TYPE i,
        l_subrc  TYPE sy-subrc.
  DATA: list_tab TYPE TABLE OF abaplist.
  DATA lit_string TYPE list_string_table.
  DATA: lv_string TYPE string,
        lt_split  TYPE TABLE OF char80.
  DATA  lv_num_output TYPE salk3.
  SUBMIT zrm07mlbs
    WITH matnr IN s_matnr
    WITH werks IN s_werks
    WITH lgort IN s_lgort
    WITH p_meins = p_meins
    WITH pa_sond = 'X'
    WITH nozero  = 'X'
    WITH pa_hsq  = ' '
   WITH pa_flt  = 'X'
    WITH p_vari  = '/MIGRACIÓN_V'    "'/MIGRACIÓN_V'
  EXPORTING LIST TO MEMORY
  AND RETURN.

  CALL FUNCTION 'LIST_FROM_MEMORY'
    TABLES
      listobject = list_tab
    EXCEPTIONS
      not_found  = 1
      OTHERS     = 2.

  CALL FUNCTION 'LIST_TO_ASCI'
    EXPORTING
      list_index         = -1
      with_line_break    = ' '
    IMPORTING
      list_string_ascii  = lit_string         "Screen Output/Readable Format
    TABLES
      listobject         = list_tab
    EXCEPTIONS
      empty_list         = 1
      list_index_invalid = 2
      OTHERS             = 3.

  LOOP AT lit_string INTO DATA(wa_data).
    IF sy-tabix > 3.
      CLEAR lt_split[].
      MOVE wa_data+1 TO lv_string .
      CONDENSE lv_string NO-GAPS.
      SPLIT lv_string AT '|' INTO TABLE lt_split.
      CLEAR l_subrc.
      READ TABLE lt_split INTO DATA(was) INDEX 1.
      PERFORM validar_matnr USING was CHANGING l_subrc.
      IF l_subrc = 4.
        EXIT.
      ENDIF.
      LOOP AT lt_split INTO DATA(wa).

        REPLACE ALL OCCURRENCES OF ',' IN wa WITH  ''.
        CASE sy-tabix.
          WHEN 1.
            gs_saldos-matnr = wa.
          WHEN 2.
            gs_saldos-werks = wa.
          WHEN 3.
            gs_saldos-lgort = wa.
          WHEN 4.
            gs_saldos-meins = wa.
          WHEN 5.
            SEARCH wa FOR ','.
*            IF sy-subrc EQ 0.
*              REPLACE ALL OCCURRENCES OF '.' IN wa WITH space.
*              REPLACE ALL OCCURRENCES OF ',' IN wa WITH  '.'.
*            ENDIF.
            gs_saldos-labst = wa.
          WHEN 6.
            SEARCH wa FOR ','.
*            IF sy-subrc EQ 0.
*              REPLACE ALL OCCURRENCES OF '.' IN wa WITH space.
*              REPLACE ALL OCCURRENCES OF ',' IN wa WITH  '.'.
*            ENDIF.
            gs_saldos-salk3 = wa.
          WHEN 7.
            gs_saldos-waers = wa.
          WHEN 8.
*             SEARCH wa FOR ','.
*            IF sy-subrc EQ 0.
*              REPLACE ALL OCCURRENCES OF '.' IN wa WITH space.
*              REPLACE ALL OCCURRENCES OF ',' IN wa WITH  '.'.
*            ENDIF.
            gs_saldos-speme = wa.
          WHEN 9.
            SEARCH wa FOR ','.
*            IF sy-subrc EQ 0.
*              REPLACE ALL OCCURRENCES OF '.' IN wa WITH space.
*              REPLACE ALL OCCURRENCES OF ',' IN wa WITH  '.'.
*            ENDIF.
            gs_saldos-salk4 = wa.
          WHEN 10.
            SEARCH wa FOR ','.
*             IF sy-subrc EQ 0.
*              REPLACE ALL OCCURRENCES OF '.' IN wa WITH space.
*              REPLACE ALL OCCURRENCES OF ',' IN wa WITH  '.'.
*            ENDIF.
            gs_saldos-insme = wa.
          WHEN 11.
*             SEARCH wa FOR ','.
*            IF sy-subrc EQ 0.
*              REPLACE ALL OCCURRENCES OF '.' IN wa WITH space.
*              REPLACE ALL OCCURRENCES OF ',' IN wa WITH  '.'.
*            ENDIF.
            gs_saldos-salk5 = wa.
          WHEN 12.
*             SEARCH wa FOR ','.
*             IF sy-subrc EQ 0.
*              REPLACE ALL OCCURRENCES OF '.' IN wa WITH space.
*              REPLACE ALL OCCURRENCES OF ',' IN wa WITH  '.'.
*            ENDIF.
            gs_saldos-retme = wa.
          WHEN 13.
*             SEARCH wa FOR ','.
*             IF sy-subrc EQ 0.
*              REPLACE ALL OCCURRENCES OF '.' IN wa WITH space.
*              REPLACE ALL OCCURRENCES OF ',' IN wa WITH  '.'.
*            ENDIF.
            gs_saldos-trauml = wa.
          WHEN 14.
            SEARCH wa FOR ','.
*            IF sy-subrc EQ 0.
*              REPLACE ALL OCCURRENCES OF '.' IN wa WITH space.
*              REPLACE ALL OCCURRENCES OF ',' IN wa WITH  '.'.
*            ENDIF.
            gs_saldos-salk6 = wa.
          WHEN 15.
*             SEARCH wa FOR ','.
*            IF sy-subrc EQ 0.
*              REPLACE ALL OCCURRENCES OF '.' IN wa WITH space.
*              REPLACE ALL OCCURRENCES OF ',' IN wa WITH  '.'.
*            ENDIF.
            gs_saldos-trame = wa.
          WHEN 16.
*             SEARCH wa FOR ','.
*            IF sy-subrc EQ 0.
*              REPLACE ALL OCCURRENCES OF '.' IN wa WITH space.
*              REPLACE ALL OCCURRENCES OF ',' IN wa WITH  '.'.
*            ENDIF.
            gs_saldos-salk7 = wa.
          WHEN 17.
*             SEARCH wa FOR ','.
*            IF sy-subrc EQ 0.
*              REPLACE ALL OCCURRENCES OF '.' IN wa WITH space.
*              REPLACE ALL OCCURRENCES OF ',' IN wa WITH  '.'.
*            ENDIF.
            gs_saldos-umlme = wa.
          WHEN 18.
*            SEARCH wa FOR ','.
*            IF sy-subrc EQ 0.
*              REPLACE ALL OCCURRENCES OF '.' IN wa WITH space.
*              REPLACE ALL OCCURRENCES OF ',' IN wa WITH  '.'.
*            ENDIF.
            gs_saldos-salk8 = wa.
          WHEN 19.
*            SEARCH wa FOR ','.
*            IF sy-subrc EQ 0.
*              REPLACE ALL OCCURRENCES OF '.' IN wa WITH space.
*              REPLACE ALL OCCURRENCES OF ',' IN wa WITH  '.'.
*            ENDIF.
            gs_saldos-qnty_open = wa.
        ENDCASE.
      ENDLOOP.
      APPEND gs_saldos TO lt_saldos.
    ENDIF.
  ENDLOOP.

  CALL FUNCTION 'LIST_FREE_MEMORY'.

ENDFORM.



*&---------------------------------------------------------------------*
*& Form f_dsc_file
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM f_dsc_file.
  CONSTANTS: lc_tabname TYPE tabname VALUE 'ZMM_S_MQA_DESCARGA_SALDOS_01',        " Tabla a listar
             c_t_salida TYPE tabname VALUE 'GT_FINAL'.   " Tabla de salida
  DATA: lc_tabint    TYPE tabname.
  FIELD-SYMBOLS: <fs_it>  TYPE STANDARD TABLE.

  DATA: lt_campos    TYPE STANDARD TABLE OF dd03l WITH HEADER LINE,
        lt_rollname  TYPE STANDARD TABLE OF dd04t WITH HEADER LINE,
        lt_cabeceras TYPE STANDARD TABLE OF fieldnames,
        wa_cabeceras TYPE fieldnames.
  DATA: lv_file          TYPE string,
        lv_xlsx          TYPE xstring,
        lv_encoding      TYPE abap_encoding,
        lv_cont          TYPE char2,
        lv_bytes_written TYPE i.

  lv_encoding = '4103'.

  lv_cont =  gv_cont.

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = lv_cont
    IMPORTING
      output = lv_cont.

  CONCATENATE p_file '/SALDOS_' s_werks-low '_' sy-datum+6(2) sy-datum+4(2) sy-datum(4) '_'  lv_cont INTO lv_file.
  CONDENSE lv_file.

  lc_tabint  = c_t_salida.
  ASSIGN (lc_tabint) TO <fs_it>.

  TRY.
      DATA(lo_excel) = NEW zcl_mm_utility_excel( ).
      DATA(lv_bytes) = lo_excel->download_xlsx( EXPORTING iv_file_path = |{ lv_file }.xlsx| ir_table = REF #( <fs_it> ) iv_server = abap_true ).
    CATCH zcx_mm_utility_excel INTO DATA(lx_err).
      MESSAGE lx_err->get_text( ) TYPE 'I' DISPLAY LIKE 'E'.
  ENDTRY.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.

    WRITE: /1 'Cant. Registros descargados:      ', gv_cntrg.
  ENDIF.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form f_layout
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM f_layout .
  CLEAR gs_layout.
  gs_layout-zebra             = 'X'.
  gs_layout-colwidth_optimize = 'X'.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form do_fieldcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM f_fieldcat .
  PERFORM f_append_fielcat USING 'ICON'  'Pos' abap_false  abap_false 10 abap_false.
  PERFORM f_append_fielcat USING 'MATNR' 'Número de material' abap_false abap_false 10 abap_false.
  PERFORM f_append_fielcat USING 'WERKS' 'Centro' abap_false  abap_false 6 abap_false.
  PERFORM f_append_fielcat USING 'LGORT' 'Almacén' abap_false  abap_false 8 abap_false.
  PERFORM f_append_fielcat USING 'MEINS' 'Unidad medida' abap_false  abap_false 6 abap_false.
  PERFORM f_append_fielcat USING 'LABST' 'Stock valorado de libre utilización' abap_false  abap_false 17 abap_false.
  PERFORM f_append_fielcat USING 'SALK3' 'Valor del stock valorado total' abap_false  abap_false 17 abap_false.
  PERFORM f_append_fielcat USING 'WAERS' 'Moneda' abap_false  abap_false 6 abap_false.
  PERFORM f_append_fielcat USING 'SPEME' 'Bloqueado' abap_false  abap_false 17 abap_false.
  PERFORM f_append_fielcat USING 'SALK4' 'Valor stock bloq.' abap_false  abap_false 10 abap_false.
  PERFORM f_append_fielcat USING 'INSME' 'En control calidad' abap_false  abap_false 10 abap_false.
  PERFORM f_append_fielcat USING 'SALK5' 'Valor en insp.cal.' abap_false  abap_false 10 abap_false.
  PERFORM f_append_fielcat USING 'RETME'  'Stock bloqueado de devoluciones' abap_false  abap_false 10 abap_false.
  PERFORM f_append_fielcat USING 'TRAUML' 'Trans./Trasl.' abap_false  abap_false 10 abap_false.
  PERFORM f_append_fielcat USING 'SALK6'  'Trans./Trasl.' abap_false  abap_false 10 abap_false.
  PERFORM f_append_fielcat USING 'TRAME'  'Stock en tránsito' abap_false  abap_false 10 abap_false.
  PERFORM f_append_fielcat USING 'SALK7'  'Valor tránsito' abap_false  abap_false 10 abap_false.
  PERFORM f_append_fielcat USING 'UMLME'  'En traslado' abap_false  abap_false 10 abap_false.
  PERFORM f_append_fielcat USING 'SALK8'  'Valor en traslado' abap_false  abap_false 10 abap_false.
  PERFORM f_append_fielcat USING 'QNTY_OPEN'  'Cant.Pendiente' abap_false  abap_false 10 abap_false.
  PERFORM f_append_fielcat USING 'TEXTO' 'Mensaje' abap_false  abap_false 100 abap_false.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form f_append_fielcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM f_append_fielcat USING p_fieldname p_seltext p_checkbox p_edit p_outputlen p_no_out.
  DATA ls_fieldcat TYPE slis_fieldcat_alv.

  CLEAR ls_fieldcat.

  ls_fieldcat-fieldname  = p_fieldname.
  ls_fieldcat-seltext_m  = p_seltext.
  ls_fieldcat-checkbox   = p_checkbox.
  ls_fieldcat-edit       = p_edit.
  ls_fieldcat-no_out     = p_no_out.
  IF p_outputlen IS NOT INITIAL.
    ls_fieldcat-outputlen = p_outputlen.
  ENDIF.
*  ls__fieldcat-emphasize = p_emphasize.
  APPEND ls_fieldcat TO gt_fieldcat.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form f_call_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM f_call_alv .
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program      = sy-repid
*     i_callback_top_of_page  = 'TOP_OF_PAGE'
      is_layout               = gs_layout
      it_fieldcat             = gt_fieldcat[]
*     i_callback_pf_status_set = 'SET_PF_STATUS'
      i_callback_user_command = 'F_USER_COMMAND'
    TABLES
      t_outtab                = ti_log[]
    EXCEPTIONS
      program_error           = 1
      OTHERS                  = 2.

ENDFORM.

FORM f_set_pf_status USING rt_extab TYPE slis_t_extab.
  SET PF-STATUS 'STANDARD'.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form f_user_command
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM f_user_command  USING r_ucomm LIKE sy-ucomm
                         rs_selfield TYPE slis_selfield.

  DATA ls_ref1 TYPE REF TO cl_gui_alv_grid .

  CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
    IMPORTING
      e_grid = ls_ref1.

  CALL METHOD ls_ref1->check_changed_data.

  rs_selfield-refresh    =  abap_true.
  rs_selfield-col_stable =  abap_true.
  rs_selfield-row_stable =  abap_true.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  VALIDAR_MATNR
*&---------------------------------------------------------------------*
*       Validar Material
*----------------------------------------------------------------------*
FORM validar_matnr  USING    p_matnr
                    CHANGING p_l_subrc.

  DATA l_matnr TYPE matnr.
  CLEAR l_matnr.
  CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
    EXPORTING
      input        = p_matnr
    IMPORTING
      output       = l_matnr
    EXCEPTIONS
      length_error = 1
      OTHERS       = 2.
  SELECT SINGLE matnr INTO @DATA(xmatnr) FROM mara WHERE matnr = @l_matnr.
  p_l_subrc = sy-subrc.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  VALIDACIONES_MATNR
*&---------------------------------------------------------------------*
*       Validaciones de Cantidades
*----------------------------------------------------------------------*
FORM validaciones_matnr .
  CHECK NOT lt_saldos[] IS INITIAL.
  DATA: l_uno(1), l_dos(1), l_tres(1), l_message(120).

  LOOP AT lt_saldos INTO gs_saldos.
    CLEAR: l_uno, l_dos, l_tres, l_message.
    IF gs_saldos-trauml = 0 AND
       gs_saldos-salk6  = 0 AND
       gs_saldos-trame  = 0 AND
       gs_saldos-salk7  = 0 AND
       gs_saldos-umlme  = 0 AND
       gs_saldos-salk8  = 0.
    ELSE.
      l_uno = 'X'.
    ENDIF.

    IF gs_saldos-retme  = 0.
    ELSE.
      l_dos = 'X'.
    ENDIF.

    SELECT COUNT(*)  FROM vbbe WHERE matnr EQ @gs_saldos-matnr
                                 AND werks EQ @gs_saldos-werks
                                 AND lgort EQ @gs_saldos-lgort
      INTO @DATA(intrecordcount).
    IF intrecordcount <> 0.
      l_tres = 'X'.
    ENDIF.

    IF l_uno = 'X' AND l_dos = ''.
      l_message = 'Inventario en Transito, no se puede realizar la descarga'.
      PERFORM generar_log_return USING gs_saldos l_message '1'.
    ELSEIF l_uno = '' AND l_dos = 'X'.
      l_message = 'Inventario en Devolución, no se puede realizar la descarga'.
      PERFORM generar_log_return USING gs_saldos l_message '2'.
    ELSEIF l_uno = 'X' AND l_dos = 'X'.
      l_message = 'Inventario en Transito y Devolución, no se puede realizar la descarga'.
      PERFORM generar_log_return USING gs_saldos l_message '3'.
    ELSEIF  l_tres = 'X'.
      l_message = 'Inventario Reservado, no se puede realizar la descarga'.
      PERFORM generar_log_return USING gs_saldos l_message '4'.
    ELSEIF l_uno = '' AND l_dos = '' AND l_tres = ''.
      MOVE-CORRESPONDING gs_saldos TO ls_saldos.
      APPEND ls_saldos TO gt_saldos.
    ENDIF.

    MOVE-CORRESPONDING gs_saldos TO ls_log.
    ls_log-texto = l_message.
    IF l_message IS INITIAL.
      ls_log-icon = '@08@'.
    ELSE.
      ls_log-icon = '@0A@'.
    ENDIF.
    APPEND ls_log TO ti_log.

  ENDLOOP.

  IF NOT it_return[] IS INITIAL.
    PERFORM f0100_crea_log.
    PERFORM mostrar_errores TABLES it_return.
    PERFORM f0700_resultado.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  printer_log_datos
*&---------------------------------------------------------------------*
*       Imprimir log de datos return
*----------------------------------------------------------------------*
FORM mostrar_errores TABLES p_return STRUCTURE bapiret2.
  DATA sg_log  TYPE bal_s_msg.
  " Generar Log de errores
  LOOP AT p_return INTO DATA(ls_mess).
    CLEAR sg_log.
    sg_log-msgty = ls_mess-type.
    sg_log-msgid = ls_mess-id.
    sg_log-msgno = ls_mess-number.
    sg_log-msgv1 = ls_mess-message_v1.
    sg_log-msgv2 = ls_mess-message_v2.
    sg_log-msgv3 = ls_mess-message_v3.
    sg_log-msgv4 = ls_mess-message_v4.
    sg_log-probclass = '1'.

    CALL FUNCTION 'BAL_LOG_MSG_ADD'
      EXPORTING
        i_s_msg       = sg_log
      EXCEPTIONS
        log_not_found = 0
        OTHERS        = 1.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid
      TYPE sy-msgty
      NUMBER sy-msgno
      WITH sy-msgv1
      sy-msgv2
      sy-msgv3
      sy-msgv4.
    ENDIF.
  ENDLOOP.


  CHECK 1 = 2.
  CALL FUNCTION 'FINB_BAPIRET2_DISPLAY'
    EXPORTING
      it_message = it_return.


  CALL FUNCTION 'RSCRMBW_DISPLAY_BAPIRET2'
    TABLES
      it_return = it_return.



  DATA: l_msg_str(100).
  LOOP AT it_return INTO ls_return.
    CALL FUNCTION 'FORMAT_MESSAGE'
      EXPORTING
        id        = ls_return-id
        lang      = sy-langu
        no        = ls_return-number
        v1        = ls_return-message_v1
        v2        = ls_return-message_v2
        v3        = ls_return-message_v3
        v4        = ls_return-message_v4
      IMPORTING
        msg       = l_msg_str   " Message text
      EXCEPTIONS
        not_found = 1
        OTHERS    = 2.
    WRITE:/ l_msg_str.
  ENDLOOP.
ENDFORM.                    " printer_log_datos



*&---------------------------------------------------------------------*
*&      Form  generar_log_return
*&---------------------------------------------------------------------*
*       Log de datos return
*----------------------------------------------------------------------*
FORM generar_log_return USING p_saldos TYPE zmm_s_mqa_descarga_saldos
                              p_message
                              p_valor.
  CLEAR ls_return.
  ls_return-type = 'E'.
  ls_return-id = 'MM'.
  ls_return-number = '899'.
  ls_return-message  = p_message.
  ls_return-message_v1 = p_saldos-matnr.
  ls_return-message_v2 = p_saldos-werks.
  CASE p_valor.
    WHEN '1'.
      CONCATENATE p_saldos-lgort p_message(23) INTO ls_return-message_v3 SEPARATED BY space.
      ls_return-message_v4 = p_message+24.
    WHEN '2'.
      CONCATENATE p_saldos-lgort p_message(25) INTO ls_return-message_v3 SEPARATED BY space.
      ls_return-message_v4 = p_message+26.
    WHEN '3'.
      CONCATENATE p_saldos-lgort p_message(36) INTO ls_return-message_v3 SEPARATED BY space.
      ls_return-message_v4 = p_message+37.
    WHEN '4'.
      CONCATENATE p_saldos-lgort p_message(21) INTO ls_return-message_v3 SEPARATED BY space.
      ls_return-message_v4 = p_message+22.
  ENDCASE.

  APPEND ls_return TO it_return.

ENDFORM.                    " generar_log_return


*&---------------------------------------------------------------------*
*& Form F0100_CREA_LOG
*&---------------------------------------------------------------------*
*& Log
*&---------------------------------------------------------------------*
FORM f0100_crea_log .
  DATA: vg_flag(1),
        sg_cab  TYPE bal_s_log.

  vg_flag = abap_true.
  sg_cab-extnumber = 'Descarga de Saldos'.
  sg_cab-aluser    = sy-uname.
  sg_cab-alprog    = sy-repid.

  CALL FUNCTION 'BAL_LOG_CREATE'
    EXPORTING
      i_s_log = sg_cab
    EXCEPTIONS
      OTHERS  = 1.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid
    TYPE sy-msgty
    NUMBER sy-msgno
    WITH sy-msgv1
    sy-msgv2
    sy-msgv3
    sy-msgv4.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form f0500_resultado
*&---------------------------------------------------------------------*
*       Presenta el Log
*----------------------------------------------------------------------*
FORM f0700_resultado.
  DATA: sl_filter TYPE bal_s_lfil,
        sl_ext    TYPE bal_s_extn.
  " Mostrar Log de Errores
  sl_ext-sign   = 'I'.
  sl_ext-option = 'EQ'.
  sl_ext-low    = 'Descarga de Saldos'.
  APPEND sl_ext TO sl_filter-extnumber.

  CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
    EXPORTING
      i_s_log_filter       = sl_filter
    EXCEPTIONS
      profile_inconsistent = 1
      internal_error       = 2
      no_data_available    = 3
      no_authority         = 4
      OTHERS               = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid
    TYPE sy-msgty
    NUMBER sy-msgno
    WITH sy-msgv1
    sy-msgv2
    sy-msgv3
    sy-msgv4.
  ENDIF.

ENDFORM.


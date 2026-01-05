*&---------------------------------------------------------------------*
*& Report ZR_MM_MQA_U_DESCARGA_REG_INFO
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
*                       LOG DE MODIFICACIONES                          *
*----------------------------------------------------------------------*
* Modifcado por    : Nombre completo del programador y USUARIO.        *
* N° Requerimiento : Número del requerimiento.                         *
* ID del cambio    : ID del pedido cambio.                             *
* Fecha del cambio : Fecha del cambio en formato AAAA.MM.DD            *
* Descripción      : Descripción breve del cambio.                     *
* Transporte       : ID de Transporte contenedor del cambio.           *
*&---------------------------------------------------------------------*
* Modifcado por    : Daniel Ramos USUARIO: ATRAVA01                    *
* N° Requerimiento : DINA-MM06                                         *
* ID del cambio    :                                                   *
* Fecha del cambio : 2025.11.04                                        *
* Descripción      : Ajuste para que el archivo de carga no se lea     *
*                    desde la PC del usuario, sino desde el servidor de*
*                    aplicación SAP.                                   *
* Etiqueta         : FILE_SERV                                         *
* Transporte       :                                                   *
*&---------------------------------------------------------------------*
REPORT zr_mm_mqa_u_descarga_saldos.
TYPE-POOLS: slis.
TYPES:
  BEGIN OF ty_log,
    icon    TYPE icon-id,
    type(1) TYPE c,
    number  TYPE symsgno,
    clase   TYPE symsgid,
    message TYPE string,
  END OF ty_log,
  ty_t_log TYPE TABLE OF ty_log.
*Catalogo
DATA: gt_fieldcat      TYPE slis_t_fieldcat_alv.
DATA: gs_fieldcat      TYPE slis_fieldcat_alv.
DATA: gs_layout        TYPE slis_layout_alv.

DATA: gs_regsld TYPE zest_mm_carg_desc_saldo_2,
      gs_log    TYPE ty_log, "bapiret2,
      gt_regsld TYPE TABLE OF zest_mm_carg_desc_saldo_2.
DATA: lt_data TYPE TABLE OF zest_mm_carg_desc_saldo_2,
      ls_data TYPE zest_mm_carg_desc_saldo_2.

DATA: gs_goodsmvt_header TYPE bapi2017_gm_head_01,
      gs_goodsmvt_code   TYPE bapi2017_gm_code,
      gs_goodsmvt_item   TYPE bapi2017_gm_item_create,
      gt_items           TYPE TABLE OF bapi2017_gm_item_create,
      gs_items           TYPE bapi2017_gm_item_create,
      i_fltp_value       TYPE cha_class_data-sollwert,
      e_char_field       TYPE cha_class_view-sollwert,
      gt_log             TYPE ty_t_log.


DATA: gv_fecha TYPE char8,
      gv_cont  TYPE n.
DATA lv_filename      TYPE string.

TYPES: BEGIN OF gty_sal.
         INCLUDE TYPE salfldir.
         TYPES: fecha TYPE sy-datum,
         horat TYPE char8.
TYPES: borra TYPE xfeld.
TYPES END OF gty_sal.

DATA: it_filedoc TYPE TABLE OF gty_sal.
DATA: it_filedir TYPE TABLE OF salfldir.
DATA: BEGIN OF it_match OCCURS 0,
        shlpname  TYPE ddshretval-shlpname,
        fieldname TYPE ddshretval-fieldname,
        recordpos TYPE ddshretval-recordpos,
        fieldval  TYPE ddshretval-fieldval,
        retfield  TYPE ddshretval-retfield,
      END OF it_match.

CONSTANTS: c_fs_wa      TYPE lvc_fname VALUE '-',
           c_ext_xls    TYPE string    VALUE '*.xls',
           gc_05        TYPE bapi2017_gm_code-gm_code VALUE '05',
           gc_move_type TYPE bapi2017_gm_item_create-move_type VALUE '561',
           gc_i(1)      TYPE c VALUE 'I',
           gc_mm        TYPE bapiret2-id VALUE 'MM',
           gc_899       TYPE bapiret2-number VALUE '899',
           gc_cantreg   TYPE i VALUE 999.
CONSTANTS: gc_v_serv_dir_mat_data TYPE tvarvc-name VALUE 'ZMM_RUTA_DIR_ARCH_DESC_IM'.


FIELD-SYMBOLS: <gt_excel> TYPE STANDARD TABLE.
FIELD-SYMBOLS: <lv_field> TYPE any.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
SELECTION-SCREEN SKIP 1.
PARAMETERS: p_file LIKE rlgrap-filename OBLIGATORY.
PARAMETERS p_fecha TYPE BUDAT.
SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  SELECT SINGLE low INTO p_file FROM tvarvc WHERE name = gc_v_serv_dir_mat_data."Etiqueda ajuste FILE_SERV: Se agrega

AT SELECTION-SCREEN OUTPUT.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.

  PERFORM f4_open_file_serv. "Etiqueda ajuste FILE_SERV: Se agrega

START-OF-SELECTION.
  PERFORM progress_indicator USING 0 'Inciando...'.
  lv_filename = p_file.

  PERFORM upload_excel_server_v2. "Etiqueda ajuste FILE_SERV: Se agrega

  PERFORM f_cargar_data.
  PERFORM f_crear_saldos.


  IF gt_log IS NOT INITIAL.
    PERFORM crea_y_muestra_log.

  ENDIF.

FORM f4_open_file.


  DATA it_files TYPE filetable.
  DATA rc TYPE i.
  DATA action TYPE i.

  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
      initial_directory       = ''
      file_filter             = |xlsx (*.xlsx)\|*.xlsx\|{ cl_gui_frontend_services=>filetype_all }|
    CHANGING
      file_table              = it_files
      rc                      = rc
      user_action             = action
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5 ##SUBRC_OK
  ).
  IF action = cl_gui_frontend_services=>action_ok.
    IF lines( it_files ) > 0.
      p_file = it_files[ 1 ]-filename.
    ENDIF.
  ENDIF.

ENDFORM.                    " F4_OPEN_FILE


FORM f_upload_excel_to_itab.

  DATA lo_excel_ref TYPE REF TO cl_fdt_xl_spreadsheet.
  DATA : lv_filename      TYPE string,
         lt_records       TYPE solix_tab,
         lv_headerxstring TYPE xstring,
         lv_filelength    TYPE i,
         lt_worksheet     TYPE stringtab.

  lv_filename = p_file.

  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename                = lv_filename
      filetype                = 'BIN'
    IMPORTING
      filelength              = lv_filelength
      header                  = lv_headerxstring
    TABLES
      data_tab                = lt_records
    EXCEPTIONS
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      header_not_allowed      = 9
      separator_not_allowed   = 10
      header_too_long         = 11
      unknown_dp_error        = 12
      access_denied           = 13
      dp_out_of_memory        = 14
      disk_full               = 15
      dp_timeout              = 16
      OTHERS                  = 17.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    EXIT.
  ENDIF.
  "convert binary data to xstring
  "if you are using cl_fdt_xl_spreadsheet in odata then skips this step
  "as excel file will already be in xstring

  PERFORM progress_indicator USING 5 'Transferir datos de EXCEL...'.

  IF lt_records IS NOT INITIAL.

    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = lv_filelength
      IMPORTING
        buffer       = lv_headerxstring
      TABLES
        binary_tab   = lt_records
      EXCEPTIONS
        failed       = 1
        OTHERS       = 2.

    TRY.
        CREATE OBJECT lo_excel_ref
          EXPORTING
            document_name = lv_filename
            xdocument     = lv_headerxstring.
      CATCH cx_fdt_excel_core.
        RETURN.
    ENDTRY .
    lo_excel_ref->if_fdt_doc_spreadsheet~get_worksheet_names(
      IMPORTING
        worksheet_names = lt_worksheet ).
    IF lt_worksheet IS NOT INITIAL.
      READ TABLE lt_worksheet INTO DATA(lw_excel)
      INDEX 1.
      DATA(lo_data_ref) = lo_excel_ref->if_fdt_doc_spreadsheet~get_itab_from_worksheet(
        worksheet_name = lw_excel ).
      ASSIGN lo_data_ref->* TO <gt_excel>.
    ENDIF.
  ENDIF.

ENDFORM.                    " UPLOAD_EXCEL_TO_ITAB


FORM f_crear_saldos.
  DATA: lv_counter            TYPE i,
        lt_return             TYPE TABLE OF bapiret2,
        gm_headret            TYPE bapi2017_gm_head_ret,
        gm_retmtd             TYPE bapi2017_gm_head_ret-mat_doc,
        gv_documento_material TYPE bapi2017_gm_head_ret-mat_doc.

  FIELD-SYMBOLS: <fs_item> TYPE bapi2017_gm_item_create.

  PERFORM progress_indicator USING 40 'Generar datos para registro saldos Centro y almacenes'.

  DATA(lv_no_lines) = lines( gt_regsld ).
  DATA(lv_resto) = lv_no_lines.
*  TRY .
  DATA(ls_cab) = gt_regsld[ 1 ].
  DATA       lv_longitud TYPE i.

  gs_goodsmvt_header-pstng_date     =  p_fecha . "sy-datum.  "FECHA DEL PARAMETRO DE ENTRADA
  gs_goodsmvt_header-doc_date       = p_fecha .  "sy-datum.    "FECHA DEL PARAMETRO DE ENTRADA
*      GS_GOODSMVT_HEADER-HEADER_TXT     = LS_CAB-BKTXT.
  gs_goodsmvt_code-gm_code = gc_05.

*  IF ( lv_no_lines <= gc_cantreg ). " Si la cant de registros no supera los 500000 registros
  LOOP AT gt_regsld INTO DATA(ls_regsld).

    gs_items-material = ls_regsld-matnr .

    gs_items-material = |{ gs_items-material  ALPHA = IN }|.
    lv_longitud = strlen( ls_regsld-matnr ).
    gs_items-plant    = ls_regsld-werks .
    gs_items-stge_loc = ls_regsld-lgort .

    SELECT SINGLE * INTO @DATA(ls_mara)
      FROM mara
      WHERE  matnr  =  @gs_items-material .

    SELECT SINGLE * INTO @DATA(ls_t134h)
       FROM  t134h
      WHERE  bwkey =  @gs_items-plant
      AND    spart = @ls_mara-spart .

    gs_items-tr_part_ba = ls_t134h-gsber.        .
    gs_items-move_type = gc_move_type  .

    CALL FUNCTION 'CONVERSION_EXIT_CUNIT_INPUT'
      EXPORTING
        input    = ls_regsld-erfme
        language = sy-langu
      IMPORTING
        output   = gs_items-entry_uom.
    IF sy-subrc <> 0.

    ENDIF.


    IF ls_regsld-erfmg NE 0 .
      gs_items-stck_type  = ' '.
      gs_items-entry_qnt = ls_regsld-erfmg.
      IF ls_regsld-exbwr NE 0 .
        gs_items-stck_type = ' '.
        gs_items-amount_lc  = ls_regsld-exbwr.
      ENDIF.
      APPEND gs_items  TO gt_items.
    ENDIF.


    IF ls_regsld-bloqueado NE 0 .
      gs_items-stck_type = '3' .
      gs_items-entry_qnt = ls_regsld-bloqueado.
       gs_items-amount_lc  = ' ' .
      IF ls_regsld-valtotalb NE 0 .
        gs_items-stck_type = '3'.
       gs_items-amount_lc  = ls_regsld-valtotalb. .

      ENDIF.
      APPEND gs_items  TO gt_items.
    ENDIF.
    IF ls_regsld-controlqa NE 0 .
      gs_items-stck_type = 'X'.
      gs_items-entry_qnt =  ls_regsld-controlqa.
      IF ls_regsld-valtotalqa NE 0 .
        gs_items-stck_type = 'X'.
        gs_items-amount_lc  =  ls_regsld-valtotalqa .

      ENDIF.
      APPEND gs_items  TO gt_items.
    ENDIF.

    lv_counter = lv_counter + 1.
    CLEAR: gs_items, ls_regsld.
  ENDLOOP.
 CLEAR: gs_items,



         lt_return[]."Etiqueta ajuste FILE_SERV: Se agrega
  " Llamar BAPI con el bloque de 999
  CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
    EXPORTING
      goodsmvt_header  = gs_goodsmvt_header
      goodsmvt_code    = gs_goodsmvt_code
    IMPORTING
      goodsmvt_headret = gm_headret
      materialdocument = gm_retmtd
    TABLES
      goodsmvt_item    = gt_items
      return           = lt_return.
*
  IF lt_return[] IS INITIAL.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.

    PERFORM message USING gc_i gc_mm gc_899 gm_retmtd space space space.

  ELSE.

    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

    PERFORM messages_table USING lt_return.

  ENDIF.

***        " Limpiar para siguiente bloque
**        CLEAR: gt_items, lv_counter.
**      ELSE.
**        LOOP AT gt_regsld INTO ls_regsld.
**
**          APPEND VALUE #( material = ls_regsld-matnr
**                          plant    = ls_regsld-werks
**                          stge_loc = ls_regsld-lgort
**                          move_type = gc_move_type
***                          BATCH = LS_REGSLD-CHARG
**                          entry_qnt = ls_regsld-erfmg
**                          entry_uom = ls_regsld-erfme
***                          EXPIRYDATE = LS_REGSLD-VFDAT
**                          amount_lc  = ls_regsld-exbwr ) TO gt_items.
**
**          lv_counter = lv_counter + 1.
**
**          IF lv_counter = gc_cantreg AND lv_no_lines > gc_cantreg.
**            " Llamar BAPI con el bloque de 999
**            lv_no_lines = lv_no_lines - gc_cantreg.
**            CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
**              EXPORTING
**                goodsmvt_header  = gs_goodsmvt_header
**                goodsmvt_code    = gs_goodsmvt_code
**              IMPORTING
**                goodsmvt_headret = gm_headret
**                materialdocument = gm_retmtd
**              TABLES
**                goodsmvt_item    = gt_items
**                return           = lt_return.
***
**            IF lt_return[] IS INITIAL.
**
**              CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
**                EXPORTING
**                  wait = abap_true.
**
**              PERFORM message USING gc_i gc_mm gc_899 gm_retmtd space space space.
**
**            ELSE.
**
**              CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
**
**              PERFORM messages_table USING lt_return.
**
**            ENDIF.
**
**            " Limpiar para siguiente bloque
**            CLEAR: gt_items, lv_counter.
**            REFRESH gt_items.
**          ELSEIF lv_no_lines = lv_counter AND lv_no_lines <= gc_cantreg.
**            CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
**              EXPORTING
**                goodsmvt_header  = gs_goodsmvt_header
**                goodsmvt_code    = gs_goodsmvt_code
**              IMPORTING
**                goodsmvt_headret = gm_headret
**                materialdocument = gm_retmtd
**              TABLES
**                goodsmvt_item    = gt_items
**                return           = lt_return.
***
**            IF lt_return[] IS INITIAL.
**
**              CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
**                EXPORTING
**                  wait = abap_true.
**
**              PERFORM message USING gc_i gc_mm gc_899 gm_retmtd space space space.
**
**            ELSE.
**
**              CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
**
**              PERFORM messages_table USING lt_return.
**
**            ENDIF.
*  ENDIF.
**
**        ENDLOOP.
**      ENDIF.
**    CATCH cx_sy_itab_line_not_found.
**      MESSAGE 'Read failed' TYPE 'E'.
*  ENDTRY.

  PERFORM progress_indicator USING 100 'Final de registro saldos Centro y almacenes...'.

ENDFORM.

FORM f_cargar_data.
  DATA : lv_id    TYPE i,
         lv_cnt   TYPE i,
         lv_fill  TYPE string,
         lv_campo TYPE string.

  PERFORM progress_indicator USING 10 'Transferir datos a tabla interna...'.



  lv_cnt = 12. " Cantidad de columnas del reporte
  LOOP AT <gt_excel> ASSIGNING FIELD-SYMBOL(<lw_file>).
    IF sy-tabix <= 1.
      CONTINUE.
    ENDIF.
    ASSIGN COMPONENT 'A' OF STRUCTURE <lw_file> TO FIELD-SYMBOL(<a>).
    CHECK <a> IS NOT INITIAL.
    lv_id = lv_id + 1.

    APPEND INITIAL LINE TO gt_regsld ASSIGNING FIELD-SYMBOL(<lw_excel>).
*    <lw_excel>-id = lv_id.
*    <lw_excel>-icono = icon_light_out.
    DO lv_cnt TIMES.
      ASSIGN COMPONENT sy-index OF STRUCTURE <lw_file> TO <lv_field>.
      IF sy-subrc EQ 0.
        CASE sy-index.

          WHEN 1.   MOVE <lv_field> TO <lw_excel>-matnr.
          WHEN 2.   MOVE <lv_field> TO <lw_excel>-werks.
          WHEN 3.   MOVE <lv_field> TO <lw_excel>-lgort.
          WHEN 4.   MOVE <lv_field> TO <lw_excel>-erfme.
          WHEN 5.
            MOVE <lv_field> TO i_fltp_value.
            CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
              EXPORTING
                i_number_of_digits       = '3'
                i_fltp_value             = i_fltp_value
                i_value_not_initial_flag = 'X'
                i_screen_fieldlength     = 16
              IMPORTING
                e_char_field             = e_char_field.
            REPLACE ALL OCCURRENCES OF ',' IN e_char_field WITH '.'.
            CONDENSE e_char_field NO-GAPS.
            MOVE e_char_field   TO <lw_excel>-erfmg.
          WHEN 6.
            MOVE <lv_field> TO i_fltp_value.
            CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
              EXPORTING
                i_number_of_digits       = '3'
                i_fltp_value             = i_fltp_value
                i_value_not_initial_flag = 'X'
                i_screen_fieldlength     = 16
              IMPORTING
                e_char_field             = e_char_field.
            REPLACE ALL OCCURRENCES OF ',' IN e_char_field WITH '.'.
            CONDENSE e_char_field NO-GAPS.
            MOVE e_char_field   TO <lw_excel>-exbwr.
          WHEN 7.
            MOVE <lv_field> TO <lw_excel>-waers.
          WHEN 8.
            MOVE <lv_field> TO i_fltp_value.
            CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
              EXPORTING
                i_number_of_digits       = '3'
                i_fltp_value             = i_fltp_value
                i_value_not_initial_flag = 'X'
                i_screen_fieldlength     = 16
              IMPORTING
                e_char_field             = e_char_field.
            REPLACE ALL OCCURRENCES OF ',' IN e_char_field WITH '.'.
            CONDENSE e_char_field NO-GAPS.
            MOVE e_char_field   TO <lw_excel>-bloqueado.
          WHEN 9.
            MOVE <lv_field> TO i_fltp_value.

            CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
              EXPORTING
                i_number_of_digits       = '3'
                i_fltp_value             = i_fltp_value
                i_value_not_initial_flag = 'X'
                i_screen_fieldlength     = 16
              IMPORTING
                e_char_field             = e_char_field.
            REPLACE ALL OCCURRENCES OF ',' IN e_char_field WITH '.'.
            CONDENSE e_char_field NO-GAPS.
            MOVE e_char_field   TO  <lw_excel>-valtotalb..
          WHEN 10.
            MOVE <lv_field> TO i_fltp_value.
            CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
              EXPORTING
                i_number_of_digits       = '3'
                i_fltp_value             = i_fltp_value
                i_value_not_initial_flag = 'X'
                i_screen_fieldlength     = 16
              IMPORTING
                e_char_field             = e_char_field.
            REPLACE ALL OCCURRENCES OF ',' IN e_char_field WITH '.'.
            CONDENSE e_char_field NO-GAPS.
            MOVE e_char_field   TO  <lw_excel>-controlqa.
          WHEN 11.
            MOVE <lv_field> TO i_fltp_value.
            CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
              EXPORTING
                i_number_of_digits       = '3'
                i_fltp_value             = i_fltp_value
                i_value_not_initial_flag = 'X'
                i_screen_fieldlength     = 16
              IMPORTING
                e_char_field             = e_char_field.
            REPLACE ALL OCCURRENCES OF ',' IN e_char_field WITH '.'.
            CONDENSE e_char_field NO-GAPS.
            MOVE e_char_field   TO   <lw_excel>-valtotalqa.

          WHEN 12.  MOVE <lv_field> TO <lw_excel>-cantidad.

        ENDCASE.
      ENDIF.
    ENDDO.
  ENDLOOP.
*****  PERFORM PROGRESS_INDICATOR USING 30 'final de Transferir datos a tabla interna...'.
ENDFORM.
FORM progress_indicator USING percent message.
  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
    EXPORTING
      percentage = percent
      text       = message.
ENDFORM.


FORM message  USING iv_type TYPE bapi_mtype
                    iv_id TYPE symsgid
                    iv_number TYPE symsgno
                    iv_msgv1 TYPE any
                    iv_msgv2 TYPE any
                    iv_msgv3 TYPE any
                    iv_msgv4 TYPE any.

  IF iv_type EQ 'S'.
    gs_log-icon   = '@08@'.
  ELSEIF iv_type EQ 'E'.
    gs_log-icon    = '@0A@'.
  ELSE.
    gs_log-icon   = '@09@'.
  ENDIF.

  gs_log-type =  iv_type .

  gs_log-number = iv_number.

  MESSAGE ID iv_id TYPE iv_type
          NUMBER iv_number
          WITH iv_msgv1 iv_msgv2 iv_msgv3 iv_msgv4
               INTO gs_log-message.

  APPEND gs_log TO gt_log.

ENDFORM.                    " MESSAGE
*&---------------------------------------------------------------------*
*&      Form  MESSAGES_TABLE
*&---------------------------------------------------------------------*
*       Subrutina para pasar toda la tabla de mensajes al log
*----------------------------------------------------------------------*
*      -->P_gt_return  text
*----------------------------------------------------------------------*
FORM messages_table  USING    p_gt_return TYPE ANY TABLE.
  DATA:
    s_return TYPE bapiret2,
    s_log    TYPE REF TO data,
    lv_id    TYPE symsgid,
    lv_msgno TYPE symsgno,
    lv_type  TYPE bapi_mtype,
    lv_v1    TYPE symsgv,
    lv_v2    TYPE symsgv,
    lv_v3    TYPE symsgv,
    lv_v4    TYPE symsgv.

  LOOP AT p_gt_return INTO s_return.

    CLEAR: gs_log. "Etiqueta ajuste FILE_SERV: Se agrega

    IF s_return-type EQ 'S'.
      gs_log-icon   = '@08@'.
    ELSEIF s_return-type EQ 'E'.
      gs_log-icon    = '@0A@'.
    ELSE.
      gs_log-icon   = '@09@'.
    ENDIF.

    gs_log-type = s_return-type.

    gs_log-number = s_return-number.

    IF NOT s_return-message IS INITIAL.
      gs_log-message = s_return-message.
    ELSE.

      MESSAGE ID s_return-id TYPE s_return-type
              NUMBER s_return-number
              WITH s_return-message_v1 s_return-message_v2
                   s_return-message_v3 s_return-message_v4
                   INTO gs_log-message.

    ENDIF.
*    ENDIF.
    APPEND gs_log TO gt_log.
*    me->singleton( EXPORTING is_append_log = s_log ).

  ENDLOOP.
*  CALL METHOD o_log->parse_bapi
*    EXPORTING
*      t_return          = p_gt_return
*    EXCEPTIONS
*      icon_not_supplied = 1
*      text_not_supplied = 2
*      OTHERS            = 3.
*  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*  ENDIF.

ENDFORM.                    " MESSAGES_TABLE
*&---------------------------------------------------------------------*
*&      Form  CREA_Y_MUESTRA_LOG
*&---------------------------------------------------------------------*
*       Subrutina para pasar los mensajes y mostrar el log
*----------------------------------------------------------------------*
FORM crea_y_muestra_log .
  DATA: lo_table     TYPE REF TO cl_salv_table,
        lo_functions TYPE REF TO cl_salv_functions_list,
        lo_columns   TYPE REF TO cl_salv_columns_table,
        lo_column    TYPE REF TO cl_salv_column_table,
*        obj_alv_table TYPE REF TO cl_salv_table,
        gr_display   TYPE REF TO cl_salv_display_settings.

  cl_salv_table=>factory( IMPORTING r_salv_table = lo_table
                          CHANGING t_table = gt_log ).

  gr_display = lo_table->get_display_settings( ).
  gr_display->set_list_header( 'Mensajes resultantes' ).

  TRY .

      lo_columns = lo_table->get_columns( ).
      lo_column ?= lo_columns->get_column( 'ICONO' ).
      lo_column->set_long_text( 'Icono' ).
      lo_column->set_medium_text( 'Icono' ).
      lo_column->set_short_text( 'Icono' ).

      lo_columns = lo_table->get_columns( ).
      lo_column ?= lo_columns->get_column( 'MENSAJE' ).
      lo_column->set_long_text( 'Mensaje' ).
      lo_column->set_medium_text( 'Mensaje' ).
      lo_column->set_short_text( 'Mensaje' ).
      lo_columns->set_optimize( abap_true ).

    CATCH  cx_salv_not_found.
  ENDTRY.


*  lo_columns = lo_table->get_columns( ).
  lo_columns->set_optimize( abap_true ).
  lo_functions = lo_table->get_functions( ).
  lo_functions->set_all( ).

  lo_table->set_screen_status(
              pfstatus = 'ZSTATUS_GUI'
              report = sy-repid
              set_functions = lo_table->c_functions_all ).

  lo_table->display( ).

ENDFORM.                    " CREA_Y_MUESTRA_LOG
FORM f_fecha_value USING lv_external_date TYPE string
                 CHANGING cv_date TYPE sy-datum.
*  REPLACE '.' WITH '' INTO fecha_in.
*  REPLACE '.' WITH '' INTO fecha_in.
*  REPLACE '/' WITH '' INTO fecha_in.
*  REPLACE '/' WITH '' INTO fecha_in.
*  REPLACE '-' WITH '' INTO fecha_in.
*  REPLACE '-' WITH '' INTO fecha_in.
*
*  CONDENSE fecha_in NO-GAPS.
*  MOVE fecha_in TO fecha_out.
*  SHIFT fecha_in RIGHT DELETING TRAILING space.
*  OVERLAY fecha_out WITH '00000000'.
*  CONCATENATE fecha_out+4(4) fecha_out+2(2) fecha_out(2) INTO fecha_in.

  DATA: lv_day   TYPE string,
        lv_month TYPE string,
        lv_year  TYPE string.

*lv_external_date = '05/05/2025'. " Puedes cambiarlo a cualquier otro: '05.05.2025', '12/31/2024', etc.

  " Detectar separador
  DATA(lv_sep) = COND string(
    WHEN lv_external_date CP '*.*' THEN '.'
    WHEN lv_external_date CP '*/?/*' THEN '/'
    ELSE '' ).

  IF lv_sep IS INITIAL.
    WRITE: / 'Formato no reconocido'.
    EXIT.
  ENDIF.

  " Dividir fecha en partes
  SPLIT lv_external_date AT lv_sep INTO lv_day lv_month lv_year.

  " Detectar si el primer número es día o mes
  IF lv_day > '12'. " Supone que si >12, es día (no mes)
    " Formato tipo DD/MM/YYYY o DD.MM.YYYY
    cv_date = |{ lv_year }{ lv_month }{ lv_day }|.
  ELSE.
    " Ambiguo: puede ser MM/DD/YYYY o DD/MM/YYYY
    " Aquí puedes usar una regla de negocio o una variable de configuración para decidir
    " Por ejemplo, asumamos MM/DD/YYYY si día <= 12
    cv_date = |{ lv_year }{ lv_day }{ lv_month }|.
  ENDIF.

*  WRITE: / 'Fecha interna SAP:', lv_internal_date.


ENDFORM.
FORM f_monto_value USING lv_excel_value TYPE string
                 CHANGING lv_amount TYPE exbwr. "p decimals 2.
  DATA: lv_user_format TYPE usr01-dcpfm.

  SELECT SINGLE dcpfm INTO lv_user_format FROM usr01 WHERE bname = sy-uname.

  IF lv_user_format = 'X'.
    " Inglés
    REPLACE ALL OCCURRENCES OF ',' IN lv_excel_value WITH ''.
  ELSE.
    " Europeo
    REPLACE ALL OCCURRENCES OF '.' IN lv_excel_value WITH ''.
    REPLACE ALL OCCURRENCES OF ',' IN lv_excel_value WITH '.'.
  ENDIF.

  lv_amount = lv_excel_value.

ENDFORM.
FORM f_cantidad_value USING lv_excel_value TYPE string
                 CHANGING lv_amount TYPE erfmg. "p decimals 2.
  DATA: lv_user_format TYPE usr01-dcpfm.

  DATA: lv_float   TYPE f,
        lv_decimal TYPE p DECIMALS 2.
  DATA: lv_match TYPE abap_bool.
  DATA matcher TYPE REF TO cl_abap_matcher.

  matcher = cl_abap_matcher=>create( pattern = '^-?\d+(\.\d+)?[eE][+-]?\d+$'
                                     text    = lv_excel_value  ).
  IF NOT matcher->match( ) IS INITIAL.

    lv_float =  lv_excel_value. " Conversión automática a tipo float
    lv_amount = lv_float.        " Se redondea a 2 decimales
  ELSE.

    SELECT SINGLE dcpfm INTO lv_user_format FROM usr01 WHERE bname = sy-uname.

    IF lv_user_format = 'X'.
      " Inglés
      REPLACE ALL OCCURRENCES OF ',' IN lv_excel_value WITH ''.
    ELSE.
      " Europeo
      REPLACE ALL OCCURRENCES OF '.' IN lv_excel_value WITH ''.
      REPLACE ALL OCCURRENCES OF ',' IN lv_excel_value WITH '.'.
    ENDIF.

    lv_amount = lv_excel_value.
  ENDIF.
ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  UPLOAD_EXCEL_SERVER
*&---------------------------------------------------------------------*
*       Carga Excel desde el servidor
*----------------------------------------------------------------------*
FORM upload_excel_server.
  DATA lv_filename      TYPE string.
  DATA it_data TYPE TABLE OF zmm_s_mqa_descarga_contratos.
  FIELD-SYMBOLS: <fs_tab> TYPE STANDARD TABLE.
  DATA: lh_archivo TYPE string,
        lh_tabint  TYPE tabname,
        h_t_salida TYPE tabname VALUE 'LT_DATA'.
  lh_tabint = h_t_salida.
  ASSIGN (lh_tabint) TO <fs_tab>.

  TRY.
      DATA(lo_excel) = NEW zcl_mm_utility_excel( ).
      CALL METHOD lo_excel->upload_xlsx
        EXPORTING
          iv_file_path = lv_filename
          iv_server    = abap_true
          iv_hdr_lines = 1
          ir_table     = REF #( <fs_tab> ).
    CATCH zcx_mm_utility_excel INTO DATA(lx_err).
      IF <fs_tab> IS INITIAL.
        MESSAGE lx_err->get_text( ) TYPE 'I' DISPLAY LIKE 'E'.
      ENDIF.
  ENDTRY.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
*      ASSIGN <fs_tab> TO it_data.
    LOOP AT <fs_tab> ASSIGNING FIELD-SYMBOL(<fs_data>).
      MOVE-CORRESPONDING <fs_data> TO ls_data.
      APPEND ls_data TO lt_data.
    ENDLOOP.
    gt_regsld[] = lt_data[].
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_OPEN_SALDOS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f4_open_saldos .
  DATA: uno(200), dos(4).
  DATA: ls_doc TYPE gty_sal.
  DATA: file_name TYPE epsf-epsfilnam,
        dir_name  TYPE epsf-epsdirnam.
  DATA: lv_mtime TYPE sy-tabix,
        lv_dates TYPE sy-datum,
        lv_times TYPE char8.
  DATA s_file TYPE salfile-longname.

  SELECT SINGLE low INTO p_file FROM tvarvc WHERE name = gc_v_serv_dir_mat_data.
  CONCATENATE p_file '/' INTO s_file.
  CLEAR: it_filedir[], it_filedoc[], it_match[].

  CALL FUNCTION 'RZL_READ_DIR_LOCAL'
    EXPORTING
      name           = s_file
    TABLES
      file_tbl       = it_filedir
    EXCEPTIONS
      argument_error = 1
      not_found      = 2
      OTHERS         = 3.
  IF sy-subrc = 0.
    LOOP AT it_filedir INTO DATA(ls_file).
      CLEAR: file_name, dir_name, lv_mtime, lv_dates, lv_times.
      SPLIT ls_file-name AT '.' INTO uno dos.
      TRANSLATE dos TO UPPER CASE.
      IF dos = 'XLSX'.
        MOVE-CORRESPONDING ls_file TO ls_doc.
        file_name = ls_doc-name.
        dir_name = p_file.
        CALL FUNCTION 'EPS_GET_FILE_ATTRIBUTES'
          EXPORTING
            file_name              = file_name
            dir_name               = dir_name
          IMPORTING
            file_mtime             = lv_mtime
          EXCEPTIONS
            read_directory_failed  = 1
            read_attributes_failed = 2
            OTHERS                 = 3.
        PERFORM p6_to_date_time_tz IN PROGRAM rstr0400 USING lv_mtime ls_doc-horat ls_doc-fecha.
        IF ls_file-name(3) EQ 'DM_'.
          APPEND ls_doc TO it_filedoc.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFORM.

"INICIO Etiqueta FILE_SERV: Subrutina para el evento 'AT SELECTION-SCREEN ON VALUE-REQUEST FOR ...' del
"campo para la ruta del archivo
*&---------------------------------------------------------------------*
*&      Form  F4_OPEN_FILE_SERV
*&---------------------------------------------------------------------*
*       F4
*----------------------------------------------------------------------*
FORM f4_open_file_serv.
  DATA: uno(200), dos(4).
  DATA: ls_doc TYPE gty_sal.
  DATA: file_name TYPE epsf-epsfilnam,
        dir_name  TYPE epsf-epsdirnam.
  DATA: lv_mtime TYPE sy-tabix,
        lv_dates TYPE sy-datum,
        lv_times TYPE char8.
  DATA s_file TYPE salfile-longname.
  DATA xlines TYPE sy-tabix VALUE 2000.
  SELECT SINGLE low INTO p_file FROM tvarvc WHERE name = gc_v_serv_dir_mat_data.
  TRANSLATE p_file TO LOWER CASE.
  CONCATENATE p_file '/' INTO s_file.
  CLEAR: it_filedir[], it_filedoc[], it_match[].

  CALL FUNCTION 'RZL_READ_DIR_LOCAL'
    EXPORTING
      name           = s_file
      nrlines        = xlines
    TABLES
      file_tbl       = it_filedir
    EXCEPTIONS
      argument_error = 1
      not_found      = 2
      OTHERS         = 3.
  IF sy-subrc = 0.
    LOOP AT it_filedir INTO DATA(ls_file).
      CLEAR: file_name, dir_name, lv_mtime, lv_dates, lv_times.
      SPLIT ls_file-name AT '.' INTO uno dos.
      TRANSLATE dos TO UPPER CASE.
      IF dos = 'XLSX'.
        MOVE-CORRESPONDING ls_file TO ls_doc.
        file_name = ls_doc-name.
        dir_name = p_file.
        CALL FUNCTION 'EPS_GET_FILE_ATTRIBUTES'
          EXPORTING
            file_name              = file_name
            dir_name               = dir_name
          IMPORTING
            file_mtime             = lv_mtime
          EXCEPTIONS
            read_directory_failed  = 1
            read_attributes_failed = 2
            OTHERS                 = 3.
        PERFORM p6_to_date_time_tz IN PROGRAM rstr0400 USING lv_mtime ls_doc-horat ls_doc-fecha.
        APPEND ls_doc TO it_filedoc.
      ENDIF.
    ENDLOOP.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'NAME'
      window_title    = 'Archivo'
      value_org       = 'S'
    TABLES
      value_tab       = it_filedoc
      return_tab      = it_match
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc = 0.
    READ TABLE it_match INTO DATA(wa_match) INDEX 1.
    CONCATENATE p_file '/' wa_match-fieldval INTO p_file.
  ENDIF.

  CHECK 1 = 2.

  DATA lv_rc TYPE i.
  DATA lt_files TYPE filetable.
  DATA lv_action TYPE i.
  cl_gui_frontend_services=>file_open_dialog( EXPORTING
                                                file_filter    = |xlsx (*.xlsx)\|*.xlsx\|{ cl_gui_frontend_services=>filetype_all }|  "Filter file type while browsing
                                                multiselection = abap_false
                                              CHANGING
                                                file_table  = lt_files
                                                rc          = lv_rc
                                                user_action = lv_action ).

  IF lv_action EQ cl_gui_frontend_services=>action_ok.
    IF lines( lt_files ) GT 0.
      p_file = lt_files[ 1 ]-filename.
    ENDIF.
  ENDIF.
ENDFORM."f4_open_file_serv

*&---------------------------------------------------------------------*
*&      Form  UPLOAD_EXCEL_SERVER_V2
*&---------------------------------------------------------------------*
*       Carga Excel desde el servidor
*----------------------------------------------------------------------*
FORM upload_excel_server_v2.
*  DATA lv_filename      TYPE string.
  FIELD-SYMBOLS: <fs_tab> TYPE STANDARD TABLE.
  DATA: lh_archivo TYPE string,
        lh_tabint  TYPE tabname,
        h_t_salida TYPE tabname VALUE 'GT_REGSLD'.
  lh_tabint = h_t_salida.
  ASSIGN (lh_tabint) TO <fs_tab>.
*  lv_filename = p_file.

  DATA: iv_file_path TYPE string,
        iv_hdr_lines TYPE i,
        ir_table     TYPE REF TO data.

  DATA: mo_table_descr  TYPE REF TO  cl_abap_tabledescr,
        mo_struct_descr TYPE REF TO	cl_abap_structdescr.

  DATA:
    lv_line           TYPE string,
    lt_components     TYPE cl_abap_structdescr=>component_table,
    lv_num_of_records TYPE i,
    lt_records        TYPE solix_tab,
    ls_records        TYPE solix,
    lv_filelength     TYPE i,
    lv_headerxstring  TYPE xstring,
    lr_table          TYPE REF TO data,
    lt_upload         TYPE STANDARD TABLE OF string,
    lv_errmsg         TYPE bapi_msg,
    lv_data           TYPE REF TO data,
    lo_excel_ref      TYPE REF TO cl_fdt_xl_spreadsheet.
  DATA mv_separator TYPE  c VALUE ';'.
  FIELD-SYMBOLS:
    <ft_data>  TYPE STANDARD TABLE,
    <ft_table> TYPE STANDARD TABLE,
    <fs_line>  TYPE any,
    <fs_field> TYPE string.
  DATA(lo_excel) = NEW zcl_mm_utility_excel( ).

  ir_table = REF #( <fs_tab> ).
  ASSIGN ir_table->* TO <ft_table>.
  REFRESH <ft_table>.
  iv_file_path = lv_filename.

  " Upload from application server disk
  OPEN DATASET iv_file_path FOR INPUT IN BINARY MODE MESSAGE lv_errmsg.
  IF sy-subrc NE 0.
    MESSAGE lv_errmsg TYPE 'E'.
  ENDIF.
  DO.
    READ DATASET iv_file_path INTO ls_records LENGTH DATA(lv_binlen).
    IF sy-subrc NE 0.
      EXIT.
    ENDIF.
    lv_filelength = lv_filelength + lv_binlen.
    APPEND ls_records TO lt_records.
  ENDDO.
  CLOSE DATASET iv_file_path.

  " Convert binary data to xstring
  CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
    EXPORTING
      input_length = lv_filelength
    IMPORTING
      buffer       = lv_headerxstring
    TABLES
      binary_tab   = lt_records
    EXCEPTIONS
      failed       = 1
      OTHERS       = 2.

  IF sy-subrc NE 0.
    MESSAGE iv_file_path TYPE 'E'.
  ENDIF.

  TRY.
      lo_excel_ref = NEW cl_fdt_xl_spreadsheet(
        document_name = iv_file_path
        xdocument     = lv_headerxstring ).
    CATCH cx_fdt_excel_core.
  ENDTRY .

  " Get list of worksheets
  lo_excel_ref->if_fdt_doc_spreadsheet~get_worksheet_names(
    IMPORTING
      worksheet_names = DATA(lt_worksheets) ).

  IF lt_worksheets IS NOT INITIAL.
    " Use the first worksheet
    DATA(lv_woksheetname) = VALUE #( lt_worksheets[ 1 ] OPTIONAL ).
    " Read the worksheet into internal table
    DATA(lo_data_ref) = lo_excel_ref->if_fdt_doc_spreadsheet~get_itab_from_worksheet( lv_woksheetname ).
    ASSIGN lo_data_ref->* TO <gt_excel>.
  ENDIF.

ENDFORM.
"FIN Etiqueta FILE_SERV: Subrutina para el evento 'AT SELECTION-SCREEN ON VALUE-REQUEST FOR ...' del
"campo para la ruta del archivo

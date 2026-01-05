*&---------------------------------------------------------------------*
*& Report ZR_MM_MQA_U_CARGA_DE_PEDIDOS
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* Modifcado por    : Nombre completo del programador y USUARIO.        *
* N° Requerimiento : Número del requerimiento.                         *
* ID del cambio    : ID del pedido cambio.                             *
* Fecha del cambio : Fecha del cambio en formato AAAA.MM.DD            *
* Descripción      : Descripción breve del cambio.                     *
* Transporte       : ID de Transporte contenedor del cambio.           *
*&---------------------------------------------------------------------*

REPORT zr_mm_mqa_u_carga_de_pedidos_o.
TABLES: ekko.
DATA cont TYPE char2.
CONSTANTS: c_fs_wa   TYPE lvc_fname VALUE '-',
           c_ext_xls TYPE string    VALUE '*.xls'.
CONSTANTS: gc_v_serv_dir_mat_data TYPE tvarvc-name VALUE 'ZMM_RUTA_DIR_ARCH_DESC_OC'.

FIELD-SYMBOLS: <gt_excel> TYPE STANDARD TABLE.
FIELD-SYMBOLS: <lv_value> TYPE any.

DATA: lt_campos    TYPE STANDARD TABLE OF dd03l WITH HEADER LINE,
      lt_rollname  TYPE STANDARD TABLE OF dd04t WITH HEADER LINE,
      c_t_salida   TYPE tabname VALUE 'LT_SALIDA',
      lt_cabeceras TYPE STANDARD TABLE OF fieldnames,
      wa_cabeceras TYPE fieldnames,
      lc_archivo   TYPE string,
      lv_encoding  TYPE abap_encoding,
      lc_tabint    TYPE tabname,
      lc_tabname   TYPE tabname.
DATA: var   TYPE sy-tabix, compu TYPE sy-tabix.
DATA gt_regsld TYPE STANDARD TABLE OF zmm_s_mqa_descarga_pedidos.
DATA gs_regsld TYPE zmm_s_mqa_descarga_pedidos.
DATA gt_salida TYPE STANDARD TABLE OF zmm_s_mqa_descarga_pedidos.
DATA lv_filename      TYPE string.   "agregado para el job
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

FIELD-SYMBOLS: <fs_tab> TYPE STANDARD TABLE,
               <fs_it>  TYPE STANDARD TABLE.
*----------------------------------------------------------------------*
*  A L V  -  D E F I N I T I O N
*----------------------------------------------------------------------*

DATA:
  gt_slis_group    TYPE slis_t_sp_group_alv,
  gt_slis_fieldcat TYPE slis_t_fieldcat_alv,
  gs_slis_layout   TYPE slis_layout_alv,
  gt_slis_header   TYPE slis_t_listheader.
*----------------------------------------------------------------------*
DATA: ls_bapi_te_mara  TYPE bapi_te_mara,
      ls_bapi_te_marax TYPE bapi_te_marax.
DATA ll_extensionin  TYPE bapiparex.
DATA ll_extensioninx  TYPE bapiparexx.

*----------------------------------------------------------------------*
*  T A B L E S  /  S T R U C T U  R E  /  V A R I A B L E S
*----------------------------------------------------------------------*
DATA:
  ls_data TYPE zmm_s_mqa_carga_pedidos,
  lt_data TYPE TABLE OF zmm_s_mqa_carga_pedidos.
DATA: lv_rojo(4)  TYPE c VALUE '@0A@',
      lv_verde(4) TYPE c VALUE '@08@'.

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE TEXT-003.
PARAMETERS: p_fsnam TYPE rlgrap-filename OBLIGATORY.
SELECTION-SCREEN END OF BLOCK blk1.

SELECTION-SCREEN BEGIN OF BLOCK blk2 WITH FRAME TITLE TEXT-002.
PARAMETERS: p_alv AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK blk2.

INITIALIZATION.
  SELECT SINGLE low INTO p_fsnam FROM tvarvc WHERE name = gc_v_serv_dir_mat_data.

AT SELECTION-SCREEN OUTPUT.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_fsnam.
  PERFORM f4_open_file.

START-OF-SELECTION.

  lv_filename = p_fsnam.
  PERFORM upload_excel_server.
  PERFORM componentes_lineas.
  PERFORM procesar_datos.


* ENDLOOP.

*&---------------------------------------------------------------------*
*&      Form  F4_OPEN_FILE
*&---------------------------------------------------------------------*
*       F4
*----------------------------------------------------------------------*
FORM f4_open_file.
  DATA: uno(200), dos(4).
  DATA: ls_doc TYPE gty_sal.
  DATA: file_name TYPE epsf-epsfilnam,
        dir_name  TYPE epsf-epsdirnam.
  DATA: lv_mtime TYPE sy-tabix,
        lv_dates TYPE sy-datum,
        lv_times TYPE char8.
  DATA s_file TYPE salfile-longname.
  DATA xlines TYPE sy-tabix VALUE 2000.
  SELECT SINGLE low INTO p_fsnam FROM tvarvc WHERE name = gc_v_serv_dir_mat_data.
  TRANSLATE p_fsnam TO LOWER CASE.
  CONCATENATE p_fsnam '/' INTO s_file.
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
        dir_name = p_fsnam.
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
    CONCATENATE p_fsnam '/' wa_match-fieldval INTO p_fsnam.
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
      p_fsnam = lt_files[ 1 ]-filename.
    ENDIF.
  ENDIF.
ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_UPLOAD_EXCEL_TO_ITAB
*&---------------------------------------------------------------------*
*       Upload Excel
*----------------------------------------------------------------------*
FORM f_upload_excel_to_itab .
  DATA lo_excel_ref TYPE REF TO cl_fdt_xl_spreadsheet.
  DATA : lv_filename      TYPE string,
         lt_records       TYPE solix_tab,
         lv_headerxstring TYPE xstring,
         lv_filelength    TYPE i,
         lt_worksheet     TYPE stringtab.

  lv_filename = p_fsnam.

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

*  PERFORM progress_indicator USING 5 'Transferir datos de EXCEL...'.

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
ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  PROCESAR_DATOS
*&---------------------------------------------------------------------*
*       Procesar Datos
*----------------------------------------------------------------------*
FORM procesar_datos.
  CHECK NOT gt_regsld[] IS INITIAL.
  DATA wa_ekko TYPE wrf_pohf_data_ekko_sty.
  DATA wa_bapimepoh TYPE bapimepoheader.
  DATA wa_ekkox TYPE wrf_pohf_datax_ekko_sty.
  DATA wa_bapimepohx TYPE bapimepoheaderx.


  DATA wa_ekpo TYPE wrf_pohf_data_ekpo_sty.
  DATA wa_bapimepoi TYPE bapimepoitem.
  DATA wa_ekpox TYPE wrf_pohf_datax_ekpo_sty.
  DATA wa_bapimepoix TYPE bapimepoitemx.

  DATA lt_bapimepoi  TYPE TABLE OF bapimepoitem.
  DATA lt_bapimepoix TYPE TABLE OF bapimepoitemx.

  DATA: lt_poaccount  TYPE TABLE OF bapimepoaccount,
        ls_poaccount  TYPE bapimepoaccount,
        lt_poaccountx TYPE TABLE OF bapimepoaccountx,
        ls_poaccountx TYPE bapimepoaccountx,
        lt_pocondp    TYPE TABLE OF bapimepocond,
        ls_pocondp    TYPE bapimepocond,
        lt_pocondpx   TYPE TABLE OF bapimepocondx,
        ls_pocondpx   TYPE bapimepocondx.


  LOOP AT gt_regsld INTO DATA(wa_salida).
    MOVE-CORRESPONDING wa_salida TO wa_ekko.
    wa_ekko-aedat = wa_salida-bedat.
    wa_ekko-ernam = sy-uname.

***    IF wa_salida-matnr IS INITIAL.
***      wa_salida-matnr = wa_salida-sakto.
***    ENDIF.
    MOVE-CORRESPONDING wa_salida TO wa_ekpo.
    wa_ekpo-konnr = wa_salida-konnr2.
    wa_ekpo-bstyp = wa_salida-bstyp2.
    wa_ekpo-stafo = wa_salida-stafo2.
    wa_ekpo-inco1 = wa_salida-inco1x.
    wa_ekpo-inco2 = wa_salida-inco2x.
    wa_ekpo-stapo = wa_salida-stapo2.
     wa_ekpo-MWSKZ = wa_salida-MWSKZ.

*
    AT NEW ebeln.
*      IF  wa_salida-knttp  IS  NOT INITIAL.
        LOOP AT gt_regsld INTO DATA(wa_ekkn) WHERE ebeln = wa_salida-ebeln .

          IF   wa_ekkn-knttp = 'K'.
            ls_poaccount-gl_account  = wa_ekkn-sakto.
            ls_poaccount-po_item     = wa_ekkn-ebelp.
            ls_poaccount-costcenter  = wa_ekkn-kostl.

            ls_poaccountx-gl_account = 'X'.
            ls_poaccountx-po_item    = wa_ekkn-ebelp.
            ls_poaccountx-costcenter = 'X'.
            APPEND ls_poaccount  TO lt_poaccount.
            APPEND ls_poaccountx TO lt_poaccountx.
          ENDIF.

          IF  wa_ekkn-knttp = 'N'.
            ls_poaccount-po_item    = wa_ekkn-ebelp.
            ls_poaccount-gl_account = wa_ekkn-sakto.
            ls_poaccount-bus_area   = wa_ekkn-gsber.

            ls_poaccountx-po_item    = wa_ekkn-ebelp.
            ls_poaccountx-gl_account = 'X'.
            ls_poaccountx-bus_area   = 'X'.
            APPEND ls_poaccount  TO lt_poaccount.
          APPEND ls_poaccountx TO lt_poaccountx.
          ENDIF.


        ENDLOOP.
        CLEAR: wa_ekkn,  ls_poaccount, ls_poaccountx.
*      ENDIF.
    ENDAT.


    AT NEW ebeln.
      CLEAR: wa_bapimepoh.
      PERFORM poner_x_wa_ekkox USING wa_ekko CHANGING wa_ekkox.
      wa_ekkox-aedat = 'X'.
      wa_ekkox-ernam = 'X'.

      CALL FUNCTION 'MAP2E_EKKO_TO_MEPOHEADER'
        EXPORTING
          wrf_pohf_data_ekko_sty = wa_ekko
        CHANGING
          bapimepoheader         = wa_bapimepoh.

      CALL FUNCTION 'MAP2E_EKKOX_TO_MEPOHEADERX'
        EXPORTING
          wrf_pohf_datax_ekko_sty = wa_ekkox
        CHANGING
          bapimepoheaderx         = wa_bapimepohx.

    ENDAT.
    wa_ekpo-banfn =  ' '.
    wa_ekpo-bnfpo =  ' '.
    wa_ekpo-konnr =  ' '.
    wa_ekpo-ktpnr =  ' '.

    CALL FUNCTION 'MAP2E_EKPO_TO_MEPOITEM'
      EXPORTING
        wrf_pohf_data_ekpo_sty = wa_ekpo
      CHANGING
        bapimepoitem           = wa_bapimepoi.

    APPEND wa_bapimepoi TO lt_bapimepoi.

    CLEAR wa_ekpox.
    PERFORM poner_x_wa_ekpox USING wa_ekpo CHANGING wa_ekpox.
    wa_ekpox-banfn =  ' '.
    wa_ekpox-bnfpo =  ' '.
    wa_ekpo-konnr  =  ' '.
    wa_ekpo-ktpnr  =  ' '.
    CALL FUNCTION 'MAP2E_EKPOX_TO_MEPOITEMX'
      EXPORTING
        wrf_pohf_datax_ekpo_sty = wa_ekpox
      CHANGING
        bapimepoitemx           = wa_bapimepoix.

    APPEND wa_bapimepoix TO lt_bapimepoix.
    CLEAR: wa_bapimepoi, wa_bapimepoix.

    PERFORM agregar_prctr_kschl USING wa_salida CHANGING ls_pocondp ls_pocondpx ls_poaccount ls_poaccountx.
    IF NOT ls_pocondp IS INITIAL.
      APPEND ls_pocondpx TO lt_pocondpx.
      APPEND ls_pocondp TO lt_pocondp.
      CLEAR: ls_pocondp, ls_pocondpx.
    ENDIF.



    AT END OF ebeln.
      PERFORM crear_documento_po TABLES lt_bapimepoi lt_bapimepoix lt_poaccount lt_poaccountx USING wa_bapimepoh wa_bapimepohx.
      CLEAR: lt_bapimepoi[], lt_bapimepoix[], wa_bapimepoh, wa_bapimepohx, lt_poaccount[], lt_poaccountx[].
    ENDAT.


  ENDLOOP.

  PERFORM show_alv.
ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  PONER_X_WA_EKKOX
*&---------------------------------------------------------------------*
*       Seleccionar X
*----------------------------------------------------------------------*
FORM poner_x_wa_ekkox USING p_wa_ekko TYPE wrf_pohf_data_ekko_sty
                   CHANGING p_wa_ekkox TYPE wrf_pohf_datax_ekko_sty.

*  p_wa_ekkox-ebeln  = p_wa_ekko-ebeln.
  p_wa_ekkox-ebelnx = 'X'.
  p_wa_ekkox-bukrs              = COND #( WHEN p_wa_ekko-bukrs             NE '' THEN 'X' ).
  p_wa_ekkox-bstyp              = COND #( WHEN p_wa_ekko-bstyp             NE '' THEN 'X' ).
  p_wa_ekkox-bsakz              = COND #( WHEN p_wa_ekko-bsakz             NE '' THEN 'X' ).
  p_wa_ekkox-bsart              = COND #( WHEN p_wa_ekko-bsart             NE '' THEN 'X' ).
  p_wa_ekkox-statu              = COND #( WHEN p_wa_ekko-statu             NE '' THEN 'X' ).
  p_wa_ekkox-pincr              = COND #( WHEN p_wa_ekko-pincr             NE '' THEN 'X' ).
*  p_wa_ekkox-lponr              = COND #( WHEN p_wa_ekko-lponr             NE '' THEN 'X' ).
  p_wa_ekkox-lifnr              = COND #( WHEN p_wa_ekko-lifnr             NE '' THEN 'X' ).
  p_wa_ekkox-spras              = COND #( WHEN p_wa_ekko-spras             NE '' THEN 'X' ).
  p_wa_ekkox-zterm              = COND #( WHEN p_wa_ekko-zterm             NE '' THEN 'X' ).
  p_wa_ekkox-zbd1t              = COND #( WHEN p_wa_ekko-zbd1t             NE '' THEN 'X' ).
  p_wa_ekkox-zbd2t              = COND #( WHEN p_wa_ekko-zbd2t             NE '' THEN 'X' ).
  p_wa_ekkox-zbd3t              = COND #( WHEN p_wa_ekko-zbd3t             NE '' THEN 'X' ).
  p_wa_ekkox-zbd1p              = COND #( WHEN p_wa_ekko-zbd1p             NE '' THEN 'X' ).
  p_wa_ekkox-zbd2p              = COND #( WHEN p_wa_ekko-zbd2p             NE '' THEN 'X' ).
  p_wa_ekkox-ekorg              = COND #( WHEN p_wa_ekko-ekorg             NE '' THEN 'X' ).
  p_wa_ekkox-ekgrp              = COND #( WHEN p_wa_ekko-ekgrp             NE '' THEN 'X' ).
  p_wa_ekkox-waers              = COND #( WHEN p_wa_ekko-waers             NE '' THEN 'X' ).
  p_wa_ekkox-wkurs              = COND #( WHEN p_wa_ekko-wkurs             NE '' THEN 'X' ).
  p_wa_ekkox-kufix              = COND #( WHEN p_wa_ekko-kufix             NE '' THEN 'X' ).
  p_wa_ekkox-bedat              = COND #( WHEN p_wa_ekko-bedat             NE '' THEN 'X' ).
  p_wa_ekkox-angnr              = COND #( WHEN p_wa_ekko-angnr             NE '' THEN 'X' ).
  p_wa_ekkox-verkf              = COND #( WHEN p_wa_ekko-verkf             NE '' THEN 'X' ).
  p_wa_ekkox-telf1              = COND #( WHEN p_wa_ekko-telf1             NE '' THEN 'X' ).
  p_wa_ekkox-konnr              = COND #( WHEN p_wa_ekko-konnr             NE '' THEN 'X' ).
  p_wa_ekkox-reswk              = COND #( WHEN p_wa_ekko-reswk             NE '' THEN 'X' ).
  p_wa_ekkox-inco1              = COND #( WHEN p_wa_ekko-inco1             NE '' THEN 'X' ).
  p_wa_ekkox-inco2              = COND #( WHEN p_wa_ekko-inco2             NE '' THEN 'X' ).
  p_wa_ekkox-ktwrt              = COND #( WHEN p_wa_ekko-ktwrt             NE '' THEN 'X' ).
  p_wa_ekkox-knumv              = COND #( WHEN p_wa_ekko-knumv             NE '' THEN 'X' ).
  p_wa_ekkox-kalsm              = COND #( WHEN p_wa_ekko-kalsm             NE '' THEN 'X' ).
  p_wa_ekkox-stafo              = COND #( WHEN p_wa_ekko-stafo             NE '' THEN 'X' ).
  p_wa_ekkox-lifre              = COND #( WHEN p_wa_ekko-lifre             NE '' THEN 'X' ).
  p_wa_ekkox-upinc              = COND #( WHEN p_wa_ekko-upinc             NE '' THEN 'X' ).
  p_wa_ekkox-frggr              = COND #( WHEN p_wa_ekko-frggr             NE '' THEN 'X' ).
  p_wa_ekkox-frgsx              = COND #( WHEN p_wa_ekko-frgsx             NE '' THEN 'X' ).
  p_wa_ekkox-frgke              = COND #( WHEN p_wa_ekko-frgke             NE '' THEN 'X' ).
  p_wa_ekkox-frgzu              = COND #( WHEN p_wa_ekko-frgzu             NE '' THEN 'X' ).
  p_wa_ekkox-frgrl              = COND #( WHEN p_wa_ekko-frgrl             NE '' THEN 'X' ).
  p_wa_ekkox-lands              = COND #( WHEN p_wa_ekko-lands             NE '' THEN 'X' ).
  p_wa_ekkox-stceg_l            = COND #( WHEN p_wa_ekko-stceg_l           NE '' THEN 'X' ).
  p_wa_ekkox-absgr              = COND #( WHEN p_wa_ekko-absgr             NE '' THEN 'X' ).
  p_wa_ekkox-memory             = COND #( WHEN p_wa_ekko-memory            NE '' THEN 'X' ).
  p_wa_ekkox-procstat           = COND #( WHEN p_wa_ekko-procstat          NE '' THEN 'X' ).
  p_wa_ekkox-rlwrt              = COND #( WHEN p_wa_ekko-rlwrt             NE '' THEN 'X' ).
  p_wa_ekkox-inco2_l            = COND #( WHEN p_wa_ekko-inco2_l           NE '' THEN 'X' ).
  p_wa_ekkox-inco3_l            = COND #( WHEN p_wa_ekko-inco3_l           NE '' THEN 'X' ).
  p_wa_ekkox-key_id             = COND #( WHEN p_wa_ekko-key_id            NE '' THEN 'X' ).
  p_wa_ekkox-otb_value          = COND #( WHEN p_wa_ekko-otb_value         NE '' THEN 'X' ).
  p_wa_ekkox-otb_curr           = COND #( WHEN p_wa_ekko-otb_curr          NE '' THEN 'X' ).
  p_wa_ekkox-otb_res_value      = COND #( WHEN p_wa_ekko-otb_res_value     NE '' THEN 'X' ).
  p_wa_ekkox-otb_spec_value     = COND #( WHEN p_wa_ekko-otb_spec_value    NE '' THEN 'X' ).

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  PONER_X_WA_EKPOX
*&---------------------------------------------------------------------*
*       Seleccionar X
*----------------------------------------------------------------------*
FORM poner_x_wa_ekpox  USING    p_wa_ekpo TYPE wrf_pohf_data_ekpo_sty
                       CHANGING p_wa_ekpox TYPE wrf_pohf_datax_ekpo_sty.
**
**  p_wa_ekpox-ebeln  = p_wa_ekpo-ebeln.
  p_wa_ekpox-ebelp  = p_wa_ekpo-ebelp.
  p_wa_ekpox-ebelpx = p_wa_ekpo-ebelp . " 'X'.
  p_wa_ekpox-txz01        = COND #( WHEN p_wa_ekpo-txz01       NE '' THEN 'X' ).
  p_wa_ekpox-matnr        = COND #( WHEN p_wa_ekpo-matnr       NE '' THEN 'X' ).
  p_wa_ekpox-matnr        = COND #( WHEN p_wa_ekpo-matnr       NE '' THEN 'X' ).
  p_wa_ekpox-bukrs        = COND #( WHEN p_wa_ekpo-bukrs       NE '' THEN 'X' ).
  p_wa_ekpox-werks        = COND #( WHEN p_wa_ekpo-werks       NE '' THEN 'X' ).
  p_wa_ekpox-lgort        = COND #( WHEN p_wa_ekpo-lgort       NE '' THEN 'X' ).
  p_wa_ekpox-bednr        = COND #( WHEN p_wa_ekpo-bednr       NE '' THEN 'X' ).
  p_wa_ekpox-matkl        = COND #( WHEN p_wa_ekpo-matkl       NE '' THEN 'X' ).
  p_wa_ekpox-infnr        = COND #( WHEN p_wa_ekpo-infnr       NE '' THEN 'X' ).
  p_wa_ekpox-ktmng        = COND #( WHEN p_wa_ekpo-ktmng       NE '' THEN 'X' ).
  p_wa_ekpox-ktmng        = COND #( WHEN p_wa_ekpo-ktmng       NE '' THEN 'X' ).
  p_wa_ekpox-menge        = COND #( WHEN p_wa_ekpo-menge       NE '' THEN 'X' ).
  p_wa_ekpox-meins        = COND #( WHEN p_wa_ekpo-meins       NE '' THEN 'X' ).
  p_wa_ekpox-bpumz        = COND #( WHEN p_wa_ekpo-bpumz       NE '' THEN 'X' ).
  p_wa_ekpox-bpumn        = COND #( WHEN p_wa_ekpo-bpumn       NE '' THEN 'X' ).
  p_wa_ekpox-umrez        = COND #( WHEN p_wa_ekpo-umrez       NE '' THEN 'X' ).
  p_wa_ekpox-umren        = COND #( WHEN p_wa_ekpo-umren       NE '' THEN 'X' ).
  p_wa_ekpox-netpr        = COND #( WHEN p_wa_ekpo-netpr       NE '' THEN 'X' ).
  p_wa_ekpox-peinh        = COND #( WHEN p_wa_ekpo-peinh       NE '' THEN 'X' ).
  p_wa_ekpox-netwr        = COND #( WHEN p_wa_ekpo-netwr       NE '' THEN 'X' ).
  p_wa_ekpox-brtwr        = COND #( WHEN p_wa_ekpo-brtwr       NE '' THEN 'X' ).
  p_wa_ekpox-webaz        = COND #( WHEN p_wa_ekpo-webaz       NE '' THEN 'X' ).
  p_wa_ekpox-mwskz        = COND #( WHEN p_wa_ekpo-mwskz       NE '' THEN 'X' ).
  p_wa_ekpox-spinf        = COND #( WHEN p_wa_ekpo-spinf       NE '' THEN 'X' ).
  p_wa_ekpox-prsdr        = COND #( WHEN p_wa_ekpo-prsdr       NE '' THEN 'X' ).
  p_wa_ekpox-prsdr        = COND #( WHEN p_wa_ekpo-prsdr       NE '' THEN 'X' ).
  p_wa_ekpox-mahn1        = COND #( WHEN p_wa_ekpo-mahn1       NE '' THEN 'X' ).
  p_wa_ekpox-mahn2        = COND #( WHEN p_wa_ekpo-mahn2       NE '' THEN 'X' ).
  p_wa_ekpox-mahn3        = COND #( WHEN p_wa_ekpo-mahn3       NE '' THEN 'X' ).
  p_wa_ekpox-uebto        = COND #( WHEN p_wa_ekpo-uebto       NE '' THEN 'X' ).
  p_wa_ekpox-uebtk        = COND #( WHEN p_wa_ekpo-uebtk       NE '' THEN 'X' ).
  p_wa_ekpox-uebto        = COND #( WHEN p_wa_ekpo-uebto       NE '' THEN 'X' ).
  p_wa_ekpox-elikz        = COND #( WHEN p_wa_ekpo-elikz       NE '' THEN 'X' ).
  p_wa_ekpox-erekz        = COND #( WHEN p_wa_ekpo-erekz       NE '' THEN 'X' ).
  p_wa_ekpox-pstyp        = COND #( WHEN p_wa_ekpo-pstyp       NE '' THEN 'X' ).
  p_wa_ekpox-knttp        = COND #( WHEN p_wa_ekpo-knttp       NE '' THEN 'X' ).
  p_wa_ekpox-kzvbr        = COND #( WHEN p_wa_ekpo-kzvbr       NE '' THEN 'X' ).
  p_wa_ekpox-wepos        = COND #( WHEN p_wa_ekpo-wepos       NE '' THEN 'X' ).
  p_wa_ekpox-weunb        = COND #( WHEN p_wa_ekpo-weunb       NE '' THEN 'X' ).
  p_wa_ekpox-repos        = COND #( WHEN p_wa_ekpo-repos       NE '' THEN 'X' ).
  p_wa_ekpox-webre        = COND #( WHEN p_wa_ekpo-webre       NE '' THEN 'X' ).
  p_wa_ekpox-konnr        = COND #( WHEN p_wa_ekpo-konnr       NE '' THEN 'X' ).
  p_wa_ekpox-ktpnr        = COND #( WHEN p_wa_ekpo-ktpnr       NE '' THEN 'X' ).
  p_wa_ekpox-abftz        = COND #( WHEN p_wa_ekpo-abftz       NE '' THEN 'X' ).
  p_wa_ekpox-etfz1        = COND #( WHEN p_wa_ekpo-etfz1       NE '' THEN 'X' ).
  p_wa_ekpox-etfz2        = COND #( WHEN p_wa_ekpo-etfz2       NE '' THEN 'X' ).
  p_wa_ekpox-lmein        = COND #( WHEN p_wa_ekpo-lmein       NE '' THEN 'X' ).
  p_wa_ekpox-zwert        = COND #( WHEN p_wa_ekpo-zwert       NE '' THEN 'X' ).
  p_wa_ekpox-navnw        = COND #( WHEN p_wa_ekpo-navnw       NE '' THEN 'X' ).
  p_wa_ekpox-abmng        = COND #( WHEN p_wa_ekpo-abmng       NE '' THEN 'X' ).
  p_wa_ekpox-prdat        = COND #( WHEN p_wa_ekpo-prdat       NE '' THEN 'X' ).
  p_wa_ekpox-bstyp        = COND #( WHEN p_wa_ekpo-bstyp       NE '' THEN 'X' ).
  p_wa_ekpox-effwr        = COND #( WHEN p_wa_ekpo-effwr       NE '' THEN 'X' ).
  p_wa_ekpox-stafo        = COND #( WHEN p_wa_ekpo-stafo       NE '' THEN 'X' ).
  p_wa_ekpox-plifz        = COND #( WHEN p_wa_ekpo-plifz       NE '' THEN 'X' ).
  p_wa_ekpox-ntgew        = COND #( WHEN p_wa_ekpo-ntgew       NE '' THEN 'X' ).
  p_wa_ekpox-gewei        = COND #( WHEN p_wa_ekpo-gewei       NE '' THEN 'X' ).
  p_wa_ekpox-arsnr        = COND #( WHEN p_wa_ekpo-arsnr       NE '' THEN 'X' ).
  p_wa_ekpox-arsps        = COND #( WHEN p_wa_ekpo-arsps       NE '' THEN 'X' ).
  p_wa_ekpox-ean11        = COND #( WHEN p_wa_ekpo-ean11       NE '' THEN 'X' ).
  p_wa_ekpox-ko_prctr     = COND #( WHEN p_wa_ekpo-ko_prctr    NE '' THEN 'X' ).
  p_wa_ekpox-brgew        = COND #( WHEN p_wa_ekpo-brgew       NE '' THEN 'X' ).
  p_wa_ekpox-volum        = COND #( WHEN p_wa_ekpo-volum       NE '' THEN 'X' ).
  p_wa_ekpox-voleh        = COND #( WHEN p_wa_ekpo-voleh       NE '' THEN 'X' ).
  p_wa_ekpox-inco1        = COND #( WHEN p_wa_ekpo-inco1       NE '' THEN 'X' ).
  p_wa_ekpox-inco2        = COND #( WHEN p_wa_ekpo-inco2       NE '' THEN 'X' ).
  p_wa_ekpox-packno       = COND #( WHEN p_wa_ekpo-packno      NE '' THEN 'X' ).
  p_wa_ekpox-gnetwr       = COND #( WHEN p_wa_ekpo-gnetwr      NE '' THEN 'X' ).
  p_wa_ekpox-stapo        = COND #( WHEN p_wa_ekpo-stapo       NE '' THEN 'X' ).
  p_wa_ekpox-uebpo        = COND #( WHEN p_wa_ekpo-uebpo       NE '' THEN 'X' ).
  p_wa_ekpox-cuobj        = COND #( WHEN p_wa_ekpo-cuobj       NE '' THEN 'X' ).
  p_wa_ekpox-druhr        = COND #( WHEN p_wa_ekpo-druhr       NE '' THEN 'X' ).
  p_wa_ekpox-drunr        = COND #( WHEN p_wa_ekpo-drunr       NE '' THEN 'X' ).
  p_wa_ekpox-abelp        = COND #( WHEN p_wa_ekpo-abelp       NE '' THEN 'X' ).
  p_wa_ekpox-anzpu        = COND #( WHEN p_wa_ekpo-anzpu       NE '' THEN 'X' ).
  p_wa_ekpox-mhdrz        = COND #( WHEN p_wa_ekpo-mhdrz       NE '' THEN 'X' ).
  p_wa_ekpox-anfnr        = COND #( WHEN p_wa_ekpo-anfnr       NE '' THEN 'X' ).
  p_wa_ekpox-anfps        = COND #( WHEN p_wa_ekpo-anfps       NE '' THEN 'X' ).
*  p_wa_ekpox-banfn        = COND #( WHEN p_wa_ekpo-banfn       NE '' THEN 'X' ).
**  p_wa_ekpox-bnfpo        = COND #( WHEN p_wa_ekpo-bnfpo       NE '' THEN 'X' ).
  p_wa_ekpox-mtart        = COND #( WHEN p_wa_ekpo-mtart       NE '' THEN 'X' ).
  p_wa_ekpox-kzwi1        = COND #( WHEN p_wa_ekpo-kzwi1       NE '' THEN 'X' ).
  p_wa_ekpox-kzwi2        = COND #( WHEN p_wa_ekpo-kzwi2       NE '' THEN 'X' ).
  p_wa_ekpox-kzwi3        = COND #( WHEN p_wa_ekpo-kzwi3       NE '' THEN 'X' ).
  p_wa_ekpox-kzwi4        = COND #( WHEN p_wa_ekpo-kzwi4       NE '' THEN 'X' ).
  p_wa_ekpox-kzwi5        = COND #( WHEN p_wa_ekpo-kzwi5       NE '' THEN 'X' ).
  p_wa_ekpox-kzwi6        = COND #( WHEN p_wa_ekpo-kzwi6       NE '' THEN 'X' ).
  p_wa_ekpox-mfzhi        = COND #( WHEN p_wa_ekpo-mfzhi       NE '' THEN 'X' ).
  p_wa_ekpox-ffzhi        = COND #( WHEN p_wa_ekpo-ffzhi       NE '' THEN 'X' ).
  p_wa_ekpox-lfret        = COND #( WHEN p_wa_ekpo-lfret       NE '' THEN 'X' ).
  p_wa_ekpox-nrfhg        = COND #( WHEN p_wa_ekpo-nrfhg       NE '' THEN 'X' ).
  p_wa_ekpox-bonba        = COND #( WHEN p_wa_ekpo-bonba       NE '' THEN 'X' ).
  p_wa_ekpox-afnam        = COND #( WHEN p_wa_ekpo-afnam       NE '' THEN 'X' ).
  p_wa_ekpox-tzonrc       = COND #( WHEN p_wa_ekpo-tzonrc      NE '' THEN 'X' ).
  p_wa_ekpox-iprkz        = COND #( WHEN p_wa_ekpo-iprkz       NE '' THEN 'X' ).
  p_wa_ekpox-ccomp        = COND #( WHEN p_wa_ekpo-ccomp       NE '' THEN 'X' ).
  p_wa_ekpox-reslo        = COND #( WHEN p_wa_ekpo-reslo       NE '' THEN 'X' ).

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  CREAR_DOCUMENTO_PO
*&---------------------------------------------------------------------*
*       Crear Documento
*----------------------------------------------------------------------*
FORM crear_documento_po  TABLES   p_lt_bapimepoi STRUCTURE bapimepoitem
                                  p_lt_bapimepoix STRUCTURE bapimepoitemx
                                  p_lt_poaccount STRUCTURE bapimepoaccount
                                  p_lt_poaccountx STRUCTURE bapimepoaccountx
**                                POACCOUNT
**                                POACCOUNTX

                         USING    p_wa_bapimepoh TYPE bapimepoheader
                                  p_wa_bapimepohx TYPE bapimepoheaderx.



  DATA: ls_reg_ekpo TYPE zmm_reg_ekpo,
        lt_reg_ekpo TYPE TABLE OF  zmm_reg_ekpo.

  DATA lt_return TYPE TABLE OF bapiret2.
  DATA lv_ebeln TYPE ebeln.
  CLEAR: lv_ebeln, lt_return[].

  CALL FUNCTION 'BAPI_PO_CREATE1'
    EXPORTING
      poheader         = p_wa_bapimepoh
      poheaderx        = p_wa_bapimepohx
    IMPORTING
      exppurchaseorder = lv_ebeln
    TABLES
      return           = lt_return
      poitem           = p_lt_bapimepoi
      poitemx          = p_lt_bapimepoix
      poaccount        = p_lt_poaccount
      poaccountx       = p_lt_poaccountx.
*      POACCOUNT
*      POACCOUNTX


  IF NOT lv_ebeln  IS NOT INITIAL.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.
  ENDIF.

  LOOP AT lt_return INTO DATA(return).

    IF return-type  NE 'E'.
      ls_data-ebeln    = p_wa_bapimepoh-po_number.
      ls_data-semaforo = lv_verde.
      ls_data-mensajes  = return-message.

      ls_reg_ekpo-ebeln    =  p_wa_bapimepoh-po_number.
      ls_reg_ekpo-semaforo =  lv_verde.
      ls_reg_ekpo-mensajes =   return-message.

    ELSE.
      ls_data-ebeln    = p_wa_bapimepoh-po_number.
      ls_data-semaforo = lv_rojo.
      ls_data-mensajes  = return-message.

      ls_reg_ekpo-ebeln   = p_wa_bapimepoh-po_number.
      ls_reg_ekpo-semaforo = lv_rojo.
      ls_reg_ekpo-mensajes =  return-message.

    ENDIF.
    APPEND    ls_reg_ekpo TO   lt_reg_ekpo .
    APPEND    ls_data TO   lt_data .
    CLEAR: ls_data , ls_reg_ekpo .
  ENDLOOP.
  MODIFY zmm_reg_ekpo FROM TABLE lt_reg_ekpo.
  REFRESH   lt_reg_ekpo.
  CLEAR   lt_reg_ekpo.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  AGREGAR_PRCTR_KSCHL
*&---------------------------------------------------------------------*
*       Datos de la condición
*----------------------------------------------------------------------*
FORM agregar_prctr_kschl USING p_wa_ekpo     TYPE zmm_s_mqa_descarga_pedidos
                      CHANGING ls_pocondp    TYPE bapimepocond
                               ls_pocondpx   TYPE bapimepocondx
                               ls_poaccount  TYPE bapimepoaccount
                               ls_poaccountx TYPE bapimepoaccountx.


*  IF NOT p_wa_ekpo-ko_prctr IS INITIAL.
*    ls_poaccount-po_item     = p_wa_ekpo-ebelp.
*    ls_poaccountx-po_item    = p_wa_ekpo-ebelp.
*    ls_poaccount-profit_ctr  = p_wa_ekpo-ko_prctr.
*    ls_poaccountx-profit_ctr = 'X'.
*  ENDIF.

  ls_pocondp-itm_number   = p_wa_ekpo-ebelp.
  ls_pocondp-cond_st_no   = '001'.
  ls_pocondp-cond_type    = 'PBXX'.
  ls_pocondp-cond_value   = p_wa_ekpo-netwr.
  ls_pocondp-currency     = p_wa_ekpo-waers.
  ls_pocondp-currency_iso = p_wa_ekpo-waers.
  ls_pocondp-cond_unit    = p_wa_ekpo-meins.
  ls_pocondp-cond_p_unt   = 1.
  ls_pocondp-change_id    = 'I'.

  ls_pocondpx-itm_number   =  p_wa_ekpo-ebelp.
  ls_pocondpx-cond_st_no   = '001'.
  ls_pocondpx-cond_type    = 'X'.
  ls_pocondpx-cond_value   = 'X'.
  ls_pocondpx-currency     = 'X'.
  ls_pocondpx-currency_iso = 'X'.
  ls_pocondpx-cond_unit    = 'X'.
  ls_pocondpx-cond_p_unt   = 'X'.
  ls_pocondpx-itm_numberx  = 'X'.
  ls_pocondpx-change_id    = 'X'.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  UPLOAD_EXCEL_SERVER
*&---------------------------------------------------------------------*
*       Carga Excel desde el servidor
*----------------------------------------------------------------------*
FORM upload_excel_server.
  FIELD-SYMBOLS: <fs_tab> TYPE STANDARD TABLE.
  DATA: lh_archivo TYPE string,
        lh_tabint  TYPE tabname,
        h_t_salida TYPE tabname VALUE  'GT_REGSLD'.  "'LT_SALIDA'.
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

*&---------------------------------------------------------------------*
*&      Form  COMPONENTES_LINEAS
*&---------------------------------------------------------------------*
*       Linea
*----------------------------------------------------------------------*
FORM componentes_lineas .
  DATA:
    lt_values TYPE TABLE OF string,

    lv_data   TYPE REF TO data,
    lv_datfm  TYPE xudatfm.
  DATA : lv_id    TYPE i,
         lv_cnt   TYPE i,
         lv_fill  TYPE string,
         lv_campo TYPE string.

  FIELD-SYMBOLS:
    <fs_line>  TYPE any,
    <fs_value> TYPE any.
  FIELD-SYMBOLS: <lv_field> TYPE any.

  lv_cnt = 169.
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
      ASSIGN COMPONENT sy-index OF STRUCTURE <lw_file> TO <lv_value>.
      IF sy-subrc EQ 0.
        CASE sy-index.
          WHEN 1.  MOVE   <lv_value> TO <lw_excel>-ebeln    .
          WHEN 2.  MOVE   <lv_value> TO <lw_excel>-bukrs    .
          WHEN 3.  MOVE   <lv_value> TO <lw_excel>-bstyp    .
          WHEN 4.  MOVE   <lv_value> TO <lw_excel>-bsakz    .
          WHEN 5.  MOVE   <lv_value> TO <lw_excel>-bsart    .
          WHEN 6.  MOVE   <lv_value> TO <lw_excel>-statu    .
          WHEN 7.  MOVE   <lv_value> TO <lw_excel>-pincr    .
          WHEN 8.  MOVE   <lv_value> TO <lw_excel>-lponr    .
          WHEN 9.  MOVE   <lv_value> TO <lw_excel>-lifnr    .
          WHEN 10. MOVE   <lv_value> TO <lw_excel>-spras   .
          WHEN 11. MOVE   <lv_value> TO <lw_excel>-zterm   .
          WHEN 12. MOVE   <lv_value> TO <lw_excel>-zbd1t   .
          WHEN 13. MOVE   <lv_value> TO <lw_excel>-zbd2t   .
          WHEN 14. MOVE   <lv_value> TO <lw_excel>-zbd3t   .
          WHEN 15. MOVE   <lv_value> TO <lw_excel>-zbd1p   .
          WHEN 16. MOVE   <lv_value> TO <lw_excel>-zbd2p   .
          WHEN 17. MOVE   <lv_value> TO <lw_excel>-ekorg   .
          WHEN 18. MOVE   <lv_value> TO <lw_excel>-ekgrp   .
          WHEN 19. MOVE   <lv_value> TO <lw_excel>-waers   .
          WHEN 20. MOVE   <lv_value> TO <lw_excel>-wkurs   .
          WHEN 21.
            REPLACE ALL OCCURRENCES OF '-' IN <lv_value> WITH space.
            MOVE    <lv_value> TO <lw_excel>-kufix   .
          WHEN 22.
            REPLACE ALL OCCURRENCES OF '-' IN <lv_value> WITH space.
            MOVE   <lv_value> TO <lw_excel>-bedat   .

          WHEN 23. MOVE   <lv_value> TO <lw_excel>-angnr   .
          WHEN 24. MOVE   <lv_value> TO <lw_excel>-verkf   .
          WHEN 25. MOVE   <lv_value> TO <lw_excel>-telf1   .
          WHEN 26. MOVE   <lv_value> TO <lw_excel>-konnr   .
          WHEN 27. MOVE   <lv_value> TO <lw_excel>-reswk   .
          WHEN 28. MOVE   <lv_value> TO <lw_excel>-inco1   .
          WHEN 29. MOVE   <lv_value> TO <lw_excel>-inco2   .
          WHEN 30. MOVE   <lv_value> TO <lw_excel>-ktwrt   .
          WHEN 31. MOVE   <lv_value> TO <lw_excel>-knumv   .
          WHEN 32. MOVE   <lv_value> TO <lw_excel>-kalsm   .
          WHEN 33. MOVE   <lv_value> TO <lw_excel>-stafo   .
          WHEN 34. MOVE   <lv_value> TO <lw_excel>-lifre   .
          WHEN 35. MOVE   <lv_value> TO <lw_excel>-upinc   .
          WHEN 36. MOVE   <lv_value> TO <lw_excel>-stako   .
          WHEN 37. MOVE   <lv_value> TO <lw_excel>-frggr   .
          WHEN 38. MOVE   <lv_value> TO <lw_excel>-frgsx   .
          WHEN 39. MOVE   <lv_value> TO <lw_excel>-frgke   .
          WHEN 40. MOVE   <lv_value> TO <lw_excel>-frgzu   .
          WHEN 41. MOVE   <lv_value> TO <lw_excel>-frgrl   .
          WHEN 42. MOVE   <lv_value> TO <lw_excel>-lands   .
          WHEN 43. MOVE   <lv_value> TO <lw_excel>-stceg_l .
          WHEN 44. MOVE   <lv_value> TO <lw_excel>-absgr   .
          WHEN 45. MOVE   <lv_value> TO <lw_excel>-memory  .
          WHEN 46. MOVE   <lv_value> TO <lw_excel>-procstat.
          WHEN 47. MOVE   <lv_value> TO <lw_excel>-rlwrt   .
          WHEN 48. MOVE   <lv_value> TO <lw_excel>-rettp   .
          WHEN 49. MOVE   <lv_value> TO <lw_excel>-dptyp   .
          WHEN 50. MOVE   <lv_value> TO <lw_excel>-dppct   .
          WHEN 51. MOVE   <lv_value> TO <lw_excel>-dpamt   .
          WHEN 52. MOVE   <lv_value> TO <lw_excel>-inco2_l .
          WHEN 53. MOVE   <lv_value> TO <lw_excel>-inco3_l .
          WHEN 54. MOVE   <lv_value> TO <lw_excel>-ext_rev_tmstmp   .
          WHEN 55. MOVE   <lv_value> TO <lw_excel>-force_cnt        .
          WHEN 56. MOVE   <lv_value> TO <lw_excel>-reloc_id         .
          WHEN 57. MOVE   <lv_value> TO <lw_excel>-fsh_item_group   .
          WHEN 58. MOVE   <lv_value> TO <lw_excel>-fsh_vas_last_item.
          WHEN 59. MOVE   <lv_value> TO <lw_excel>-key_id           .
          WHEN 60. MOVE   <lv_value> TO <lw_excel>-otb_value        .
          WHEN 61. MOVE   <lv_value> TO <lw_excel>-otb_curr         .
          WHEN 62. MOVE   <lv_value> TO <lw_excel>-otb_res_value    .
          WHEN 63. MOVE   <lv_value> TO <lw_excel>-otb_spec_value   .
          WHEN 64. MOVE   <lv_value> TO <lw_excel>-ebeln2  .
          WHEN 65. MOVE   <lv_value> TO <lw_excel>-ebelp   .
          WHEN 66. MOVE   <lv_value> TO <lw_excel>-txz01   .
          WHEN 67. MOVE   <lv_value> TO <lw_excel>-matnr   .
          WHEN 68. MOVE   <lv_value> TO <lw_excel>-matnr2  .
          WHEN 69. MOVE   <lv_value> TO <lw_excel>-bukrs2  .
          WHEN 70. MOVE   <lv_value> TO <lw_excel>-werks   .
          WHEN 71. MOVE   <lv_value> TO <lw_excel>-lgort   .
          WHEN 72. MOVE   <lv_value> TO <lw_excel>-bednr   .
          WHEN 73. MOVE   <lv_value> TO <lw_excel>-matkl   .
          WHEN 74. MOVE   <lv_value> TO <lw_excel>-infnr   .
          WHEN 75. MOVE   <lv_value> TO <lw_excel>-ktmng   .
          WHEN 76. MOVE   <lv_value> TO <lw_excel>-menge   .
          WHEN 77. MOVE   <lv_value> TO <lw_excel>-meins   .
          WHEN 78. MOVE   <lv_value> TO <lw_excel>-bprme   .
          WHEN 79. MOVE   <lv_value> TO <lw_excel>-bpumz   .
          WHEN 80. MOVE   <lv_value> TO <lw_excel>-bpumn   .
          WHEN 81. MOVE   <lv_value> TO <lw_excel>-umrez   .
          WHEN 82. MOVE   <lv_value> TO <lw_excel>-umren   .
          WHEN 83. MOVE   <lv_value> TO <lw_excel>-netpr   .
          WHEN 84. MOVE   <lv_value> TO <lw_excel>-peinh   .
          WHEN 85. MOVE   <lv_value> TO <lw_excel>-netwr   .
          WHEN 86. MOVE   <lv_value> TO <lw_excel>-brtwr   .
          WHEN 87. MOVE   <lv_value> TO <lw_excel>-webaz   .
          WHEN 88. MOVE   <lv_value> TO <lw_excel>-mwskz   .
          WHEN 89. MOVE   <lv_value> TO <lw_excel>-spinf   .
          WHEN 90. MOVE   <lv_value> TO <lw_excel>-prsdr   .
          WHEN 91. MOVE   <lv_value> TO <lw_excel>-mahnz   .
          WHEN 92. MOVE   <lv_value> TO <lw_excel>-mahn1   .
          WHEN 93. MOVE   <lv_value> TO <lw_excel>-mahn2   .
          WHEN 94. MOVE   <lv_value> TO <lw_excel>-mahn3   .
          WHEN 95. MOVE   <lv_value> TO <lw_excel>-uebto   .
          WHEN 96. MOVE   <lv_value> TO <lw_excel>-uebtk   .
          WHEN 97. MOVE   <lv_value> TO <lw_excel>-untto   .
          WHEN 98. MOVE   <lv_value> TO <lw_excel>-elikz   .
          WHEN 99. MOVE   <lv_value> TO <lw_excel>-erekz   .
          WHEN 100. MOVE   <lv_value> TO <lw_excel>-pstyp  .
          WHEN 101. MOVE   <lv_value> TO <lw_excel>-knttp  .
          WHEN 102. MOVE   <lv_value> TO <lw_excel>-kzvbr  .
          WHEN 103. MOVE   <lv_value> TO <lw_excel>-wepos  .
          WHEN 104. MOVE   <lv_value> TO <lw_excel>-weunb  .
          WHEN 105. MOVE   <lv_value> TO <lw_excel>-repos  .
          WHEN 106. MOVE   <lv_value> TO <lw_excel>-webre  .
          WHEN 107. MOVE   <lv_value> TO <lw_excel>-konnr2 .
          WHEN 108. MOVE   <lv_value> TO <lw_excel>-ktpnr  .
          WHEN 109. MOVE   <lv_value> TO <lw_excel>-abftz  .
          WHEN 110. MOVE   <lv_value> TO <lw_excel>-etfz1  .
          WHEN 111. MOVE   <lv_value> TO <lw_excel>-etfz2  .
          WHEN 112. MOVE   <lv_value> TO <lw_excel>-lmein  .
          WHEN 113. MOVE   <lv_value> TO <lw_excel>-zwert  .
          WHEN 114. MOVE   <lv_value> TO <lw_excel>-navnw  .
          WHEN 115. MOVE   <lv_value> TO <lw_excel>-abmng  .
          WHEN 116.REPLACE ALL OCCURRENCES OF '-' IN <lv_value> WITH space.  MOVE   <lv_value> TO <lw_excel>-prdat  .
          WHEN 117. MOVE   <lv_value> TO <lw_excel>-bstyp2 .
          WHEN 118. MOVE   <lv_value> TO <lw_excel>-effwr  .
          WHEN 119. MOVE   <lv_value> TO <lw_excel>-stafo2 .
          WHEN 120. MOVE   <lv_value> TO <lw_excel>-plifz  .
          WHEN 121. MOVE   <lv_value> TO <lw_excel>-ntgew  .
          WHEN 122. MOVE   <lv_value> TO <lw_excel>-gewei  .
          WHEN 123. MOVE   <lv_value> TO <lw_excel>-arsnr  .
          WHEN 124. MOVE   <lv_value> TO <lw_excel>-arsps  .
          WHEN 125. MOVE   <lv_value> TO <lw_excel>-ean11  .
          WHEN 126. MOVE   <lv_value> TO <lw_excel>-ko_prctr .
          WHEN 127. MOVE   <lv_value> TO <lw_excel>-brgew    .
          WHEN 128. MOVE   <lv_value> TO <lw_excel>-volum    .
          WHEN 129. MOVE   <lv_value> TO <lw_excel>-voleh    .
          WHEN 130. MOVE   <lv_value> TO <lw_excel>-inco1x   .
          WHEN 131. MOVE   <lv_value> TO <lw_excel>-inco2x   .
          WHEN 132. MOVE   <lv_value> TO <lw_excel>-packno   .
          WHEN 133. MOVE   <lv_value> TO <lw_excel>-gnetwr   .
          WHEN 134. MOVE   <lv_value> TO <lw_excel>-stapo2   .
          WHEN 135. MOVE   <lv_value> TO <lw_excel>-uebpo    .
          WHEN 136. MOVE   <lv_value> TO <lw_excel>-cuobj    .
          WHEN 137. MOVE   <lv_value> TO <lw_excel>-druhr    .
          WHEN 138. MOVE   <lv_value> TO <lw_excel>-drunr    .
          WHEN 139. MOVE   <lv_value> TO <lw_excel>-abelp    .
          WHEN 140. MOVE   <lv_value> TO <lw_excel>-anzpu    .
          WHEN 141. MOVE   <lv_value> TO <lw_excel>-mhdrz    .
          WHEN 142. MOVE   <lv_value> TO <lw_excel>-anfnr    .
          WHEN 143. MOVE   <lv_value> TO <lw_excel>-anfps    .
          WHEN 144. MOVE   <lv_value> TO <lw_excel>-banfn    .
          WHEN 145. MOVE   <lv_value> TO <lw_excel>-bnfpo    .
          WHEN 146. MOVE   <lv_value> TO <lw_excel>-mtart    .
          WHEN 147. MOVE   <lv_value> TO <lw_excel>-kzwi1    .
          WHEN 148. MOVE   <lv_value> TO <lw_excel>-kzwi2    .
          WHEN 149. MOVE   <lv_value> TO <lw_excel>-kzwi3    .
          WHEN 150. MOVE   <lv_value> TO <lw_excel>-kzwi4    .
          WHEN 151. MOVE   <lv_value> TO <lw_excel>-kzwi5    .
          WHEN 152. MOVE   <lv_value> TO <lw_excel>-kzwi6    .
          WHEN 153. MOVE   <lv_value> TO <lw_excel>-mfzhi    .
          WHEN 154. MOVE   <lv_value> TO <lw_excel>-ffzhi    .
          WHEN 155. MOVE   <lv_value> TO <lw_excel>-lfret    .
          WHEN 156. MOVE   <lv_value> TO <lw_excel>-nrfhg    .
          WHEN 157. MOVE   <lv_value> TO <lw_excel>-bonba    .
          WHEN 158. MOVE   <lv_value> TO <lw_excel>-afnam    .
          WHEN 159. MOVE   <lv_value> TO <lw_excel>-tzonrc   .
          WHEN 160. MOVE   <lv_value> TO <lw_excel>-iprkz    .
          WHEN 161. MOVE   <lv_value> TO <lw_excel>-ccomp    .
          WHEN 162. MOVE   <lv_value> TO <lw_excel>-reslo    .
          WHEN 163. MOVE   <lv_value> TO <lw_excel>-prio_urg .
          WHEN 164. MOVE   <lv_value> TO <lw_excel>-prio_req .
          WHEN 165.
            REPLACE ALL OCCURRENCES OF '-' IN <lv_value> WITH space.
            MOVE   <lv_value> TO <lw_excel>-creationdate.
          WHEN 166. MOVE   <lv_value> TO <lw_excel>-creationtime.
          WHEN 167. MOVE   <lv_value> TO <lw_excel>-kostl.
          WHEN 168. MOVE   <lv_value> TO <lw_excel>-sakto.
          WHEN 169. MOVE   <lv_value> TO <lw_excel>-gsber.
        ENDCASE.
      ENDIF.
    ENDDO.
  ENDLOOP.



ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_OPEN_DATOS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f4_open_datos .
  DATA: uno(200), dos(4).
  DATA: ls_doc TYPE gty_sal.
  DATA: file_name TYPE epsf-epsfilnam,
        dir_name  TYPE epsf-epsdirnam.
  DATA: lv_mtime TYPE sy-tabix,
        lv_dates TYPE sy-datum,
        lv_times TYPE char8.
  DATA s_file TYPE salfile-longname.
  DATA xlines TYPE sy-tabix VALUE 2000.
  SELECT SINGLE low INTO p_fsnam FROM tvarvc WHERE name = gc_v_serv_dir_mat_data.
  TRANSLATE p_fsnam TO LOWER CASE.
  CONCATENATE p_fsnam '/' INTO s_file.
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
        dir_name = p_fsnam.
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
        IF ls_file-name(3) EQ 'OC_'.
          APPEND ls_doc TO it_filedoc.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFORM.


"Etiqueta de ajuste: FRONT, INICIO: Adición de subrutina para obtención de la ruta del archivo
"en el frontend
FORM get_filepath_frontend
  CHANGING
    ch_v_filepath  LIKE p_fsnam.

  DATA: lt_file_table    TYPE filetable,
        ls_file_table    LIKE LINE OF lt_file_table,
        lv_rc            TYPE i,
        lv_user_action   TYPE i,
        lv_file_encoding TYPE abap_encoding.
  "lv_file_sele_ok   type i.

  CLEAR: ch_v_filepath.

  CLEAR: lt_file_table[],
         lv_rc,
         lv_user_action,
         lv_file_encoding.
  "lv_file_sele_ok = 4.
  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title            = 'Archivo'
      default_extension       = '.xlsx'
      "default_filename        =
      "file_filter             = cl_gui_frontend_services=>filetype_excel
      "with_encoding           =
      "initial_directory       =
      multiselection          = ' ' "no se permite selección multiple
    CHANGING
      file_table              = lt_file_table[]
      rc                      = lv_rc
      user_action             = lv_user_action
      file_encoding           = lv_file_encoding
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5.
  IF lv_user_action EQ 9.
    "El usuario presionó el botón "Cancelar"
    MESSAGE 'Acción Cancelada por el Usuario' TYPE 'S'
      DISPLAY LIKE 'E'.

  ELSEIF ( lv_user_action EQ 0 ) AND ( lv_rc EQ -1 ).
    "El método retornó error
    "message id sy-msgid type sy-msgty number sy-msgno
    "           with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    MESSAGE 'Error al tratar de abrir el archivo' TYPE 'S'
      DISPLAY LIKE 'E'.

  ELSEIF ( lv_user_action EQ 0 ) AND ( lv_rc NE -1 ).

    IF lv_rc EQ 0.
      MESSAGE 'Seleccione 1 archivo por favor' TYPE 'S'
        DISPLAY LIKE 'E'.
    ELSEIF lv_rc GT 1.
      MESSAGE 'Por favor, seleccione sólo 1 archivo' TYPE 'S'
        DISPLAY LIKE 'E'.
    ELSEIF lv_rc EQ 1.

      CLEAR ls_file_table.
      READ TABLE lt_file_table[] INTO ls_file_table INDEX 1.
      IF sy-subrc NE 0.
        MESSAGE 'Error al tratar de abrir el archivo' TYPE 'S'
          DISPLAY LIKE 'E'.
      ELSE.
        ch_v_filepath = ls_file_table-filename."Se asigna la ruta al
        "parámetro
        "lv_file_sele_ok = 0.
      ENDIF.

    ENDIF."verif. cantidad de archivos seleccionados

  ENDIF."Verif. resultado "file_open_dialog"

ENDFORM."get_filepath_frontend
"Etiqueta de ajuste: FRONT, FIN: Adición de subrutina para obtención de la ruta del archivo
"en el frontend

"Etiqueta de ajuste: FRONT, INICIO: Adición de subrutina para carga de datos desde el archivo
"en el frontend
*&---------------------------------------------------------------------*
*&      Form  UPLOAD_EXCEL_FRONTEND
*&---------------------------------------------------------------------*
*       Carga Excel desde el frontend
*----------------------------------------------------------------------*
FORM upload_excel_frontend.
*  DATA lv_filename      TYPE string.
  FIELD-SYMBOLS: <fs_tab> TYPE STANDARD TABLE.
  DATA: lh_archivo TYPE string,
        lh_tabint  TYPE tabname,
        h_t_salida TYPE tabname VALUE 'LT_SALIDA'.
  lh_tabint = h_t_salida.
  ASSIGN (lh_tabint) TO <fs_tab>.
  lv_filename = p_fsnam.

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

  " Upload from workstation
  cl_gui_frontend_services=>gui_upload(
    EXPORTING
      filename                = iv_file_path
      filetype                = 'BIN'
    IMPORTING
      filelength              = lv_filelength
    CHANGING
      data_tab                = lt_records
    EXCEPTIONS
      file_open_error         = 1                " File does not exist and cannot be opened
      file_read_error         = 2                " Error when reading file
      no_batch                = 3                " Cannot execute front-end function in background
      gui_refuse_filetransfer = 4                " Incorrect front end or error on front end
      invalid_type            = 5                " Incorrect parameter FILETYPE
      no_authority            = 6                " No upload authorization
      unknown_error           = 7                " Unknown error
      bad_data_format         = 8                " Cannot Interpret Data in File
      header_not_allowed      = 9                " Invalid header
      separator_not_allowed   = 10               " Invalid separator
      header_too_long         = 11               " Header information currently restricted to 1023 bytes
      unknown_dp_error        = 12               " Error when calling data provider
      access_denied           = 13               " Access to File Denied
      dp_out_of_memory        = 14               " Not enough memory in data provider
      disk_full               = 15               " Storage medium is full.
      dp_timeout              = 16               " Data provider timeout
      not_supported_by_gui    = 17               " GUI does not support this
      error_no_gui            = 18               " GUI not available
      OTHERS                  = 19
  ).
  IF sy-subrc NE 0.
    MESSAGE 'Error durante la carga del archivo'
      TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.



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
    ASSIGN lo_data_ref->* TO <ft_data>.
  ENDIF.
  iv_hdr_lines = 1.
  IF <ft_data> IS ASSIGNED.
    CLEAR gt_salida[].
    LOOP AT <ft_data> ASSIGNING FIELD-SYMBOL(<fs_data>).
      CHECK sy-tabix GT iv_hdr_lines.
      APPEND INITIAL LINE TO <ft_table> ASSIGNING <fs_line>.
      DATA(lv_ref) = REF #( <fs_line> ).
      " Convert to CSV line
      CLEAR lv_line.
      DO.
        ASSIGN COMPONENT sy-index OF STRUCTURE <fs_data> TO <fs_field>.
        IF sy-subrc NE 0.
          EXIT.
        ENDIF.
        IF sy-index EQ 1.
          lv_line = <fs_field>.
        ELSE.
          lv_line = |{ lv_line }{ mv_separator }{ <fs_field> }|.
        ENDIF.
      ENDDO.
      " Convert CSV line to structure
*      PERFORM componentes_lineas USING lv_line CHANGING wa_salida.
*      APPEND wa_salida TO gt_salida.
*      convert_line_to_structure( EXPORTING iv_line = lv_line it_components = lt_components ir_line = lv_ref ).
    ENDLOOP.
  ELSE.
  ENDIF.


ENDFORM. "upload_excel_frontend
FORM show_alv .
  PERFORM alv_group.
  PERFORM alv_fieldcat.
  PERFORM alv_layout.
  PERFORM alv_display.

ENDFORM.
**----------------------------------------------------------------------*
FORM alv_group .
  APPEND VALUE #( sp_group = 'A'
                    text     = TEXT-001 )
                    TO gt_slis_group.
ENDFORM.
*&---------------------------------------------------------------------*.
FORM alv_fieldcat .

  REFRESH gt_slis_fieldcat.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name         = sy-repid
      i_internal_tabname     = 'ZMM_S_MQA_CARGA_PEDIDOS'
      i_structure_name       = 'ZMM_S_MQA_CARGA_PEDIDOS'
      i_bypassing_buffer     = 'X'
      i_buffer_active        = ' '
    CHANGING
      ct_fieldcat            = gt_slis_fieldcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
FORM alv_layout .
  CLEAR gs_slis_layout.
  gs_slis_layout-colwidth_optimize   = 'X'.
  gs_slis_layout-zebra               = 'X'.
*  gs_slis_layout-box_fieldname       = 'CHECK'.
*  gs_slis_layout-get_selinfos        = 'X'.
*  gs_slis_layout-f2code              = 'BEAN' .
*  gs_slis_layout-confirmation_prompt = 'X'.
*  gs_slis_layout-key_hotspot         = 'X'.
*  gs_slis_layout-info_fieldname      = 'COL'.
ENDFORM.
*&---------------------------------------------------------------------*

FORM alv_display.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
*     i_callback_top_of_page   = 'TOP_OF_PAGE'
*     i_callback_pf_status_set = 'PF_STATUS'
*     i_callback_user_command  = 'USER_COMMAND'
      is_layout          = gs_slis_layout
      it_fieldcat        = gt_slis_fieldcat
      it_special_groups  = gt_slis_group
      i_save             = 'X'
    TABLES
      t_outtab           = lt_data.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.

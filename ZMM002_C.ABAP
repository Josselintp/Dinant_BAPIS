*&---------------------------------------------------------------------*
*& Report zr_mm_mqa_u_carga_mat
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zr_mm_mqa_u_carga_mat LINE-SIZE 700.
INCLUDE zr_mm_mqa_u_carga_mat_c1.
TYPES: ty_contador TYPE n LENGTH 6.

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
  ls_reg_mara TYPE zmm_reg_mara,
  lt_reg_mara TYPE TABLE OF  zmm_reg_mara,
  ls_reg_marc TYPE zmm_reg_marc,
  lt_reg_marc TYPE TABLE OF  zmm_reg_marc,
  ls_reg_mard TYPE zmm_reg_mard,
  lt_reg_mard TYPE TABLE OF  zmm_reg_mard,
  ls_reg_mvke TYPE zmm_reg_mvke,
  lt_reg_mvke TYPE TABLE OF  zmm_reg_mvke,
  ls_reg_mbew TYPE zmm_reg_mbew,
  lt_reg_mbew TYPE TABLE OF  zmm_reg_mbew,
  ls_reg_mlan TYPE zmm_reg_mlan,
  lt_reg_mlan TYPE TABLE OF  zmm_reg_mlan.


DATA: lv_rojo(4)  TYPE c VALUE '@0A@',
      lv_verde(4) TYPE c VALUE '@08@'.
*----------------------------------------------------------------------*

TYPES: BEGIN OF ty_error_mat,
         matnr TYPE mara-matnr,
       END OF ty_error_mat,
       tt_error_mat TYPE HASHED TABLE OF ty_error_mat WITH UNIQUE KEY matnr.

TYPES: BEGIN OF ty_files_mat,
         contador TYPE ty_contador,
         BEGIN OF tabla,
           mara TYPE salfldir-name,
           makt TYPE salfldir-name,
           marc TYPE salfldir-name,
           mard TYPE salfldir-name,
           mvke TYPE salfldir-name,
           mbew TYPE salfldir-name,
           marm TYPE salfldir-name,
           mlan TYPE salfldir-name,

         END OF tabla,
       END OF ty_files_mat,
       tt_files_mat TYPE SORTED TABLE OF ty_files_mat WITH UNIQUE KEY contador.

FIELD-SYMBOLS: <tt_mara> TYPE STANDARD TABLE.
FIELD-SYMBOLS: <lv_field> TYPE any.

TYPES: tt_mara TYPE STANDARD TABLE OF mara WITH DEFAULT KEY.
TYPES: tt_makt TYPE STANDARD TABLE OF makt WITH DEFAULT KEY
                                     WITH NON-UNIQUE SORTED KEY s1
                                            COMPONENTS matnr spras.
TYPES: tt_marm TYPE STANDARD TABLE OF marm WITH DEFAULT KEY
                                     WITH NON-UNIQUE SORTED KEY s1
                                            COMPONENTS matnr meinh.
TYPES: tt_marc TYPE STANDARD TABLE OF marc WITH DEFAULT KEY.
TYPES: tt_mard TYPE STANDARD TABLE OF mard WITH DEFAULT KEY.
TYPES: tt_mvke TYPE STANDARD TABLE OF mvke WITH DEFAULT KEY.
TYPES: tt_mbew TYPE STANDARD TABLE OF mbew WITH DEFAULT KEY.
TYPES: tt_mlan TYPE STANDARD TABLE OF mlan WITH DEFAULT KEY.
DATA lv_filename      TYPE string.
DATA dcont TYPE ty_contador.
PARAMETERS preffl TYPE rlgrap-filename OBLIGATORY DEFAULT 'YY21_'. " Prefijo Archivo
PARAMETERS: pdir TYPE rlgrap-filename  DEFAULT '/mnt/sapshare/temp'. "OBLIGATORY
*PARAMETERS: p_fill LIKE rlgrap-filename .
SELECT-OPTIONS scont FOR dcont OBLIGATORY DEFAULT '000001' TO '000100'.


START-OF-SELECTION.
  PARAMETERS tc_mara AS CHECKBOX DEFAULT 'X'.
  PARAMETERS tc_marc AS CHECKBOX DEFAULT 'X'.
  PARAMETERS tc_mard AS CHECKBOX DEFAULT 'X'.
  PARAMETERS tc_mvke AS CHECKBOX DEFAULT 'X'.
  PARAMETERS tc_mbew AS CHECKBOX DEFAULT 'X'.
  PARAMETERS tc_mlan AS CHECKBOX DEFAULT 'X'.

  PARAMETERS sprinerr AS CHECKBOX DEFAULT 'X'.
  PARAMETERS fileerr   TYPE rlgrap-filename DEFAULT 'MAT_01_05' OBLIGATORY.


CLASS lcl_program DEFINITION CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES: tt_filedir TYPE STANDARD TABLE OF salfldir WITH DEFAULT KEY.
    " PRINCIPAL
    " PRINCIPAL
    CLASS-METHODS main.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-METHODS get_files_of_dir
      IMPORTING
        dir         TYPE rlgrap-filename
        filt_prefix TYPE rlgrap-filename
      RETURNING
        VALUE(r)    TYPE tt_files_mat.
    CLASS-METHODS validar_filtro
      IMPORTING
        lfile       TYPE string
        filt_prefix TYPE string
      RETURNING
        VALUE(r)    TYPE abap_bool.
    CLASS-METHODS descomponer_name
      IMPORTING
        namefile TYPE salfldir-name
      EXPORTING
        contador TYPE ty_files_mat-contador
        tabla    TYPE ty_files_mat-tabla-mara.
    CLASS-METHODS procesar_contador
      IMPORTING
        files TYPE ty_files_mat.

    CLASS-METHODS read_file_server
      IMPORTING
        filename TYPE c
      RETURNING
        VALUE(r) TYPE xstring.
    CLASS-METHODS file_to_it
      IMPORTING
        filename TYPE c
      CHANGING
        atable   TYPE ANY TABLE.

    CLASS-METHODS procesar_file_mara
      IMPORTING
        contador  TYPE ty_contador
        file_mara TYPE salfldir-name
        file_marm TYPE salfldir-name
        file_makt TYPE salfldir-name.


    CLASS-METHODS procesar_file_marc
      IMPORTING
        contador  TYPE ty_contador
        file_marc TYPE salfldir-name.

    CLASS-METHODS procesar_file_mard
      IMPORTING
        contador  TYPE ty_contador
        file_mard TYPE salfldir-name.

    CLASS-METHODS procesar_file_mvke
      IMPORTING
        contador  TYPE ty_contador
        file_mvke TYPE salfldir-name.

    CLASS-METHODS procesar_file_mbew
      IMPORTING
        contador  TYPE ty_contador
        file_mbew TYPE salfldir-name.

    CLASS-METHODS procesar_file_mlan
      IMPORTING
        contador  TYPE ty_contador
        file_mlan TYPE salfldir-name.


    CLASS-METHODS call_bapi_mara
      IMPORTING
        ti_makt TYPE tt_makt
        ti_marm TYPE tt_marm
        ti_mara TYPE tt_mara.

    CLASS-METHODS call_bapi_marc
      IMPORTING reprocesar TYPE abap_bool
                ti_marc    TYPE tt_marc
      EXPORTING reproceso  TYPE tt_marc .

    CLASS-METHODS call_bapi_mard
      IMPORTING reprocesar TYPE abap_bool
                ti_mard    TYPE tt_mard
      EXPORTING reproceso  TYPE tt_mard .

    CLASS-METHODS call_bapi_mvke
      IMPORTING
        ti_mvke TYPE tt_mvke.

    CLASS-METHODS call_bapi_mbew
      IMPORTING reprocesar TYPE abap_bool
                ti_mbew    TYPE tt_mbew
      EXPORTING reproceso  TYPE tt_mbew .

    CLASS-METHODS call_bapi_mlan
      IMPORTING reprocesar TYPE abap_bool
                ti_mlan    TYPE tt_mlan
      EXPORTING reproceso  TYPE tt_mlan .


    CLASS-METHODS generar_vistas
      IMPORTING
        pstat    TYPE marc-pstat
        table    TYPE string
      CHANGING
        headdata TYPE bapimathead.

    CLASS-METHODS reportar_error
      IMPORTING
        i_matnr TYPE marc-matnr.
    CLASS-METHODS respaldar_errores
      IMPORTING
        dir         TYPE rlgrap-filename
        filename    TYPE rlgrap-filename
        filt_prefix TYPE rlgrap-filename.

    CLASS-DATA ti_errores TYPE tt_error_mat.
ENDCLASS.


START-OF-SELECTION.
  lcl_program=>main(  ).

CLASS lcl_program IMPLEMENTATION.
  METHOD main.

    WRITE: /'Leyendo Archivos'.
    DATA(archivosjuegos) = get_files_of_dir(
                        dir         = pdir
                        filt_prefix = preffl ).

    BREAK atrava01.

    LOOP AT archivosjuegos ASSIGNING FIELD-SYMBOL(<archivos>)
           WHERE contador IN scont.
      WRITE: /'Procesar Archivo:', <archivos>-contador.
      procesar_contador( files = <archivos> ).
    ENDLOOP.

    IF ti_errores IS NOT INITIAL AND fileerr IS NOT INITIAL.
      respaldar_errores( filename = fileerr filt_prefix = preffl
                          dir         = pdir ).
    ENDIF.
  ENDMETHOD.

  METHOD get_files_of_dir.
    DATA s_file TYPE salfile-longname.
    DATA files    TYPE tt_filedir.

    s_file =  dir && '/'.

    CALL FUNCTION 'RZL_READ_DIR_LOCAL'
      EXPORTING
        name     = s_file
        nrlines  = 100000
      TABLES
        file_tbl = files
      EXCEPTIONS
        OTHERS   = 0.
    IF preffl IS NOT INITIAL.
      LOOP AT files ASSIGNING FIELD-SYMBOL(<files>).
        IF NOT validar_filtro( lfile       = CONV #( <files>-name )
                               filt_prefix = CONV #( filt_prefix ) ).
          <files>-size = 0.
        ENDIF.
      ENDLOOP.

    ENDIF.
    DELETE files WHERE size = 0.

    LOOP AT files ASSIGNING <files>.
      descomponer_name( EXPORTING namefile = <files>-name
                        IMPORTING contador = DATA(imp_contador)
                                  tabla    = DATA(imp_tabla) ).

      READ TABLE r ASSIGNING FIELD-SYMBOL(<r>)
          WITH TABLE KEY contador = imp_contador.
      IF <r> IS NOT ASSIGNED.
        INSERT VALUE #( contador = imp_contador ) INTO TABLE r ASSIGNING <r>.
      ENDIF.
      CASE imp_tabla.
        WHEN 'MARA'. <r>-tabla-mara = <files>-name.
        WHEN 'MLAN'. <r>-tabla-mlan = <files>-name.
        WHEN 'MAKT'. <r>-tabla-makt = <files>-name.
        WHEN 'MARC'. <r>-tabla-marc = <files>-name.
        WHEN 'MARD'. <r>-tabla-mard = <files>-name.
        WHEN 'MVKE'. <r>-tabla-mvke = <files>-name.
        WHEN 'MARD'. <r>-tabla-mard = <files>-name.
        WHEN 'MBEW'. <r>-tabla-mbew = <files>-name.
        WHEN 'MARM'. <r>-tabla-marm = <files>-name.
      ENDCASE.

      UNASSIGN <r>.
    ENDLOOP.
  ENDMETHOD.


  METHOD validar_filtro.
    DATA(lenfile) = strlen( lfile ).
    DATA(lenfilt) = strlen( filt_prefix ).

    IF lenfile < ( lenfilt + 10 ) OR  lenfile < lenfilt. " Longitud minima
      EXIT.
    ENDIF.

    IF lenfile < lenfilt. " Longitud minima
      EXIT.
    ENDIF.
    DATA(lv_substring) = substring( val = lfile off = 0 len = lenfilt ). " Extracts 'World'
    IF lv_substring = filt_prefix.
      r = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD descomponer_name.
    DATA(lnamefile) = namefile.
    REPLACE FIRST OCCURRENCE OF preffl IN lnamefile WITH space.
    REPLACE FIRST OCCURRENCE OF '.dat' IN lnamefile WITH space.
    tabla = lnamefile(4).
    contador = lnamefile+4(6).
  ENDMETHOD.


  METHOD procesar_contador.

    procesar_file_mara( contador  = files-contador
                        file_mara = files-tabla-mara
                        file_marm = files-tabla-marm

                        file_makt = files-tabla-makt ).

    procesar_file_marc( contador  = files-contador
                        file_marc = files-tabla-marc  ).


    procesar_file_mard( contador  = files-contador
                        file_mard = files-tabla-mard  ).


    procesar_file_mvke( contador  = files-contador
                        file_mvke = files-tabla-mvke  ).


    procesar_file_mbew( contador  = files-contador
                        file_mbew = files-tabla-mbew ).

    procesar_file_mlan( contador  = files-contador
                           file_mlan = files-tabla-mlan  ).

  ENDMETHOD.


  METHOD procesar_file_mara.
    DATA ti_mara TYPE tt_mara.
    DATA ti_makt TYPE tt_makt.
    DATA ti_marm TYPE tt_marm.

    CHECK tc_mara = 'X'.
    GET RUN TIME FIELD DATA(p1).
    WRITE: /'Procesar Archivo MARA', contador.

    file_to_it( EXPORTING filename = |{ pdir }/{ file_mara }|
                CHANGING  atable = ti_mara ).

    file_to_it( EXPORTING filename = |{ pdir }/{ file_makt }|
                CHANGING  atable = ti_makt ).

    file_to_it( EXPORTING filename = |{ pdir }/{ file_marm }|
                CHANGING  atable = ti_marm ).

    call_bapi_mara( ti_makt = ti_makt
                    ti_marm = ti_marm
                    ti_mara = ti_mara ).

    GET RUN TIME FIELD DATA(p2).
    p2 = p2 - p1.
    WRITE: /'Procesado Archivo MARA Time:', p2.
  ENDMETHOD.

  METHOD procesar_file_marc.
    DATA ti_marc TYPE tt_marc.

    CHECK tc_marc = 'X'.
    GET RUN TIME FIELD DATA(p1).
    WRITE: /'Procesar Archivo MARC', contador.

    file_to_it( EXPORTING filename = |{ pdir }/{ file_marc }|
                CHANGING  atable = ti_marc ).

    call_bapi_marc( EXPORTING ti_marc = ti_marc
                              reprocesar = abap_true
                    IMPORTING reproceso = DATA(reproceso) ).
    CLEAR ti_marc.
    IF reproceso IS NOT INITIAL.
      call_bapi_marc( EXPORTING ti_marc = reproceso
                                reprocesar = abap_false
                      IMPORTING reproceso = reproceso ).
    ENDIF.

    GET RUN TIME FIELD DATA(p2).
    p2 = p2 - p1.
    WRITE: /'Procesado Archivo MARC Time:', p2.
  ENDMETHOD.

  METHOD procesar_file_mard.
    DATA ti_mard TYPE tt_mard.

    CHECK tc_mard = 'X'.
    GET RUN TIME FIELD DATA(p1).
    WRITE: /'Procesar Archivo MARD', contador.

    file_to_it( EXPORTING filename = |{ pdir }/{ file_mard }|
                CHANGING  atable = ti_mard ).

    call_bapi_mard( EXPORTING ti_mard = ti_mard
                              reprocesar = abap_true
                    IMPORTING reproceso = DATA(reproceso) ).
    CLEAR ti_mard.
    IF reproceso IS NOT INITIAL.
      call_bapi_mard( EXPORTING ti_mard = reproceso
                                reprocesar = abap_false
                      IMPORTING reproceso = reproceso ).
    ENDIF.
    GET RUN TIME FIELD DATA(p2).
    p2 = p2 - p1.
    WRITE: /'Procesado Archivo MARD Time:', p2.
  ENDMETHOD.

  METHOD procesar_file_mbew.
    DATA ti_mbew TYPE tt_mbew.

    CHECK tc_mbew = 'X'.
    GET RUN TIME FIELD DATA(p1).
    WRITE: /'Procesar Archivo MBEW', contador.

    file_to_it( EXPORTING filename = |{ pdir }/{ file_mbew }|
                CHANGING  atable = ti_mbew ).

    call_bapi_mbew( EXPORTING ti_mbew = ti_mbew
                              reprocesar = abap_true
                    IMPORTING reproceso = DATA(reproceso) ).
    CLEAR ti_mbew.
    IF reproceso IS NOT INITIAL.
      call_bapi_mbew( EXPORTING ti_mbew = reproceso
                                reprocesar = abap_false
                      IMPORTING reproceso = reproceso ).
    ENDIF.
    GET RUN TIME FIELD DATA(p2).
    p2 = p2 - p1.
    WRITE: /'Procesado Archivo MBEW Time:', p2.
  ENDMETHOD.

  METHOD procesar_file_mvke.
    DATA ti_mvke TYPE tt_mvke.

    CHECK tc_mvke = 'X'.
    GET RUN TIME FIELD DATA(p1).
    WRITE: /'Procesar Archivo MVKE', contador.

    file_to_it( EXPORTING filename = |{ pdir }/{ file_mvke }|
                CHANGING  atable = ti_mvke ).

    call_bapi_mvke( ti_mvke = ti_mvke ).
    GET RUN TIME FIELD DATA(p2).
    p2 = p2 - p1.
    WRITE: /'Procesado Archivo MVKE Time:', p2.
  ENDMETHOD.
  METHOD procesar_file_mlan.
    DATA ti_mlan TYPE tt_mlan.

    CHECK tc_mlan = 'X'.
    GET RUN TIME FIELD DATA(p1).
    WRITE: /'Procesar Archivo MLAN', contador.

    file_to_it( EXPORTING filename = |{ pdir }/{ file_mlan }|
                CHANGING  atable = ti_mlan ).

    call_bapi_mlan( EXPORTING ti_mlan = ti_mlan
                              reprocesar = abap_true
                    IMPORTING reproceso = DATA(reproceso) ).
    CLEAR ti_mlan.
    IF reproceso IS NOT INITIAL.
      call_bapi_mlan( EXPORTING ti_mlan = reproceso
                                reprocesar = abap_false
                      IMPORTING reproceso = reproceso ).
    ENDIF.

    GET RUN TIME FIELD DATA(p2).
    p2 = p2 - p1.
    WRITE: /'Procesado Archivo MLAN Time:', p2.
  ENDMETHOD.

  METHOD file_to_it.
    DATA(xxml) = read_file_server( filename ).
    CALL TRANSFORMATION id  " z_my_xml_transformation is the ID
        SOURCE XML xxml
        RESULT table = atable.
  ENDMETHOD.

  METHOD read_file_server.

    OPEN DATASET filename FOR INPUT IN BINARY MODE.
    IF sy-subrc NE 0.
      MESSAGE 'Error Abriendo el Archivo' TYPE 'E'.
    ENDIF.

    READ DATASET filename INTO r.

    CLOSE DATASET filename.

  ENDMETHOD.

  METHOD call_bapi_mara.
    DATA obapi TYPE REF TO lcl_bapi_material. " Nuevo llamado a la BAPI

    DATA: ls_bapi_te_mara  TYPE bapi_te_mara,
          ls_bapi_te_marax TYPE bapi_te_marax.
    DATA ll_extensionin  TYPE bapiparex.
    DATA ll_extensioninx  TYPE bapiparexx.


    LOOP AT ti_mara ASSIGNING FIELD-SYMBOL(<mara>).
      obapi = NEW lcl_bapi_material(  ).
      CLEAR: ls_bapi_te_mara, ls_bapi_te_marax, ll_extensionin, ll_extensioninx.
      " JOSELIN Colocar el Mapeo para MARA y MAKT
*  Segmento de cabecera con info de control
      obapi->headdata-material    = <mara>-matnr.
      obapi->headdata-matl_type   = <mara>-mtart.
      obapi->headdata-ind_sector  = <mara>-mbrsh.

      SEARCH <mara>-pstat FOR 'K'.
      IF sy-subrc = 0.
        obapi->headdata-basic_view       = 'X'.
      ENDIF.
      SEARCH <mara>-pstat FOR 'V'.
      IF sy-subrc = 0.
        obapi->headdata-sales_view       = 'X'.
      ENDIF.
      SEARCH <mara>-pstat FOR 'Q'.
      IF sy-subrc = 0.
        obapi->headdata-quality_view       = 'X'.
      ENDIF.
      SEARCH <mara>-pstat FOR 'E'.
      IF sy-subrc = 0.
        obapi->headdata-purchase_view       = 'X'.
      ENDIF.
      SEARCH <mara>-pstat FOR 'P'.
      IF sy-subrc = 0.
        obapi->headdata-forecast_view       = 'X'.
      ENDIF.
      SEARCH <mara>-pstat FOR 'A'.
      IF sy-subrc = 0.
        obapi->headdata-work_sched_view       = 'X'.
      ENDIF.
      SEARCH <mara>-pstat FOR 'L'.
      IF sy-subrc = 0.
        obapi->headdata-storage_view       = 'X'.
      ENDIF.
      SEARCH <mara>-pstat FOR 'S'.
      IF sy-subrc = 0.
        obapi->headdata-warehouse_view       = 'X'.
      ENDIF.
      SEARCH <mara>-pstat FOR 'B'.
      IF sy-subrc = 0.
        obapi->headdata-account_view       = 'X'.
      ENDIF.
      SEARCH <mara>-pstat FOR 'G'.
      IF sy-subrc = 0.
        obapi->headdata-cost_view       = 'X'.
      ENDIF.
      SEARCH <mara>-pstat FOR 'D'.
      IF sy-subrc = 0.
        obapi->headdata-mrp_view       = 'X'.
      ENDIF.


      SEARCH <mara>-vpsta FOR 'K'.
      IF sy-subrc = 0.
        obapi->headdata-basic_view       = 'X'.
      ENDIF.
      SEARCH <mara>-vpsta FOR 'V'.
      IF sy-subrc = 0.
        obapi->headdata-sales_view       = 'X'.
      ENDIF.
      SEARCH <mara>-vpsta FOR 'Q'.
      IF sy-subrc = 0.
        obapi->headdata-quality_view       = 'X'.
      ENDIF.
      SEARCH <mara>-vpsta FOR 'E'.
      IF sy-subrc = 0.
        obapi->headdata-purchase_view       = 'X'.
      ENDIF.
      SEARCH <mara>-vpsta FOR 'P'.
      IF sy-subrc = 0.
        obapi->headdata-forecast_view       = 'X'.
      ENDIF.
      SEARCH <mara>-vpsta FOR 'A'.
      IF sy-subrc = 0.
        obapi->headdata-work_sched_view       = 'X'.
      ENDIF.
      SEARCH <mara>-vpsta FOR 'L'.
      IF sy-subrc = 0.
        obapi->headdata-storage_view       = 'X'.
      ENDIF.
      SEARCH <mara>-vpsta FOR 'S'.
      IF sy-subrc = 0.
        obapi->headdata-warehouse_view       = 'X'.
      ENDIF.
      SEARCH <mara>-vpsta FOR 'B'.
      IF sy-subrc = 0.
        obapi->headdata-account_view       = 'X'.
      ENDIF.
      SEARCH <mara>-vpsta FOR 'G'.
      IF sy-subrc = 0.
        obapi->headdata-cost_view       = 'X'.
      ENDIF.
      SEARCH <mara>-vpsta FOR 'D'.
      IF sy-subrc = 0.
        obapi->headdata-mrp_view       = 'X'.
      ENDIF.

**   Datos material a nivel de mandante
      obapi->clientdata-matl_group = <mara>-matkl.
      SELECT SINGLE isocode
      INTO  obapi->clientdata-base_uom_iso
      FROM t006 WHERE msehi = <mara>-meins.


      obapi->clientdata-pvalidfrom  =  <mara>-mstde.
      REPLACE ALL OCCURENCES OF '-' IN obapi->clientdata-pvalidfrom WITH ''.

      obapi->clientdata-base_uom    =  <mara>-meins.
      obapi->clientdata-unit_of_wt  =  <mara>-gewei.
      obapi->clientdata-old_mat_no  =  <mara>-bismt.
      obapi->clientdata-allowed_wt  =  <mara>-brgew.
      obapi->clientdata-net_weight  =  <mara>-ntgew.
      obapi->clientdata-trans_grp   =  <mara>-tragr.
      obapi->clientdata-division    =  <mara>-spart.
      obapi->clientdata-pur_status  =  <mara>-mstae.
      obapi->clientdata-prod_hier   =  <mara>-prdha.
      obapi->clientdata-stor_conds  =  <mara>-raube.
      obapi->clientdata-allwd_vol   =  <mara>-volum.
      obapi->clientdata-pack_vo_un  =  <mara>-voleh.
      obapi->clientdata-po_unit     =  <mara>-bstme.
      obapi->clientdata-std_descr   =  <mara>-normt.
      obapi->clientdata-extmatlgrp  =  <mara>-extwg .
      obapi->clientdata-var_ord_un  =  <mara>-vabme .
      obapi->clientdata-sled_bbd    =  <mara>-sled_bbd .
* ESPEJO
      obapi->clientdatax-base_uom_iso = 'X'.
      obapi->clientdatax-matl_group   = 'X'.
      obapi->clientdatax-base_uom     = 'X'.
      obapi->clientdatax-old_mat_no   = 'X'.
      obapi->clientdatax-allowed_wt   = 'X'.
      obapi->clientdatax-net_weight   = 'X'.
      obapi->clientdatax-trans_grp    = 'X'.
      obapi->clientdatax-division     = 'X'.
      obapi->clientdatax-unit_of_wt   = 'X'.
      obapi->clientdatax-pur_status   = 'X'.
      obapi->clientdatax-pvalidfrom   = 'X'.
      obapi->clientdatax-prod_hier    = 'X'.
      obapi->clientdatax-stor_conds   = 'X'.
      obapi->clientdatax-allwd_vol    = 'X'.
      obapi->clientdatax-pack_vo_un   = 'X'.
      obapi->clientdatax-po_unit      = 'X'.
      obapi->clientdatax-std_descr    = 'X'.
      obapi->clientdatax-extmatlgrp   = 'X'.
      obapi->clientdatax-var_ord_un   = 'X'.
      obapi->clientdatax-sled_bbd     = 'X'.
      obapi->clientdatax-matcmpllvl   = 'X'.


      LOOP AT ti_makt ASSIGNING FIELD-SYMBOL(<ti_makt>)
                USING KEY s1
                   WHERE matnr = <mara>-matnr.
        APPEND INITIAL LINE TO obapi->materialdescription ASSIGNING FIELD-SYMBOL(<materialdescription>).
        " JOSELIN Colocar el Mapeo para MAKT

        <materialdescription>-langu     = <ti_makt>-spras.
        <materialdescription>-matl_desc = <ti_makt>-maktx.
        <materialdescription>-langu_iso = 'ES'.

      ENDLOOP.



      LOOP AT ti_marm ASSIGNING FIELD-SYMBOL(<ti_marm>)
                USING KEY s1
                   WHERE matnr = <mara>-matnr.
        APPEND INITIAL LINE TO obapi->unitsofmeasure ASSIGNING FIELD-SYMBOL(<unitsofmeasure>).
        APPEND INITIAL LINE TO obapi->unitsofmeasurex ASSIGNING FIELD-SYMBOL(<unitsofmeasurex>).

        <unitsofmeasure>-alt_unit    = <ti_marm>-meinh.
        <unitsofmeasure>-unit_of_wt  = <ti_marm>-gewei.
        <unitsofmeasure>-gross_wt    = <ti_marm>-brgew.
        <unitsofmeasure>-numerator   = <ti_marm>-umrez.
        <unitsofmeasure>-denominatr  = <ti_marm>-umren.
        <unitsofmeasure>-ean_upc     = <ti_marm>-ean11.
        <unitsofmeasure>-ean_cat     = <ti_marm>-numtp.
        <unitsofmeasure>-length      = <ti_marm>-laeng.
        <unitsofmeasure>-width       = <ti_marm>-breit.
        <unitsofmeasure>-height      = <ti_marm>-hoehe.
        <unitsofmeasure>-unit_dim    = <ti_marm>-meabm.
        <unitsofmeasure>-height      = <ti_marm>-hoehe.
        <unitsofmeasure>-volume      = <ti_marm>-volum.
        <unitsofmeasure>-volumeunit  = <ti_marm>-voleh.
        <unitsofmeasure>-sub_uom     = <ti_marm>-mesub.

        <unitsofmeasurex>-alt_unit    = <ti_marm>-meinh.
        <unitsofmeasurex>-unit_of_wt  = 'X'.
        <unitsofmeasurex>-gross_wt    = 'X'.
        <unitsofmeasurex>-numerator   = 'X'.
        <unitsofmeasurex>-denominatr  = 'X'.
        <unitsofmeasurex>-ean_upc     = 'X'.
        <unitsofmeasurex>-ean_cat     = 'X'.
        <unitsofmeasurex>-length      = 'X'.
        <unitsofmeasurex>-width       = 'X'.
        <unitsofmeasurex>-height      = 'X'.
        <unitsofmeasurex>-unit_dim    = 'X'.
        <unitsofmeasurex>-height      = 'X'.
        <unitsofmeasurex>-volume      = 'X'.
        <unitsofmeasurex>-volumeunit  = 'X'.
        <unitsofmeasurex>-sub_uom     = 'X'.

      ENDLOOP.

      ls_bapi_te_mara-material        = <mara>-matnr.
      ls_bapi_te_mara-zz_disst        = <mara>-disst.
      ls_bapi_te_mara-zz_class1       = <mara>-zz_class1.
      ls_bapi_te_mara-zz_class2       = <mara>-zz_class2.
      ls_bapi_te_mara-zz_dun14        = <mara>-zz_dun14.
      ls_bapi_te_mara-zz_vidautil     = <mara>-zz_vidautil.
      ls_bapi_te_mara-zz_tipoembalaje = <mara>-zz_tipoembalaje.
      ls_bapi_te_mara-zz_class3       = <mara>-zz_class3.
      ls_bapi_te_mara-zz_brgew        = <mara>-zz_brgew.
      ls_bapi_te_mara-zz_alto         = <mara>-zz_alto .
      ls_bapi_te_mara-zz_ancho        = <mara>-zz_ancho .
      ls_bapi_te_mara-zz_largo        = <mara>-zz_largo .
      ls_bapi_te_mara-zz_meins        = <mara>-zz_meins .
      ls_bapi_te_mara-zz_cntpallet    = <mara>-zz_cntpallet .

      ll_extensionin-valuepart1 =  ls_bapi_te_mara.
      ll_extensionin-structure = 'BAPI_TE_MARA'.
      APPEND ll_extensionin TO obapi->extensionin.

      ls_bapi_te_marax-material        = <mara>-matnr.
      ls_bapi_te_marax-zz_disst        = 'X'.
      ls_bapi_te_marax-zz_class1       = 'X'.
      ls_bapi_te_marax-zz_class2       = 'X'.
      ls_bapi_te_marax-zz_dun14        = 'X'.
      ls_bapi_te_marax-zz_vidautil     = 'X'.
      ls_bapi_te_marax-zz_tipoembalaje = 'X'.
      ls_bapi_te_marax-zz_class3       = 'X'.
      ls_bapi_te_marax-zz_brgew        = 'X'.
      ls_bapi_te_marax-zz_alto         = 'X'.
      ls_bapi_te_marax-zz_ancho        = 'X'.
      ls_bapi_te_marax-zz_largo        = 'X'.
      ls_bapi_te_marax-zz_meins        = 'X'.
      ls_bapi_te_marax-zz_cntpallet    = 'X'.

      ll_extensioninx-structure = 'BAPI_TE_MARAX'.
      ll_extensioninx-valuepart1 =  ls_bapi_te_marax.
      APPEND ll_extensioninx TO obapi->extensioninx.

      obapi->call_bapi( ).

      IF obapi->return-type NE 'E' .
        UPDATE mara SET disst       = @<mara>-disst,
                         pstat          = @<mara>-pstat,
                         vpsta          = @<mara>-vpsta,
                        zz_class1       = @<mara>-zz_class1,
                        zz_class2       = @<mara>-zz_class2,
                        zz_dun14        = @<mara>-zz_dun14,
                        zz_vidautil     = @<mara>-zz_vidautil,
                        zz_tipoembalaje = @<mara>-zz_tipoembalaje,
                        zz_class3       = @<mara>-zz_class3,
                        zz_brgew        = @<mara>-zz_brgew,
                        zz_alto         = @<mara>-zz_alto,
                        zz_ancho        = @<mara>-zz_ancho,
                        zz_largo        = @<mara>-zz_largo,
                        zz_meins        = @<mara>-zz_meins,
                        zz_cntpallet    = @<mara>-zz_cntpallet
                         WHERE matnr =  @<mara>-matnr.


        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.

      ENDIF.


*      IF ( obapi->return-type = 'E' OR obapi->return-type = 'A' OR obapi->return-type = 'F' ).
*        WRITE: /'MARA:', <mara>-matnr, obapi->return-type, obapi->return-number, obapi->return-id, obapi->return-message.
*        reportar_error( <mara>-matnr ).
*        CONTINUE. " Contunuar con el siguiente material
*      ELSE.
        IF sprinerr = 'X'.
          WRITE: /'MARA:', <mara>-matnr, obapi->return-type, obapi->return-number, obapi->return-id, obapi->return-message.
        ENDIF.
*      ENDIF.

**LLENAR EN LA TABLA LOS REGISTROS
      IF  obapi->return-type  NE  'E'.
        ls_reg_mara-matnr  =     <mara>-matnr.
        CONCATENATE lv_verde  obapi->return-message   INTO  ls_reg_mara-mensajes .
      ELSE.
        ls_reg_mara-matnr  =     <mara>-matnr.
        CONCATENATE lv_rojo  obapi->return-message  INTO  ls_reg_mara-mensajes.
      ENDIF.
      APPEND    ls_reg_mara TO   lt_reg_mara .
      CLEAR:  ls_reg_mara.
    ENDLOOP.
    MODIFY zmm_reg_mara FROM TABLE lt_reg_mara.

    REFRESH   lt_reg_mara.
    CLEAR    lt_reg_mara.
  ENDMETHOD.

  METHOD call_bapi_marc.
    DATA obapi TYPE REF TO lcl_bapi_material. " Nuevo llamado a la BAPI

    LOOP AT ti_marc ASSIGNING FIELD-SYMBOL(<marc>).
      obapi = NEW lcl_bapi_material(  ).

*      generar_vistas( EXPORTING pstat = <marc>-pstat table = 'MARC'
*                      CHANGING headdata = obapi->headdata ).

SEARCH <marc>-pstat FOR 'K'.
      IF sy-subrc = 0.
        obapi->headdata-basic_view       = 'X'.
      ENDIF.
      SEARCH <MARC>-pstat FOR 'V'.
      IF sy-subrc = 0.
        obapi->headdata-sales_view       = 'X'.
      ENDIF.
      SEARCH <MARC>-pstat FOR 'Q'.
      IF sy-subrc = 0.
        obapi->headdata-quality_view       = 'X'.
      ENDIF.
      SEARCH <MARC>-pstat FOR 'E'.
      IF sy-subrc = 0.
        obapi->headdata-purchase_view       = 'X'.
      ENDIF.
      SEARCH <MARC>-pstat FOR 'P'.
      IF sy-subrc = 0.
        obapi->headdata-forecast_view       = 'X'.
      ENDIF.
      SEARCH <MARC>-pstat FOR 'A'.
      IF sy-subrc = 0.
        obapi->headdata-work_sched_view       = 'X'.
      ENDIF.
      SEARCH <MARC>-pstat FOR 'L'.
      IF sy-subrc = 0.
        obapi->headdata-storage_view       = 'X'.
      ENDIF.
      SEARCH <MARC>-pstat FOR 'S'.
      IF sy-subrc = 0.
        obapi->headdata-warehouse_view       = 'X'.
      ENDIF.
      SEARCH <MARC>-pstat FOR 'B'.
      IF sy-subrc = 0.
        obapi->headdata-account_view       = 'X'.
      ENDIF.
      SEARCH <MARC>-pstat FOR 'G'.
      IF sy-subrc = 0.
        obapi->headdata-cost_view       = 'X'.
      ENDIF.
      SEARCH <MARC>-pstat FOR 'D'.
      IF sy-subrc = 0.
        obapi->headdata-mrp_view       = 'X'.
      ENDIF.

        obapi->headdata-material = <marc>-matnr.

       obapi->plantdata-plant       = <marc>-werks.
       obapi->plantdata-availcheck  = <marc>-mtvfp.
       obapi->plantdata-mrp_ctrler  = <marc>-dispo.
       obapi->plantdata-mrp_type    = <marc>-dismm.

      obapi->plantdata-base_qty    = <marc>-basmg .
      obapi->plantdata-lot_size    = <marc>-losgr.
      obapi->plantdata-del_flag    = <marc>-lvorm.
      obapi->plantdata-pur_group   = <marc>-ekgrp.
      obapi->plantdata-dep_req_id  = <marc>-sbdkz.
      obapi->plantdata-profit_ctr  = <marc>-prctr.
      obapi->plantdata-iss_st_loc  = <marc>-lgpro.
      obapi->plantdata-sm_key      = <marc>-fhori.
      obapi->plantdata-lotsizekey  = <marc>-disls.
      obapi->plantdata-issue_unit  = <marc>-ausme.
      obapi->plantdata-proc_type   = <marc>-beskz.

      obapi->plantdata-production_scheduler  = <marc>-fevor.
      obapi->plantdata-setuptime  = <marc>-ruezt.
      obapi->plantdata-proc_time  =  <marc>-bearz.
      obapi->plantdata-prod_unit  =  <marc>-frtme.
      obapi->plantdata-mrp_group  =  <marc>-disgr.
      obapi->plantdata-sloc_exprc =  <marc>-lgfsb.

      obapi->plantdata-safety_stk  = <marc>-eisbe.
      obapi->plantdata-reorder_pt  = <marc>-minbe.
      obapi->plantdata-minlotsize  = <marc>-bstmi.
      obapi->plantdata-maxlotsize  = <marc>-bstma.
      obapi->plantdata-fixed_lot   = <marc>-bstfe.
      obapi->plantdata-round_val   = <marc>-bstrf.
      obapi->plantdata-max_stock   = <marc>-mabst.
      obapi->plantdata-auto_reset  = <marc>-autru.
      obapi->plantdata-alt_bom_id  = <marc>-altsl.
      obapi->plantdata-spproctype  = <marc>-sobsl.
      obapi->plantdata-loadinggrp = <marc>-ladgr.
      obapi->plantdatax-plant      = <marc>-werks.

      IF obapi->plantdata-availcheck IS NOT INITIAL.
        obapi->plantdatax-availcheck = 'X'.
      ENDIF.
if   obapi->plantdata-mrp_ctrler is NOT INITIAL.
      obapi->plantdatax-mrp_ctrler = 'X'.
ENDIF.
      IF <marc>-dismm IS NOT INITIAL.
        obapi->plantdatax-mrp_type   = 'X'.
      ENDIF.

      obapi->plantdatax-base_qty   = 'X'.
      obapi->plantdatax-lot_size   = 'X'.
      obapi->plantdatax-del_flag   = 'X'.
      obapi->plantdatax-pur_group  = 'X'.
      obapi->plantdatax-dep_req_id = 'X'.
      obapi->plantdatax-profit_ctr = 'X'.
      obapi->plantdatax-iss_st_loc = 'X'.
      obapi->plantdatax-sm_key     = 'X'.
      obapi->plantdatax-lotsizekey = 'X'.
      obapi->plantdatax-issue_unit = 'X'.
      obapi->plantdatax-proc_type  = 'X'.
      obapi->plantdatax-production_scheduler   = 'X'.
      obapi->plantdatax-prod_unit  = 'X'.
      obapi->plantdatax-mrp_group  = 'X'.
      obapi->plantdatax-sloc_exprc = 'X'.
      obapi->plantdatax-setuptime  = 'X'.
      obapi->plantdatax-proc_time  = 'X'.
      obapi->plantdatax-safety_stk = 'X'.
      obapi->plantdatax-reorder_pt = 'X'.
      obapi->plantdatax-minlotsize = 'X'.
      obapi->plantdatax-maxlotsize = 'X'.
      obapi->plantdatax-fixed_lot  = 'X'.
      obapi->plantdatax-round_val  = 'X'.
      obapi->plantdatax-max_stock  = 'X'.
      obapi->plantdatax-auto_reset = 'X'.
      obapi->plantdatax-alt_bom_id = 'X'.
      obapi->plantdatax-lot_size   = 'X'.
      obapi->plantdatax-spproctype = 'X'.
      obapi->plantdatax-loadinggrp = 'X'.


      obapi->forecastparameters-plant      = <marc>-werks.
**      obapi->forecastparameters-fore_model = 'D'.
**
      obapi->forecastparametersx-plant      = <marc>-werks.
**      obapi->forecastparametersx-fore_model = 'X'.

      obapi->call_bapi( ).
      IF obapi->return-type NE  'E'.
        UPDATE marc SET  pstat  =  @<marc>-pstat,
                        ladgr  =  @<marc>-ladgr,
                        ekgrp  =  @<marc>-ekgrp,
                        sbdkz  =  @<marc>-sbdkz,
                        dismm  =  @<marc>-dismm,
                        rgekz  =  @<marc>-rgekz,
                        verkz  =  @<marc>-verkz,
                        strgr  =  @<marc>-strgr,
                        sfcpf  =  @<marc>-sfcpf,
                        mmsta  =  @<marc>-mmsta,
                        losgr  =  @<marc>-losgr
                        WHERE matnr = @<marc>-matnr AND
                              werks = @<marc>-werks.

        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.
      ENDIF.

**      IF ( obapi->return-type = 'E' OR obapi->return-type = 'A' OR obapi->return-type = 'F' ).
**        IF ( obapi->return-type = 'E' AND obapi->return-number = '897' AND obapi->return-id = 'M3' ) AND reprocesar = abap_true. " Reprocesar
**          APPEND <marc> TO reproceso.
**        ELSEIF ( obapi->return-type = 'E' AND obapi->return-number = '200' AND obapi->return-id = 'M3' ) AND reprocesar = abap_true. " Reprocesar
**          APPEND <marc> TO reproceso.
**          APPEND <marc> TO reproceso.
**        ELSEIF ( obapi->return-type = 'E' AND obapi->return-number = '022' AND obapi->return-id = 'M3' ) AND reprocesar = abap_true.
**          " NO TOMAR EN CUENTA
**        ELSE.
**          WRITE: /'MARC:', <marc>-matnr, obapi->return-type, obapi->return-number, obapi->return-id, obapi->return-message.
**          reportar_error( <marc>-matnr ).
**        ENDIF.
**
**        CONTINUE. " Contunuar con el siguiente material
**      ELSE.
        IF sprinerr = 'X'.
          WRITE: /'MARC:', <marc>-matnr, obapi->return-type, obapi->return-number, obapi->return-id, obapi->return-message.
        ENDIF.
*      ENDIF.
      IF  obapi->return-type   NE 'E'.
        ls_reg_marc-material  =     <marc>-matnr.
        ls_reg_marc-centro =  <marc>-werks .
        CONCATENATE lv_verde  obapi->return-message  INTO  ls_reg_marc-mensajes SEPARATED BY ' ' .
      ELSE.
        ls_reg_marc-material  =     <marc>-matnr.
        ls_reg_marc-centro =  <marc>-werks .
        CONCATENATE lv_rojo  obapi->return-message  INTO  ls_reg_marc-mensajes SEPARATED BY ' '.
      ENDIF.

      APPEND  ls_reg_marc TO   lt_reg_marc .
      CLEAR: ls_reg_marc.

    ENDLOOP.

    MODIFY zmm_reg_marc FROM TABLE lt_reg_marc.
    REFRESH   lt_reg_marc.
    CLEAR    lt_reg_marc.
  ENDMETHOD.

  METHOD call_bapi_mard.
    DATA obapi TYPE REF TO lcl_bapi_material. " Nuevo llamado a la BAPI

    LOOP AT ti_mard ASSIGNING FIELD-SYMBOL(<mard>).
      obapi = NEW lcl_bapi_material(  ).

      obapi->headdata-material = <mard>-matnr.

      SEARCH <mard>-pstat FOR 'K'.
      IF sy-subrc = 0.
        obapi->headdata-basic_view      = 'X'.
      ENDIF.
      SEARCH <mard>-pstat FOR 'V'.
      IF sy-subrc = 0.
        obapi->headdata-sales_view      = 'X'.
      ENDIF.
      SEARCH <mard>-pstat FOR 'Q'.
      IF sy-subrc = 0.
        obapi->headdata-quality_view    = 'X'.
      ENDIF.
      SEARCH <mard>-pstat FOR 'E'.
      IF sy-subrc = 0.
        obapi->headdata-purchase_view   = 'X'.
      ENDIF.
      SEARCH <mard>-pstat FOR 'P'.
      IF sy-subrc = 0.
        obapi->headdata-forecast_view   = 'X'.
      ENDIF.
      SEARCH <mard>-pstat FOR 'A'.
      IF sy-subrc = 0.
        obapi->headdata-work_sched_view = 'X'.
      ENDIF.
      SEARCH <mard>-pstat FOR 'L'.
      IF sy-subrc = 0.
        obapi->headdata-storage_view    = 'X'.
      ENDIF.
      SEARCH <mard>-pstat FOR 'S'.
      IF sy-subrc = 0.
        obapi->headdata-warehouse_view  = 'X'.
      ENDIF.
      SEARCH <mard>-pstat FOR 'B'.
      IF sy-subrc = 0.
        obapi->headdata-account_view    = 'X'.
      ENDIF.
      SEARCH <mard>-pstat FOR 'G'.
      IF sy-subrc = 0.
        obapi->headdata-cost_view       = 'X'.
      ENDIF.
      SEARCH <mard>-pstat FOR 'D'.
      IF sy-subrc = 0.
        obapi->headdata-mrp_view        = 'X'.
      ENDIF.


      obapi->storagelocationdata-plant     = <mard>-werks.
      obapi->storagelocationdata-stge_loc  = <mard>-lgort.
      obapi->storagelocationdata-del_flag  = <mard>-lvorm.


      obapi->storagelocationdatax-plant    = <mard>-werks.
      obapi->storagelocationdatax-stge_loc = <mard>-lgort.
      obapi->storagelocationdatax-del_flag = 'X'.

      obapi->call_bapi( ).

      IF obapi->return-type NE  'E'.
        UPDATE mard SET  pstat =  @<mard>-pstat
                 WHERE matnr   =  @<mard>-matnr AND
                       werks   =  @<mard>-werks.

        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.
      ENDIF.

*      IF ( obapi->return-type = 'E' OR obapi->return-type = 'A' OR obapi->return-type = 'F' ).
*        IF ( obapi->return-type = 'E' AND obapi->return-number = '024' AND obapi->return-id = 'M3' ) AND reprocesar = abap_true. " Reprocesar
*          APPEND <mard> TO reproceso.
*        ELSE.
*          WRITE: /'MARD:', <mard>-matnr, obapi->return-type, obapi->return-number, obapi->return-id, obapi->return-message.
*          reportar_error( <mard>-matnr ).
*        ENDIF.
*        CONTINUE. " Contunuar con el siguiente material
*      ELSE.
        IF sprinerr = 'X'.
          WRITE: /'MARD:', <mard>-matnr, obapi->return-type, obapi->return-number, obapi->return-id, obapi->return-message.
        ENDIF.
*      ENDIF.

      IF  obapi->return-type   NE 'E'.
        ls_reg_mard-material = <mard>-matnr.
        ls_reg_mard-centro   = <mard>-werks .
        ls_reg_mard-almacen  = <mard>-lgort.
        CONCATENATE lv_verde  obapi->return-message  INTO  ls_reg_mard-mensajes SEPARATED BY ' ' .
      ELSE.
        ls_reg_mard-material = <mard>-matnr.
        ls_reg_mard-centro   = <mard>-werks .
        ls_reg_mard-almacen  = <mard>-lgort.
        CONCATENATE lv_rojo  obapi->return-message  INTO  ls_reg_mard-mensajes SEPARATED BY ' '.
      ENDIF.

      APPEND  ls_reg_mard TO   lt_reg_mard .
      CLEAR: ls_reg_mard.

    ENDLOOP.
    MODIFY zmm_reg_mard FROM TABLE lt_reg_mard.
   REFRESH   lt_reg_mard.
    CLEAR    lt_reg_mard.

  ENDMETHOD.

  METHOD call_bapi_mbew.
    DATA obapi TYPE REF TO lcl_bapi_material. " Nuevo llamado a la BAPI

    LOOP AT ti_mbew ASSIGNING FIELD-SYMBOL(<mbew>).
      obapi = NEW lcl_bapi_material(  ).

      obapi->headdata-material = <mbew>-matnr.

      SEARCH <mbew>-pstat FOR 'K'.
      IF sy-subrc = 0.
        obapi->headdata-basic_view     = 'X'.
      ENDIF.
      SEARCH <mbew>-pstat FOR 'V'.
      IF sy-subrc = 0.
        obapi->headdata-sales_view     = 'X'.
      ENDIF.
      SEARCH <mbew>-pstat FOR 'Q'.
      IF sy-subrc = 0.
        obapi->headdata-quality_view   = 'X'.
      ENDIF.
      SEARCH <mbew>-pstat FOR 'E'.
      IF sy-subrc = 0.
        obapi->headdata-purchase_view   = 'X'.
      ENDIF.
      SEARCH <mbew>-pstat FOR 'P'.
      IF sy-subrc = 0.
        obapi->headdata-forecast_view    = 'X'.
      ENDIF.
      SEARCH <mbew>-pstat FOR 'A'.
      IF sy-subrc = 0.
        obapi->headdata-work_sched_view  = 'X'.
      ENDIF.
      SEARCH <mbew>-pstat FOR 'L'.
      IF sy-subrc = 0.
        obapi->headdata-storage_view     = 'X'.
      ENDIF.
      SEARCH <mbew>-pstat FOR 'S'.
      IF sy-subrc = 0.
        obapi->headdata-warehouse_view   = 'X'.
      ENDIF.
      SEARCH <mbew>-pstat FOR 'B'.
      IF sy-subrc = 0.
        obapi->headdata-account_view     = 'X'.
      ENDIF.
      SEARCH <mbew>-pstat FOR 'G'.
      IF sy-subrc = 0.
        obapi->headdata-cost_view        = 'X'.
      ENDIF.
      SEARCH <mbew>-pstat FOR 'D'.
      IF sy-subrc = 0.
        obapi->headdata-mrp_view        = 'X'.
      ENDIF.

      obapi->valuationdata-val_area   = <mbew>-bwkey.
      obapi->valuationdata-price_ctrl = <mbew>-vprsv.
      obapi->valuationdata-moving_pr  = <mbew>-verpr.
      obapi->valuationdata-std_price  = <mbew>-stprs.
      obapi->valuationdata-price_unit = <mbew>-peinh.
      obapi->valuationdata-val_class  = <mbew>-bklas.
      obapi->valuationdata-del_flag   = <mbew>-lvorm.
      obapi->valuationdata-mov_pr_pp  = <mbew>-vmver.

*    ESPEJO
      obapi->valuationdatax-val_area   = <mbew>-bwkey.
      obapi->valuationdatax-price_ctrl = 'X'.
      obapi->valuationdatax-moving_pr  = 'X'.
      obapi->valuationdatax-std_price  = 'X'.
      obapi->valuationdatax-price_unit = 'X'.
      obapi->valuationdatax-val_class  = 'X'.
      obapi->valuationdatax-del_flag   = 'X'.
      obapi->valuationdatax-mov_pr_pp  = 'X'.

      obapi->call_bapi( ).

      IF obapi->return-type NE  'E'.
        UPDATE mbew SET  pstat       =  @<mbew>-pstat
                         WHERE matnr =  @<mbew>-matnr AND
                              bwkey  =  @<mbew>-bwkey.

        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.
      ENDIF.

*      IF ( obapi->return-type = 'E' OR obapi->return-type = 'A' OR obapi->return-type = 'F' ).
*        IF ( obapi->return-type = 'E' AND obapi->return-number = '024' AND obapi->return-id = 'M3' ) AND reprocesar = abap_true.
*          APPEND <mbew> TO reproceso.
*        ELSE.
*          WRITE: /'MBEW:', <mbew>-matnr, obapi->return-type, obapi->return-number, obapi->return-id, obapi->return-message.
*          reportar_error( <mbew>-matnr ).
*        ENDIF.
*        CONTINUE. " Contunuar con el siguiente material
*      ELSE.
        IF sprinerr = 'X'.
          WRITE: /'MBEW:', <mbew>-matnr, obapi->return-type, obapi->return-number, obapi->return-id, obapi->return-message.
        ENDIF.
*      ENDIF.

      IF  obapi->return-type   NE 'E'.
        ls_reg_mbew-material = <mbew>-matnr.
        ls_reg_mbew-bwkey  =   <mbew>-bwkey.
        ls_reg_mbew-bwtar  =   <mbew>-bwkey.
        CONCATENATE lv_verde  obapi->return-message  INTO  ls_reg_mbew-mensajes SEPARATED BY ' ' .
      ELSE.
        ls_reg_mbew-material = <mbew>-matnr.
        ls_reg_mbew-bwkey  = <mbew>-bwkey.
        ls_reg_mbew-bwtar  = <mbew>-bwkey.
        CONCATENATE lv_rojo  obapi->return-message  INTO  ls_reg_mbew-mensajes SEPARATED BY ' '.
      ENDIF.

      APPEND  ls_reg_mbew TO   lt_reg_mbew .
      CLEAR: ls_reg_mbew.

    ENDLOOP.
    MODIFY zmm_reg_mbew FROM TABLE lt_reg_mbew.
    REFRESH   lt_reg_mbew.
    CLEAR    lt_reg_mbew.
  ENDMETHOD.

  METHOD call_bapi_mvke.
    DATA obapi TYPE REF TO lcl_bapi_material. " Nuevo llamado a la BAPI

    LOOP AT ti_mvke ASSIGNING FIELD-SYMBOL(<mvke>).
      obapi = NEW lcl_bapi_material(  ).

      obapi->headdata-material = <mvke>-matnr.

      obapi->salesdata-sales_org   = <mvke>-vkorg.
      obapi->salesdata-distr_chan  = <mvke>-vtweg.
      obapi->salesdata-matl_stats  = <mvke>-versg.
      obapi->salesdata-cash_disc   = <mvke>-sktof.
      obapi->salesdata-item_cat    = <mvke>-mtpos.
      obapi->salesdata-delyg_plnt  = <mvke>-dwerk.
      obapi->salesdata-acct_assgt  = <mvke>-ktgrm.
      obapi->salesdata-matl_grp_1  = <mvke>-mvgr1.
      obapi->salesdata-matl_grp_2  = <mvke>-mvgr2.
      obapi->salesdata-matl_grp_3  = <mvke>-mvgr3.
      obapi->salesdata-matl_grp_4  = <mvke>-mvgr4.
      obapi->salesdata-matl_grp_5  = <mvke>-mvgr5.
      obapi->salesdata-del_flag    = <mvke>-lvorm.
      obapi->salesdata-delyg_plnt  = <mvke>-dwerk.
      obapi->salesdata-rebate_grp  = <mvke>-bonus.
      obapi->salesdata-sales_unit  = <mvke>-vrkme.
      obapi->salesdata-sal_status  = <mvke>-vmsta.
      obapi->salesdata-valid_from  = <mvke>-vmstd.
      obapi->salesdata-prod_hier  =  <mvke>-prodh.
      obapi->salesdata-mat_pr_grp  = <mvke>-kondm.

      obapi->salesdatax-sales_org   = <mvke>-vkorg.
      obapi->salesdatax-distr_chan  = <mvke>-vtweg.
      obapi->salesdatax-matl_stats  = 'X'.
      obapi->salesdatax-cash_disc   = 'X'.
      obapi->salesdatax-item_cat    = 'X'.
      obapi->salesdatax-delyg_plnt  = 'X'.
      obapi->salesdatax-acct_assgt  = 'X'.
      obapi->salesdatax-matl_grp_1  = 'X'.
      obapi->salesdatax-matl_grp_2  = 'X'.
      obapi->salesdatax-matl_grp_3  = 'X'.
      obapi->salesdatax-matl_grp_4  = 'X'.
      obapi->salesdatax-matl_grp_5  = 'X'.
      obapi->salesdatax-del_flag    = 'X'.
      obapi->salesdatax-delyg_plnt  = 'X'.
      obapi->salesdatax-rebate_grp  = 'X'.
      obapi->salesdatax-sales_unit  = 'X'.
      obapi->salesdatax-sal_status  = 'X'.
      obapi->salesdatax-valid_from  = 'X'.
      obapi->salesdata-prod_hier     ='X'.
      obapi->salesdatax-mat_pr_grp  = 'X'.
      obapi->call_bapi( ).

*      IF ( obapi->return-type = 'E' OR obapi->return-type = 'A' OR obapi->return-type = 'F' ).
*        WRITE: /'MVKE:', <mvke>-matnr, obapi->return-type, obapi->return-number, obapi->return-id, obapi->return-message.
*        reportar_error( <mvke>-matnr ).
*        CONTINUE. " Contunuar con el siguiente material
*      ELSE.
        IF sprinerr = 'X'.
          WRITE: /'MVKE:', <mvke>-matnr, obapi->return-type, obapi->return-number, obapi->return-id, obapi->return-message.
        ENDIF.
*      ENDIF.

      IF  obapi->return-type   NE 'E'.
        ls_reg_mvke-material = <mvke>-matnr.
        ls_reg_mvke-vkorg  = <mvke>-vkorg.
        ls_reg_mvke-vtweg = <mvke>-vtweg.
        CONCATENATE lv_verde  obapi->return-message  INTO  ls_reg_mvke-mensajes SEPARATED BY ' ' .
      ELSE.
        ls_reg_mvke-material = <mvke>-matnr.
        ls_reg_mvke-vkorg  = <mvke>-vkorg.
        ls_reg_mvke-vtweg = <mvke>-vtweg.
        CONCATENATE lv_rojo  obapi->return-message  INTO  ls_reg_mvke-mensajes SEPARATED BY ' '.
      ENDIF.

      APPEND  ls_reg_mvke TO   lt_reg_mvke .
      CLEAR: ls_reg_mvke.

    ENDLOOP.
    MODIFY zmm_reg_mvke FROM TABLE lt_reg_mvke.

    REFRESH   lt_reg_mvke.
    CLEAR    lt_reg_mvke.
  ENDMETHOD.

  METHOD generar_vistas.
    SEARCH pstat FOR 'K'.
    IF sy-subrc = 0.
      headdata-basic_view    = 'X'.
    ENDIF.
    SEARCH pstat FOR 'V'.
    IF sy-subrc = 0.
      headdata-sales_view    = 'X'.
    ENDIF.
    SEARCH pstat FOR 'Q'.
    IF sy-subrc = 0.
      headdata-quality_view  = 'X'.
    ENDIF.
    SEARCH pstat FOR 'E'.
    IF sy-subrc = 0.
      headdata-purchase_view  = 'X'.
    ENDIF.
    SEARCH pstat FOR 'P'.
    IF sy-subrc = 0.
      headdata-forecast_view  = 'X'.
    ENDIF.
    SEARCH pstat FOR 'A'.
    IF sy-subrc = 0.
      headdata-work_sched_view = 'X'.
    ENDIF.
    SEARCH pstat FOR 'L'.
    IF sy-subrc = 0.
      headdata-storage_view    = 'X'.
    ENDIF.
    SEARCH pstat FOR 'S'.
    IF sy-subrc = 0.
      headdata-warehouse_view  = 'X'.
    ENDIF.
    SEARCH pstat FOR 'B'.
    IF sy-subrc = 0.
      headdata-account_view    = 'X'.
    ENDIF.
    SEARCH pstat FOR 'G'.
    IF sy-subrc = 0.
      headdata-cost_view      = 'X'.
    ENDIF.
    SEARCH pstat FOR 'D'.
    IF sy-subrc = 0.
      headdata-mrp_view      = 'X'.
    ENDIF.
  ENDMETHOD.

  METHOD reportar_error.
    TRY.
        INSERT VALUE #( matnr = i_matnr ) INTO TABLE ti_errores.
      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.

  METHOD respaldar_errores.
*        filename    TYPE rlgrap-filename
*        filt_prefix TYPE rlgrap-filename.
    DATA lv_xstring TYPE xstring .
    CALL TRANSFORMATION id  " z_my_xml_transformation is the ID
         SOURCE table = ti_errores
         RESULT XML lv_xstring.
    DATA(lv_xls_file) = condense( |{ dir }/{ filt_prefix }{ filename }.err.xml| ).
    OPEN DATASET lv_xls_file FOR OUTPUT IN BINARY MODE.
    IF sy-subrc EQ 0.
      TRANSFER lv_xstring TO lv_xls_file.
      CLOSE DATASET lv_xls_file.
    ELSE.
      MESSAGE w319(01) WITH
        'Error al guardar el archivo de ERRORES' lv_xls_file.
    ENDIF.
  ENDMETHOD.

  METHOD call_bapi_mlan.
    DATA obapi TYPE REF TO lcl_bapi_material. " Nuevo llamado a la BAPI


    LOOP AT ti_mlan ASSIGNING FIELD-SYMBOL(<mlan>).
      obapi = NEW lcl_bapi_material(  ).
      obapi->headdata-material = <mlan>-matnr.
      APPEND INITIAL LINE TO obapi->taxclassifications ASSIGNING FIELD-SYMBOL(<taxclassifications>).

*        <taxclassifications>-depcountry   = <mlan>-aland.
      <taxclassifications>-taxclass_1   = <mlan>-taxm1.
      <taxclassifications>-taxclass_2   = <mlan>-taxm2.
      <taxclassifications>-tax_ind      = <mlan>-taxim.

      obapi->call_bapi( ).
      IF  obapi->return-type  NE  'E'.
        UPDATE mlan SET
        taxm1   = @<mlan>-taxm1,
        taxm2   = @<mlan>-taxm2,
        taxim   = @<mlan>-taxim
        WHERE matnr = @<mlan>-matnr AND
        aland   = @<mlan>-aland.

        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.
      ENDIF.

*      IF ( obapi->return-type = 'E' OR obapi->return-type = 'A' OR obapi->return-type = 'F' ).
*        WRITE: /'MLAN:', <mlan>-matnr, obapi->return-type, obapi->return-number, obapi->return-id, obapi->return-message.
*        reportar_error( <mlan>-matnr ).
*        CONTINUE. " Contunuar con el siguiente material
*      ELSE.
        IF sprinerr = 'X'.
          WRITE: /'MLAN:', <mlan>-matnr, obapi->return-type, obapi->return-number, obapi->return-id, obapi->return-message.
        ENDIF.
*      ENDIF.

      IF  obapi->return-type   NE 'E'.
        ls_reg_mlan-material = <mlan>-matnr.
        ls_reg_mlan-aland   = <mlan>-aland .

        CONCATENATE lv_verde  obapi->return-message  INTO  ls_reg_mlan-mensajes SEPARATED BY ' ' .
      ELSE.
        ls_reg_mlan-material = <mlan>-matnr.
        ls_reg_mlan-aland   = <mlan>-aland .
        CONCATENATE lv_rojo  obapi->return-message  INTO  ls_reg_mlan-mensajes SEPARATED BY ' '.
      ENDIF.

      APPEND  ls_reg_mlan TO   lt_reg_mlan .
      CLEAR: ls_reg_mlan.

    ENDLOOP.
    MODIFY zmm_reg_mlan FROM TABLE lt_reg_mlan.
    REFRESH   lt_reg_mlan.
    CLEAR    lt_reg_mlan.
  ENDMETHOD.
ENDCLASS.


*INCLUDEEE 
*&---------------------------------------------------------------------*
*&  Include  zr_mm_mqa_u_carga_mat_c1
*&---------------------------------------------------------------------*

CLASS lcl_bapi_material DEFINITION .

  PUBLIC SECTION.
    METHODS call_bapi.

    DATA headdata TYPE  bapimathead.
    DATA clientdata TYPE  bapi_mara .
    DATA clientdatax TYPE  bapi_marax .
    DATA plantdata TYPE  bapi_marc .
    DATA plantdatax TYPE  bapi_marcx .
    DATA forecastparameters TYPE  bapi_mpop .
    DATA forecastparametersx TYPE  bapi_mpopx .
    DATA planningdata TYPE  bapi_mpgd .
    DATA planningdatax TYPE  bapi_mpgdx .
    DATA storagelocationdata TYPE  bapi_mard .
    DATA storagelocationdatax TYPE  bapi_mardx .
    DATA valuationdata TYPE  bapi_mbew .
    DATA valuationdatax TYPE  bapi_mbewx .
    DATA warehousenumberdata TYPE  bapi_mlgn .
    DATA warehousenumberdatax TYPE  bapi_mlgnx .
    DATA salesdata TYPE  bapi_mvke .
    DATA salesdatax TYPE  bapi_mvkex .
    DATA storagetypedata TYPE  bapi_mlgt .
    DATA storagetypedatax TYPE  bapi_mlgtx .
    DATA flag_online TYPE  bapie1global_data-testrun .
    DATA flag_cad_call TYPE  bapie1global_data-testrun.
    DATA no_dequeue TYPE  bapie1global_data-testrun .
    DATA no_rollback_work TYPE  bapie1global_data-testrun .

    DATA return TYPE bapiret2.

    DATA: materialdescription TYPE STANDARD TABLE OF  bapi_makt  WITH DEFAULT KEY,
          unitsofmeasure      TYPE STANDARD TABLE OF  bapi_marm  WITH DEFAULT KEY,
          unitsofmeasurex     TYPE STANDARD TABLE OF  bapi_marmx  WITH DEFAULT KEY,
          internationalartnos TYPE STANDARD TABLE OF  bapi_mean  WITH DEFAULT KEY,
          materiallongtext    TYPE STANDARD TABLE OF  bapi_mltx  WITH DEFAULT KEY,
          taxclassifications  TYPE STANDARD TABLE OF  bapi_mlan  WITH DEFAULT KEY,
          returnmessages      TYPE STANDARD TABLE OF  bapi_matreturn2  WITH DEFAULT KEY,
          prtdata             TYPE STANDARD TABLE OF  bapi_mfhm  WITH DEFAULT KEY,
          prtdatax            TYPE STANDARD TABLE OF  bapi_mfhmx  WITH DEFAULT KEY,
          extensionin         TYPE STANDARD TABLE OF  bapiparex  WITH DEFAULT KEY,
          extensioninx        TYPE STANDARD TABLE OF  bapiparexx  WITH DEFAULT KEY.
  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.


CLASS lcl_bapi_material IMPLEMENTATION.
  METHOD call_bapi.
    CALL FUNCTION 'BAPI_MATERIAL_SAVEDATA'
      EXPORTING
        headdata             = headdata
        clientdata           = clientdata
        clientdatax          = clientdatax
        plantdata            = plantdata
        plantdatax           = plantdatax
        forecastparameters   = forecastparameters
        forecastparametersx  = forecastparametersx
        planningdata         = planningdata
        planningdatax        = planningdatax
        storagelocationdata  = storagelocationdata
        storagelocationdatax = storagelocationdatax
        valuationdata        = valuationdata
        valuationdatax       = valuationdatax
        warehousenumberdata  = warehousenumberdata
        warehousenumberdatax = warehousenumberdatax
        salesdata            = salesdata
        salesdatax           = salesdatax
        storagetypedata      = storagetypedata
        storagetypedatax     = storagetypedatax
        flag_online          = space
        flag_cad_call        = space
        no_dequeue           = space
        no_rollback_work     = space
      IMPORTING
        return               = return
      TABLES
        materialdescription  = materialdescription
        unitsofmeasure       = unitsofmeasure
        unitsofmeasurex      = unitsofmeasurex
        internationalartnos  = internationalartnos
        materiallongtext     = materiallongtext
        taxclassifications   = taxclassifications
        returnmessages       = returnmessages
        prtdata              = prtdata
        prtdatax             = prtdatax
        extensionin          = extensionin
        extensioninx         = extensioninx.

IF RETURN-TYPE  NE 'E'.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*&---------------------------------------------------------------------*
*& Report zr_mm_mqa_u_descarga_mat
*&---------------------------------------------------------------------*
*& DESCARGA DE MATERIALES  JNTP  PROGRAMA PARAC DESCARGAR DATA DE TABLA

*&---------------------------------------------------------------------*
REPORT zr_mm_mqa_u_descarga_mat.

TABLES mara.

TYPES: ty_contador TYPE n LENGTH 6.
TYPES: BEGIN OF ty_mara_index,
         matnr TYPE mara-matnr,
       END OF ty_mara_index,
       tt_mara_index TYPE STANDARD TABLE OF ty_mara_index WITH DEFAULT KEY.

SELECT-OPTIONS smatnr FOR mara-matnr.

PARAMETERS regxpaq TYPE i DEFAULT 5000.
PARAMETERS preffl TYPE rlgrap-filename OBLIGATORY DEFAULT 'YY01_'. " Prefijo Archivo
PARAMETERS: pdir LIKE rlgrap-filename OBLIGATORY DEFAULT '/mnt/sapshare/temp'.

PARAMETERS prefmt TYPE c LENGTH 10.

CLASS lcl_program DEFINITION CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS main.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-METHODS descargar_mara.


    CLASS-METHODS crear_archivo
      IMPORTING
        atable     TYPE REF TO data
        directorio TYPE rlgrap-filename
        contador   TYPE ty_contador
        prefijo    TYPE rlgrap-filename
        tablename  TYPE string.

    CLASS-METHODS create_archivo_makt
      IMPORTING
        contador   TYPE ty_contador
        prefijo    TYPE rlgrap-filename
        tablename  TYPE string
        index_mara TYPE tt_mara_index
        directorio TYPE rlgrap-filename.

    CLASS-METHODS create_archivo_marc
      IMPORTING
        contador   TYPE ty_contador
        prefijo    TYPE rlgrap-filename
        tablename  TYPE string
        index_mara TYPE tt_mara_index
        directorio TYPE rlgrap-filename.

    CLASS-METHODS create_archivo_mard
      IMPORTING
        contador   TYPE ty_contador
        prefijo    TYPE rlgrap-filename
        tablename  TYPE string
        index_mara TYPE tt_mara_index
        directorio TYPE rlgrap-filename.

    CLASS-METHODS create_archivo_mvke
      IMPORTING
        contador   TYPE ty_contador
        prefijo    TYPE rlgrap-filename
        tablename  TYPE string
        index_mara TYPE tt_mara_index
        directorio TYPE rlgrap-filename.


    CLASS-METHODS create_archivo_mbew
      IMPORTING
        contador   TYPE ty_contador
        prefijo    TYPE rlgrap-filename
        tablename  TYPE string
        index_mara TYPE tt_mara_index
        directorio TYPE rlgrap-filename.

    CLASS-METHODS create_archivo_marm
      IMPORTING
        contador   TYPE ty_contador
        prefijo    TYPE rlgrap-filename
        tablename  TYPE string
        index_mara TYPE tt_mara_index
        directorio TYPE rlgrap-filename.

       CLASS-METHODS create_archivo_mlan
      IMPORTING
        contador   TYPE ty_contador
        prefijo    TYPE rlgrap-filename
        tablename  TYPE string
        index_mara TYPE tt_mara_index
        directorio TYPE rlgrap-filename.


    CLASS-METHODS cambiar_material
      IMPORTING
        i_matnr  TYPE mara-matnr
      RETURNING
        VALUE(r) TYPE mara-matnr.

ENDCLASS.

START-OF-SELECTION.
  lcl_program=>main(  ).

CLASS lcl_program IMPLEMENTATION.
  METHOD main.

    descargar_mara(  ).

  ENDMETHOD.

  METHOD descargar_mara.

    DATA index_mara TYPE tt_mara_index.
    DATA ti_mara TYPE STANDARD TABLE OF mara.
    DATA lmara LIKE LINE OF ti_mara.
    DATA contador TYPE ty_contador.
    DATA ref_data TYPE REF TO data.
    BREAK atrava01.

    SELECT * INTO lmara FROM mara WHERE matnr IN smatnr  AND lvorm NE 'X'.
      INSERT VALUE #( matnr = lmara-matnr ) INTO TABLE index_mara.
      lmara-matnr = cambiar_material( lmara-matnr ).
      APPEND lmara TO ti_mara.
      IF lines( ti_mara ) >= regxpaq.
        ADD 1 TO contador. " Nombre del Archivo
        GET REFERENCE OF ti_mara INTO ref_data.
        crear_archivo( atable = ref_data
                       directorio = pdir
                       contador = contador
                       prefijo = preffl
                       tablename = 'MARA' ).

        create_archivo_makt( index_mara = index_mara
                                contador = contador
                                directorio = pdir
                                prefijo = preffl
                                tablename = 'MAKT' ).

        create_archivo_marc( index_mara = index_mara
                             contador = contador
                             directorio = pdir
                             prefijo = preffl
                             tablename = 'MARC' ).

        create_archivo_mard( index_mara = index_mara
                         contador = contador
                         directorio = pdir
                         prefijo = preffl
                         tablename = 'MARD' ).

        create_archivo_mvke( index_mara = index_mara
                           contador = contador
                           directorio = pdir
                           prefijo = preffl
                           tablename = 'MVKE' ).

        create_archivo_mbew( index_mara = index_mara
                         contador = contador
                         directorio = pdir
                         prefijo = preffl
                         tablename = 'MBEW' ).

        create_archivo_marm( index_mara = index_mara
                         contador = contador
                         directorio = pdir
                         prefijo = preffl
                         tablename = 'MARM' ).

          create_archivo_mlan( index_mara = index_mara
                         contador = contador
                         directorio = pdir
                         prefijo = preffl
                         tablename = 'MLAN' ).

        CLEAR: ti_mara, index_mara.
      ENDIF.
    ENDSELECT.

    IF lines( ti_mara ) > 0.
      ADD 1 TO contador. " Nombre del Archivo
      GET REFERENCE OF ti_mara INTO ref_data.
      crear_archivo( atable = ref_data
                     directorio = pdir
                     contador = contador
                     prefijo = preffl
                     tablename = 'MARA' ).

      create_archivo_makt( index_mara = index_mara
                              contador = contador
                              directorio = pdir
                              prefijo = preffl
                              tablename = 'MAKT' ).

      create_archivo_marc( index_mara = index_mara
                           contador = contador
                           directorio = pdir
                           prefijo = preffl
                           tablename = 'MARC' ).

      create_archivo_mard( index_mara = index_mara
                       contador = contador
                       directorio = pdir
                       prefijo = preffl
                       tablename = 'MARD' ).

      create_archivo_mvke( index_mara = index_mara
                         contador = contador
                         directorio = pdir
                         prefijo = preffl
                         tablename = 'MVKE' ).

      create_archivo_mbew( index_mara = index_mara
                       contador = contador
                       directorio = pdir
                       prefijo = preffl
                       tablename = 'MBEW' ).

      create_archivo_marm( index_mara = index_mara
                       contador = contador
                       directorio = pdir
                       prefijo = preffl
                       tablename = 'MARM' ).


          create_archivo_mlan( index_mara = index_mara
                         contador = contador
                         directorio = pdir
                         prefijo = preffl
                         tablename = 'MLAN' ).
      CLEAR: ti_mara, index_mara.
    ENDIF.

    MESSAGE |CONTADOR:{ CONTADOR } | TYPE 'S'.
  ENDMETHOD.


  METHOD crear_archivo.

    DATA(lv_xls_file) = condense( |{ directorio }/{ prefijo }{ tablename }{ contador }.dat| ).
    DATA lv_xstring TYPE xstring .
    FIELD-SYMBOLS <anytable> TYPE STANDARD TABLE.
    ASSIGN atable->* TO <anytable>.

    CALL TRANSFORMATION id  " z_my_xml_transformation is the ID
         SOURCE table = <anytable>
         RESULT XML lv_xstring.

    OPEN DATASET lv_xls_file FOR OUTPUT IN BINARY MODE.
    IF sy-subrc EQ 0.
      TRANSFER lv_xstring TO lv_xls_file.
      CLOSE DATASET lv_xls_file.
    ELSE.
      MESSAGE e319(01) WITH
        'Error al guardar el archivo' lv_xls_file.
    ENDIF.
  ENDMETHOD.

  METHOD create_archivo_makt.

    DATA ref_data TYPE REF TO data.
    SELECT FROM makt

      FIELDS makt~*
        FOR ALL ENTRIES IN @index_mara
           WHERE matnr = @index_mara-matnr
       INTO TABLE @DATA(ti_makt).

    LOOP AT ti_makt ASSIGNING FIELD-SYMBOL(<ti_makt>).
      <ti_makt>-matnr = cambiar_material( <ti_makt>-matnr ).
    ENDLOOP.

    GET REFERENCE OF ti_makt INTO ref_data.
    crear_archivo( atable = ref_data
                   directorio = pdir
                   contador = contador
                   prefijo = preffl
                   tablename = 'MAKT' ).

  ENDMETHOD.

  METHOD create_archivo_marc.

    DATA ref_data TYPE REF TO data.
    SELECT FROM marc

      FIELDS marc~*
        FOR ALL ENTRIES IN @index_mara
           WHERE matnr = @index_mara-matnr AND lvorm NE 'X'
       INTO TABLE @DATA(ti_marc).

    LOOP AT ti_marc ASSIGNING FIELD-SYMBOL(<ti_marc>).
      <ti_marc>-matnr = cambiar_material( <ti_marc>-matnr ).
    ENDLOOP.

    GET REFERENCE OF ti_marc INTO ref_data.
    crear_archivo( atable = ref_data
                   directorio = pdir
                   contador = contador
                   prefijo = preffl
                   tablename = 'MARC' ).

  ENDMETHOD.


  METHOD create_archivo_mard.

    DATA ref_data TYPE REF TO data.
    SELECT FROM mard

      FIELDS mard~*
        FOR ALL ENTRIES IN @index_mara
           WHERE matnr = @index_mara-matnr AND lvorm NE 'X'
       INTO TABLE @DATA(ti_mard).

    LOOP AT ti_mard ASSIGNING FIELD-SYMBOL(<ti_mard>).
      <ti_mard>-matnr = cambiar_material( <ti_mard>-matnr ).
    ENDLOOP.

    GET REFERENCE OF ti_mard INTO ref_data.
    crear_archivo( atable = ref_data
                   directorio = pdir
                   contador = contador
                   prefijo = preffl
                   tablename = 'MARD' ).

  ENDMETHOD.

  METHOD create_archivo_mvke.
    TYPES: BEGIN OF ty_ls_mara,
             matnr TYPE mara-matnr,
             prdha TYPE mara-prdha,
           END OF ty_ls_mara,
           tt_ls_mara TYPE HASHED TABLE OF ty_ls_mara WITH UNIQUE KEY matnr.

    DATA ti_mara_ls TYPE tt_ls_mara.
    DATA ref_data TYPE REF TO data.

    SELECT FROM mvke
      FIELDS mvke~*
        FOR ALL ENTRIES IN @index_mara
           WHERE matnr = @index_mara-matnr AND lvorm NE 'X'
       INTO TABLE @DATA(ti_mvke).

    SELECT FROM mara
      FIELDS matnr, prdha
        FOR ALL ENTRIES IN @index_mara
           WHERE matnr = @index_mara-matnr
       INTO TABLE @ti_mara_ls.

    LOOP AT ti_mvke ASSIGNING FIELD-SYMBOL(<ti_mvke>).
      <ti_mvke>-matnr = cambiar_material( <ti_mvke>-matnr ).
      IF <ti_mvke>-prodh IS INITIAL.
        READ TABLE ti_mara_ls ASSIGNING FIELD-SYMBOL(<ti_mara_ls>)
            WITH KEY matnr = <ti_mvke>-matnr.
        IF <ti_mara_ls> IS ASSIGNED.
          <ti_mvke>-prodh = <ti_mara_ls>-prdha.
        ENDIF.
        UNASSIGN <ti_mara_ls>.
      ENDIF.
    ENDLOOP.

    GET REFERENCE OF ti_mvke INTO ref_data.
    crear_archivo( atable = ref_data
                   directorio = pdir
                   contador = contador
                   prefijo = preffl
                   tablename = 'MVKE' ).

  ENDMETHOD.

  METHOD create_archivo_mbew.

    DATA ref_data TYPE REF TO data.
    SELECT FROM mbew

      FIELDS mbew~*
        FOR ALL ENTRIES IN @index_mara
           WHERE matnr = @index_mara-matnr AND lvorm NE 'X'
       INTO TABLE @DATA(ti_mbew).

    LOOP AT ti_mbew ASSIGNING FIELD-SYMBOL(<ti_mbew>).
      <ti_mbew>-matnr = cambiar_material( <ti_mbew>-matnr ).
    ENDLOOP.

    GET REFERENCE OF ti_mbew INTO ref_data.
    crear_archivo( atable = ref_data
                   directorio = pdir
                   contador = contador
                   prefijo = preffl
                   tablename = 'MBEW' ).


  ENDMETHOD.

  METHOD create_archivo_marm.

    DATA ref_data TYPE REF TO data.
    SELECT FROM marm

      FIELDS marm~*
        FOR ALL ENTRIES IN @index_mara
           WHERE matnr = @index_mara-matnr
       INTO TABLE @DATA(ti_marm).

    LOOP AT ti_marm ASSIGNING FIELD-SYMBOL(<ti_marm>).
      <ti_marm>-matnr = cambiar_material( <ti_marm>-matnr ).
    ENDLOOP.

    GET REFERENCE OF ti_marm INTO ref_data.
    crear_archivo( atable = ref_data
                   directorio = pdir
                   contador = contador
                   prefijo = preffl
                   tablename = 'MARM' ).

  ENDMETHOD.


METHOD create_archivo_mlan.

    DATA ref_data TYPE REF TO data.
    SELECT FROM mlan

      FIELDS mlan~*
        FOR ALL ENTRIES IN @index_mara
           WHERE matnr = @index_mara-matnr
       INTO TABLE @DATA(ti_mlan).

    LOOP AT ti_mlan ASSIGNING FIELD-SYMBOL(<ti_mlan>).
      <ti_mlan>-matnr = cambiar_material( <ti_mlan>-matnr ).
    ENDLOOP.

    GET REFERENCE OF ti_mlan INTO ref_data.
    crear_archivo( atable = ref_data
                   directorio = pdir
                   contador = contador
                   prefijo = preffl
                   tablename = 'MLAN' ).

  ENDMETHOD.



  METHOD cambiar_material.
    IF prefmt <> space.
      r = |{ prefmt }{ i_matnr ALPHA = OUT }|.
    ELSE.
      r = i_matnr.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

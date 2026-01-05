*&---------------------------------------------------------------------*
*& Report ZR_MM_MQA_D_DESCARGA_PEDIDOS
*&---------------------------------------------------------------------*
*                             MQA                                      *
*----------------------------------------------------------------------*
* Proyecto          : DINANT.                                          *
* N° Requerimiento  : DINA-MM009.                                      *
* Programa          : ZR_MM_MQA_D_DESCARGAPEDIDOS                      *
* Creado por        : Alexander Moreno Rodríguez.                      *
* Fecha de creación : 2025.04.21                                       *
* Descripción       : Programa de Descarga Pedidos de Compra .         *
* Transporte        : PROK900883.                                      *
*----------------------------------------------------------------------*
*                       LOG DE MODIFICACIONES                          *
*----------------------------------------------------------------------*
* Modifcado por    : Josselin Tiverio  y NCARBA01.        *
* N° Requerimiento :  ZR_MM_MQA_D_DESCARGAPEDIDOS.                         *
* ID del cambio    : ID del pedido cambio.                             *
* Fecha del cambio : Fecha del cambio en formato AAAA.MM.DD            *
* Descripción      : Descripción breve del cambio.                     *
* Transporte       : ID de Transporte contenedor del cambio.           *
*ultima version 16/12/2025
*&---------------------------------------------------------------------*
REPORT zr_mm_mqa_d_descarga_pedidos.
TABLES: ekko.
DATA cont TYPE char2.
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
DATA lt_salida TYPE STANDARD TABLE OF zmm_s_mqa_descarga_pedidos.
DATA wa_salida TYPE zmm_s_mqa_descarga_pedidos.

* Constantes locales
CONSTANTS:lc_p TYPE c VALUE 'P',
          lc_a TYPE dxfields-location VALUE 'A'.
CONSTANTS: gc_v_serv_dir_mat_data TYPE tvarvc-name VALUE 'ZMM_RUTA_DIR_ARCH_DESC_OC'.

TYPES: BEGIN OF gty_alv.
TYPES icon TYPE icon_d.
TYPES message TYPE kcd_edtchar85.
INCLUDE TYPE zmm_s_mqa_descarga_pedidos.
TYPES: END OF gty_alv.

DATA: lt_alv TYPE TABLE OF gty_alv,
      ls_alv TYPE gty_alv.

TYPES: BEGIN OF gty_data,
         ebeln  TYPE ebeln,          "pedido
         ebelp  TYPE ebelp,          "posición del pedido
         mglief TYPE merep_mglief,   "por entregar
         mginv  TYPE merep_mginv,    "por calcular
       END OF gty_data.

DATA: lt_me2n TYPE TABLE OF gty_data,
      ls_me2n TYPE gty_data.

* Variables locales
DATA: li_host         TYPE STANDARD TABLE OF msxxlist,
      lw_host         TYPE msxxlist,
      lv_path         TYPE dxfields-longpath,
      lv_ubicacion(1) TYPE c,
      lv_abend        TYPE c.
DATA: p_valor(1), p_local(1).

FIELD-SYMBOLS: <fs_tab> TYPE STANDARD TABLE,
               <fs_it>  TYPE STANDARD TABLE.


SELECTION-SCREEN BEGIN OF BLOCK blk0 WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS: p_bukrs FOR ekko-bukrs NO INTERVALS.
SELECT-OPTIONS: p_aedat FOR ekko-aedat.
SELECT-OPTIONS: p_EBELN  FOR ekko-EBELN.
SELECTION-SCREEN END OF BLOCK blk0.

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE TEXT-003.
PARAMETERS: p_fsnam TYPE rlgrap-filename OBLIGATORY.
SELECTION-SCREEN END OF BLOCK blk1.

SELECTION-SCREEN BEGIN OF BLOCK blk2 WITH FRAME TITLE TEXT-002.
PARAMETERS: p_alv AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK blk2.

INITIALIZATION.
  SELECT SINGLE low INTO p_fsnam FROM tvarvc WHERE name = gc_v_serv_dir_mat_data.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_fsnam.
  IF p_local = 'X'.
    DATA: l_s_fol TYPE string.
    CALL METHOD cl_gui_frontend_services=>directory_browse
      EXPORTING
        window_title         = 'Selecciona un directorio'
        initial_folder       = 'C:'
      CHANGING
        selected_folder      = l_s_fol
      EXCEPTIONS
        cntl_error           = 1
        error_no_gui         = 2
        not_supported_by_gui = 3
        OTHERS               = 4.
    p_fsnam = l_s_fol.
  ELSE.
*-Nombre del servidor
    CALL FUNCTION 'RFC_GET_LOCAL_SERVERS'
      TABLES
        hosts         = li_host
      EXCEPTIONS
        not_available = 1
        OTHERS        = 2.
    IF sy-subrc IS INITIAL.
*-Nombre del servidor a la estructura
      CLEAR lw_host.
      READ TABLE li_host INTO lw_host INDEX 1.

*-Obtengo el path
      CALL FUNCTION 'F4_DXFILENAME_TOPRECURSION'
        EXPORTING
          i_location_flag = lc_a
          i_server        = lw_host-name
        IMPORTING
          o_location_flag = lv_ubicacion
          o_path          = lv_path
          abend_flag      = lv_abend
        EXCEPTIONS
          rfc_error       = 1
          error_with_gui  = 2
          OTHERS          = 3.

*-Si se obtiene un path
      IF sy-subrc    IS INITIAL AND NOT lv_path IS INITIAL AND lv_abend IS INITIAL.
*-Devuelvo ruta al parametro de selección
        p_fsnam = lv_path.
      ENDIF.
    ENDIF.
  ENDIF.


**********************************************************************
START-OF-SELECTION.
  PERFORM buscar_datos.


*&---------------------------------------------------------------------*
*&      Form  BUSCAR_DATOS
*&---------------------------------------------------------------------*
*       Buscar Datos EKKO EKPO
*----------------------------------------------------------------------*
FORM buscar_datos.
  DATA: it_record TYPE TABLE OF zmm_s_mqa_descarga_pedidos,
        ls_record TYPE zmm_s_mqa_descarga_pedidos.

  DATA: lv_dif TYPE merep_mglief.

  DATA: lt_pstyp TYPE RANGE OF pstyp,
        ls_pstyp LIKE LINE OF lt_pstyp.

*--- se excluyen valores de tipo de posición ni traslados ni servicios
  ls_pstyp-sign = 'E'.
  ls_pstyp-option = 'EQ'.
  ls_pstyp-low = '7'.
  APPEND ls_pstyp TO lt_pstyp.

  ls_pstyp-sign = 'E'.
  ls_pstyp-option = 'EQ'.
  ls_pstyp-low = '9'.
  APPEND ls_pstyp TO lt_pstyp.


  PERFORM recuperar_datos_me2n.

  CHECK NOT lt_me2n[] IS INITIAL.

  SELECT a~ebeln,
         a~bukrs,
         a~bstyp,
         a~bsakz,
         a~bsart,
         a~statu,
         a~pincr,
         a~lponr,
         a~lifnr,
         a~spras,
         a~zterm,
         a~zbd1t,
         a~zbd2t,
         a~zbd3t,
         a~zbd1p,
         a~zbd2p,
         a~ekorg,
         a~ekgrp,
         a~waers,
         a~wkurs,
         a~kufix,
         a~bedat,
         a~angnr,
         a~verkf,
         a~telf1,
         a~konnr,
         a~reswk,
         a~inco1,
         a~inco2,
         a~ktwrt,
         a~knumv,
         a~kalsm,
         a~stafo,
         a~lifre,
         a~upinc,
         a~stako,
         a~frggr,
         a~frgsx,
         a~frgke,
         a~frgzu,
         a~frgrl,
         a~lands,
         a~stceg_l,
         a~absgr,
         a~memory,
         a~procstat,
         a~rlwrt,
         a~rettp,
         a~dptyp,
         a~dppct,
         a~dpamt,
         a~inco2_l,
         a~inco3_l,
         a~ext_rev_tmstmp,
         a~force_cnt,
         a~reloc_id,
         a~fsh_item_group,
         a~fsh_vas_last_item,
         a~key_id,
         a~otb_value,
         a~otb_curr,
         a~otb_res_value,
         a~otb_spec_value,
         b~ebeln AS ebeln2,
         b~ebelp,
         b~txz01,
         b~matnr,
         b~matnr AS matnr2,
         b~bukrs AS bukrs2,
         b~werks,
         b~lgort,
         b~bednr,
         b~matkl,
         b~infnr,
         b~ktmng,
         b~menge,
         b~meins,
         b~bprme,
         b~bpumz,
         b~bpumn,
         b~umrez,
         b~umren,
         b~netpr,
         b~peinh,
         b~netwr,
         b~brtwr,
         b~webaz,
         b~mwskz,
         b~spinf,
         b~prsdr,
         b~mahnz,
         b~mahn1,
         b~mahn2,
         b~mahn3,
         b~uebto,
         b~uebtk,
         b~untto,
         b~elikz,
         b~erekz,
         b~pstyp,
         b~knttp,
         b~kzvbr,
         b~wepos,
         b~weunb,
         b~repos,
         b~webre,
         b~konnr AS konnr2,
         b~ktpnr,
         b~abftz,
         b~etfz1,
         b~etfz2,
         b~lmein,
         b~zwert,
         b~navnw,
         b~abmng,
         b~prdat,
         b~bstyp AS bstyp2,
         b~effwr,
         b~stafo AS stafo2,
         b~plifz,
         b~ntgew,
         b~gewei,
         b~arsnr,
         b~arsps,
         b~ean11,
         b~ko_prctr,
         b~brgew,
         b~volum,
         b~voleh,
         b~inco1 AS inco1x,
         b~inco2 AS inco2x,
         b~packno,
         b~gnetwr,
         b~stapo,
         b~uebpo,
         b~cuobj,
         b~druhr,
         b~drunr,
         b~abelp,
         b~anzpu,
         b~mhdrz,
         b~anfnr,
         b~anfps,
         b~banfn,
         b~bnfpo,
         b~mtart,
         b~kzwi1,
         b~kzwi2,
         b~kzwi3,
         b~kzwi4,
         b~kzwi5,
         b~kzwi6,
         b~mfzhi,
         b~ffzhi,
         b~lfret,
         b~nrfhg,
         b~bonba,
         b~afnam,
         b~tzonrc,
         b~iprkz,
         b~ccomp,
         b~reslo,
         b~prio_urg,
         b~prio_req,
         b~creationdate,
         b~creationtime
    FROM cds_po_head AS a
    INNER JOIN cds_po_items AS b
       ON b~ebeln = a~ebeln
    WHERE a~bukrs IN @p_bukrs
      AND a~aedat IN @p_aedat
     and  a~EBELN IN @p_EBELN
      AND a~bstyp = 'F'
*     AND B~ELIKZ NE 'X'
      AND b~eglkz NE 'X'              "excluir entrega final
      AND b~loekz NE 'L'              "Excluir L marcado para borrar
      AND b~pstyp IN @lt_pstyp        "Excluir Traslados y Excluir Servicios
      AND b~knttp NE 'F'              "Tipo de imputación diferente de F (Orden)
*     AND B~REPOS NE 'X'              "Excluir recepción de factura
  INTO TABLE @it_record.

  SORT it_record BY ebeln ebelp.

 SELECT *
   INTO TABLE @data(lt_ekkn2)
   FROM ekkn
   FOR ALL ENTRIES IN @it_record
   WHERE  EBELN = @it_record-EBELN
   AND    EBELP = @it_record-EBELP.


*--- se tratan las posiciones para guardar los datos con validaciones
  LOOP AT it_record ASSIGNING FIELD-SYMBOL(<fs_record>).

  READ TABLE   lt_ekkn2  INTO DATA(LS_ekkn2) WITH  KEY  EBELN  = <fs_record>-EBELN
                                                        EBELP  = <fs_record>-EBELP.


   <fs_record>-KOSTL  =  LS_ekkn2-KOSTL.
   <fs_record>-SAKTO  =  LS_ekkn2-SAKTO.
   <fs_record>-GSBER  =  LS_ekkn2-GSBER.


    CLEAR ls_me2n.
    READ TABLE lt_me2n INTO ls_me2n WITH KEY ebeln = <fs_record>-ebeln
                                             ebelp = <fs_record>-ebelp.

    IF sy-subrc = 0.
*-- se saca la diferencia para validarla
      lv_dif = ls_me2n-mglief - ls_me2n-mginv.
*--- validaciones
      IF ls_me2n-mglief = 0 AND ls_me2n-mginv = 0.
        CONTINUE.
      ELSEIF ( ls_me2n-mglief = ls_me2n-mginv ) AND ( ls_me2n-mglief NE 0 AND ls_me2n-mginv NE 0 ).
        ls_alv-message = 'La posición del pedido es apto para migrar'.
        ls_alv-icon = '@08@'.
      ELSEIF ls_me2n-mglief > ls_me2n-mginv.
        ls_alv-message = 'La posición del pedido es apto para migrar'.
        ls_alv-icon = '@08@'.
      ELSEIF ls_me2n-mglief < ls_me2n-mginv.
        ls_alv-message = 'La posición del pedido está pendiente por contabilidad'.
        ls_alv-icon = '@0A@'.
      ELSEIF lv_dif <> 0.
        ls_alv-message = 'La diferencia por entregar menos por la cantidad por calcular es distinta de cero'.
        ls_alv-icon = '@0A@'.
      ENDIF.
    ENDIF.

    MOVE-CORRESPONDING <fs_record> TO ls_alv.

*--- se rectifica la cantidad por la cantidad por calcular
    ls_alv-menge = ls_me2n-mginv.

    APPEND ls_alv TO lt_alv.
    CLEAR ls_alv.

  ENDLOOP.
  DELETE lt_alv WHERE menge = 0.

  CLEAR it_record.

   SELECT *
   INTO TABLE @data(lt_ekkn)
   FROM ekkn
   FOR ALL ENTRIES IN @lt_alv
   WHERE  EBELN = @lt_alv-EBELN
   AND    EBELP  =  @lt_alv-EBELP.



  LOOP AT lt_alv ASSIGNING FIELD-SYMBOL(<fs_alv>).

    ls_record-ebeln            =       <fs_alv>-ebeln           .
    ls_record-bukrs            =       <fs_alv>-bukrs           .
    ls_record-bstyp            =       <fs_alv>-bstyp           .
    ls_record-bsakz            =       <fs_alv>-bsakz           .
    ls_record-bsart            =       <fs_alv>-bsart           .
    ls_record-statu            =       <fs_alv>-statu           .
    ls_record-pincr            =       <fs_alv>-pincr           .
    ls_record-lponr            =       <fs_alv>-lponr           .
    ls_record-lifnr            =       <fs_alv>-lifnr           .
    ls_record-spras            =       <fs_alv>-spras           .
    ls_record-zterm            =       <fs_alv>-zterm           .
    ls_record-zbd1t            =       <fs_alv>-zbd1t           .
    ls_record-zbd2t            =       <fs_alv>-zbd2t           .
    ls_record-zbd3t            =       <fs_alv>-zbd3t           .
    ls_record-zbd1p            =       <fs_alv>-zbd1p           .
    ls_record-zbd2p            =       <fs_alv>-zbd2p           .
    ls_record-ekorg            =       <fs_alv>-ekorg           .
    ls_record-ekgrp            =       <fs_alv>-ekgrp           .
    ls_record-waers            =       <fs_alv>-waers           .
    ls_record-wkurs            =       <fs_alv>-wkurs           .
    ls_record-bedat             =       <fs_alv>-bedat            .
    ls_record-angnr            =       <fs_alv>-angnr           .
    ls_record-verkf            =       <fs_alv>-verkf           .
    ls_record-telf1            =       <fs_alv>-telf1           .
    ls_record-konnr            =       <fs_alv>-konnr           .
    ls_record-reswk            =       <fs_alv>-reswk           .
    ls_record-inco1            =       <fs_alv>-inco1           .
    ls_record-inco2            =       <fs_alv>-inco2           .
    ls_record-ktwrt            =       <fs_alv>-ktwrt           .
    ls_record-knumv            =       <fs_alv>-knumv           .
    ls_record-kalsm            =       <fs_alv>-kalsm           .
    ls_record-stafo            =       <fs_alv>-stafo           .
    ls_record-lifre            =       <fs_alv>-lifre           .
    ls_record-upinc            =       <fs_alv>-upinc           .
    ls_record-stako            =       <fs_alv>-stako           .
    ls_record-frggr            =       <fs_alv>-frggr           .
    ls_record-frgsx            =       <fs_alv>-frgsx           .
    ls_record-frgke            =       <fs_alv>-frgke           .
    ls_record-frgzu            =       <fs_alv>-frgzu           .
    ls_record-frgrl            =       <fs_alv>-frgrl           .
    ls_record-lands            =       <fs_alv>-lands           .
    ls_record-stceg_l          =       <fs_alv>-stceg_l         .
    ls_record-absgr            =       <fs_alv>-absgr           .
    ls_record-memory           =       <fs_alv>-memory          .
    ls_record-procstat         =       <fs_alv>-procstat        .
    ls_record-rlwrt            =       <fs_alv>-rlwrt           .
    ls_record-rettp            =       <fs_alv>-rettp           .
    ls_record-dptyp            =       <fs_alv>-dptyp           .
    ls_record-dppct            =       <fs_alv>-dppct           .
    ls_record-dpamt            =       <fs_alv>-dpamt           .
    ls_record-inco2_l          =       <fs_alv>-inco2_l         .
    ls_record-inco3_l          =       <fs_alv>-inco3_l         .
    ls_record-ext_rev_tmstmp   =       <fs_alv>-ext_rev_tmstmp  .
    ls_record-force_cnt        =       <fs_alv>-force_cnt       .
    ls_record-reloc_id         =       <fs_alv>-reloc_id        .
    ls_record-fsh_item_group   =       <fs_alv>-fsh_item_group  .
    ls_record-fsh_vas_last_item =       <fs_alv>-fsh_vas_last_item.
    ls_record-key_id           =       <fs_alv>-key_id          .
    ls_record-otb_value        =       <fs_alv>-otb_value       .
    ls_record-otb_curr         =       <fs_alv>-otb_curr        .
    ls_record-otb_res_value    =       <fs_alv>-otb_res_value   .
    ls_record-otb_spec_value   =       <fs_alv>-otb_spec_value  .
    ls_record-ebeln2           =       <fs_alv>-ebeln2          .
    ls_record-ebelp            =       <fs_alv>-ebelp           .
    ls_record-txz01            =       <fs_alv>-txz01           .
    ls_record-matnr            =       <fs_alv>-matnr           .
    ls_record-matnr2           =       <fs_alv>-matnr2          .
    ls_record-bukrs2           =       <fs_alv>-bukrs2          .
    ls_record-werks            =       <fs_alv>-werks           .
    ls_record-lgort            =       <fs_alv>-lgort           .
    ls_record-bednr            =       <fs_alv>-bednr           .
    ls_record-matkl            =       <fs_alv>-matkl           .
    ls_record-infnr            =       <fs_alv>-infnr           .
    ls_record-ktmng            =       <fs_alv>-ktmng           .
    ls_record-menge            =       <fs_alv>-menge           .
    ls_record-meins            =       <fs_alv>-meins           .
    ls_record-bprme            =       <fs_alv>-bprme           .
    ls_record-bpumz            =       <fs_alv>-bpumz           .
    ls_record-bpumn            =       <fs_alv>-bpumn           .
    ls_record-umrez            =       <fs_alv>-umrez           .
    ls_record-umren            =       <fs_alv>-umren           .
    ls_record-netpr            =       <fs_alv>-netpr           .
    ls_record-peinh            =       <fs_alv>-peinh           .
    ls_record-netwr            =       <fs_alv>-netwr           .
    ls_record-brtwr            =       <fs_alv>-brtwr           .
    ls_record-webaz            =       <fs_alv>-webaz           .
    ls_record-mwskz            =       <fs_alv>-mwskz           .
    ls_record-spinf            =       <fs_alv>-spinf           .
    ls_record-prsdr            =       <fs_alv>-prsdr           .
    ls_record-mahnz            =       <fs_alv>-mahnz           .
    ls_record-mahn1            =       <fs_alv>-mahn1           .
    ls_record-mahn2            =       <fs_alv>-mahn2           .
    ls_record-mahn3            =       <fs_alv>-mahn3           .
    ls_record-uebto            =       <fs_alv>-uebto           .
    ls_record-uebtk            =       <fs_alv>-uebtk           .
    ls_record-untto            =       <fs_alv>-untto           .
    ls_record-elikz            =       <fs_alv>-elikz           .
    ls_record-erekz            =       <fs_alv>-erekz           .
    ls_record-pstyp           =        <fs_alv>-pstyp          .
    ls_record-knttp           =        <fs_alv>-knttp          .
    ls_record-kzvbr           =        <fs_alv>-kzvbr          .
    ls_record-wepos           =        <fs_alv>-wepos          .
    ls_record-weunb           =        <fs_alv>-weunb          .
    ls_record-repos           =        <fs_alv>-repos          .
    ls_record-webre           =        <fs_alv>-webre          .
    ls_record-konnr2          =        <fs_alv>-konnr2         .
    ls_record-ktpnr           =        <fs_alv>-ktpnr          .
    ls_record-abftz           =        <fs_alv>-abftz          .
    ls_record-etfz1           =        <fs_alv>-etfz1          .
    ls_record-etfz2           =        <fs_alv>-etfz2          .
    ls_record-lmein           =        <fs_alv>-lmein          .
    ls_record-zwert           =        <fs_alv>-zwert          .
    ls_record-navnw           =        <fs_alv>-navnw          .
    ls_record-abmng           =        <fs_alv>-abmng          .
    ls_record-prdat            =       <fs_alv>-prdat           .
    ls_record-bstyp2           =       <fs_alv>-bstyp2          .
    ls_record-effwr            =       <fs_alv>-effwr           .
    ls_record-stafo2           =       <fs_alv>-stafo2          .
    ls_record-plifz            =       <fs_alv>-plifz           .
    ls_record-ntgew            =       <fs_alv>-ntgew           .
    ls_record-gewei            =       <fs_alv>-gewei           .
    ls_record-arsnr            =       <fs_alv>-arsnr           .
    ls_record-arsps            =       <fs_alv>-arsps           .
    ls_record-ean11            =       <fs_alv>-ean11           .
    ls_record-ko_prctr         =       <fs_alv>-ko_prctr        .
    ls_record-brgew            =       <fs_alv>-brgew           .
    ls_record-volum            =       <fs_alv>-volum           .
    ls_record-voleh            =       <fs_alv>-voleh           .
    ls_record-inco1x           =       <fs_alv>-inco1x          .
    ls_record-inco2x           =       <fs_alv>-inco2x          .
    ls_record-packno           =       <fs_alv>-packno          .
    ls_record-gnetwr           =       <fs_alv>-gnetwr          .
    ls_record-stapo2           =       <fs_alv>-stapo2          .
    ls_record-uebpo            =       <fs_alv>-uebpo           .
    ls_record-cuobj            =       <fs_alv>-cuobj           .
    ls_record-druhr            =       <fs_alv>-druhr           .
    ls_record-drunr            =       <fs_alv>-drunr           .
    ls_record-abelp            =       <fs_alv>-abelp           .
    ls_record-anzpu            =       <fs_alv>-anzpu           .
    ls_record-mhdrz            =       <fs_alv>-mhdrz           .
    ls_record-anfnr            =       <fs_alv>-anfnr           .
    ls_record-anfps            =       <fs_alv>-anfps           .
    ls_record-banfn            =       <fs_alv>-banfn           .
    ls_record-bnfpo            =       <fs_alv>-bnfpo           .
    ls_record-mtart            =       <fs_alv>-mtart           .
    ls_record-kzwi1            =       <fs_alv>-kzwi1           .
    ls_record-kzwi2            =       <fs_alv>-kzwi2           .
    ls_record-kzwi3            =       <fs_alv>-kzwi3           .
    ls_record-kzwi4            =       <fs_alv>-kzwi4           .
    ls_record-kzwi5            =       <fs_alv>-kzwi5           .
    ls_record-kzwi6            =       <fs_alv>-kzwi6           .
    ls_record-mfzhi            =       <fs_alv>-mfzhi           .
    ls_record-ffzhi            =       <fs_alv>-ffzhi           .
    ls_record-lfret            =       <fs_alv>-lfret           .
    ls_record-nrfhg            =       <fs_alv>-nrfhg           .
    ls_record-bonba            =       <fs_alv>-bonba           .
    ls_record-afnam            =       <fs_alv>-afnam           .
    ls_record-tzonrc           =       <fs_alv>-tzonrc          .
    ls_record-iprkz            =       <fs_alv>-iprkz           .
    ls_record-ccomp            =       <fs_alv>-ccomp           .
    ls_record-reslo            =       <fs_alv>-reslo           .
    ls_record-prio_urg         =       <fs_alv>-prio_urg        .
    ls_record-prio_req         =       <fs_alv>-prio_req        .
    ls_record-creationdate     =       <fs_alv>-creationdate    .
    ls_record-creationdate     =       <fs_alv>-creationdate    .
READ TABLE   lt_ekkn  INTO DATA(LS_ekkn) WITH  KEY  EBELN  = <fs_alv>-EBELN
                                                      EBELP   =  <fs_alv>-EBELP.

if  LS_ekkn is NOT INITIAL .
    ls_record-KOSTL = LS_ekkn-KOSTL.
    ls_record-SAKTO = LS_ekkn-SAKTO.
    ls_record-GSBER = LS_ekkn-GSBER.

    ENDIF.
    APPEND ls_record TO it_record.

  ENDLOOP.
  " Descaga archivo excel.
* Cabecera
  lc_tabname = 'ZMM_S_MQA_DESCARGA_PEDIDOS'.
  SELECT tabname position fieldname rollname
    FROM dd03l
    INTO CORRESPONDING FIELDS OF TABLE lt_campos
  WHERE tabname EQ lc_tabname.

  IF NOT lt_campos[] IS INITIAL.
    SELECT rollname scrtext_s scrtext_m scrtext_l
      INTO CORRESPONDING FIELDS OF TABLE lt_rollname
      FROM dd04t
       FOR ALL ENTRIES IN lt_campos
     WHERE rollname   = lt_campos-rollname
    AND ddlanguage = sy-langu.
  ENDIF.
  SORT lt_campos BY position.
  DELETE lt_campos WHERE fieldname(1) = '.'.

* Obtengo las cabeceras de columna y las agrego en lt_cabeceras para exportarlas
  CLEAR wa_cabeceras.
  LOOP AT lt_campos.
    READ TABLE lt_rollname WITH KEY rollname = lt_campos-rollname.
    CLEAR wa_cabeceras.
    wa_cabeceras-fieldname = lt_rollname-scrtext_m.
    APPEND wa_cabeceras TO lt_cabeceras.
  ENDLOOP.

  lv_encoding = '4103'.
  DESCRIBE TABLE it_record LINES DATA(lin).

  lc_tabint  = c_t_salida.
  ASSIGN (lc_tabint) TO <fs_it>.
  LOOP AT it_record INTO DATA(ls_result).
    var = var + 1.
    APPEND ls_result TO <fs_it>.
    IF var = 2000 OR var = lin.
      cont = cont + 1.
      compu = strlen( cont ).
      IF compu = 1.
        CONCATENATE p_fsnam '/OC_' sy-datum+6(2) sy-datum+4(2) sy-datum(4) '_0' cont INTO lc_archivo.
      ELSE.
        CONCATENATE p_fsnam '/OC_' sy-datum+6(2) sy-datum+4(2) sy-datum(4) '_' cont INTO lc_archivo.
      ENDIF.

      PERFORM download_excel_cl.
      CLEAR  var.
      REFRESH: <fs_it>.
    ENDIF.
  ENDLOOP.

  " Imprimir eesultado de la busqueda
  IF p_alv = 'X'.
    DATA: functions TYPE REF TO cl_salv_functions_list.
    DATA: o_alv TYPE REF TO cl_salv_table.
    TRY.
        cl_salv_table=>factory( EXPORTING list_display = abap_false
                                IMPORTING r_salv_table = o_alv
                                CHANGING  t_table      = lt_alv ).
        functions = o_alv->get_functions( ).
        functions->set_all( abap_true ).

        o_alv->display( ).

      CATCH cx_salv_msg.
        MESSAGE TEXT-t08
            TYPE 'I'
            DISPLAY LIKE 'E'.

    ENDTRY.

  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD_EXCEL
*&---------------------------------------------------------------------*
*       Download Excel
*----------------------------------------------------------------------*
FORM download_excel.
  TYPES:
    BEGIN OF ty_s_cline,
      line TYPE c LENGTH 1024, " Line of type Character
    END OF ty_s_cline .

  DATA: gr_table     TYPE REF TO cl_salv_table,          " Basis Class for Simple Tables
        lr_functions TYPE REF TO cl_salv_functions_list, " Generic and User-Defined Functions in List-Type Tables
        lr_layout    TYPE REF TO cl_salv_layout,         " Settings for Layout
        lv_xml_type  TYPE salv_bs_constant,
        lv_xml       TYPE xstring,
        gt_srctab    TYPE STANDARD TABLE OF ty_s_cline,
        gt_len       TYPE i,                             " Len of type Integers
        lv_file_xlsx TYPE string,
        lv_file      TYPE localfile,                     " Local file for upload/download
        ls_key       TYPE salv_s_layout_key,             " Layout Key
        lr_content   TYPE REF TO cl_salv_form_element.   " General Element in Design Object

  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = gr_table
        CHANGING
          t_table      = <fs_it> ).

    CATCH cx_salv_msg.                                  "#EC NO_HANDLER

  ENDTRY.

  lr_functions = gr_table->get_functions( ).
  lr_functions->set_all( abap_true ).
  lr_layout = gr_table->get_layout( ).
  ls_key-report = sy-repid.
  lr_layout->set_key( ls_key ).
  lr_layout->set_save_restriction( if_salv_c_layout=>restrict_user_independant ).
  gr_table->set_top_of_list( lr_content ).
  gr_table->set_end_of_list( lr_content ).

  lv_xml_type =  if_salv_bs_xml=>c_type_xlsx. "if_salv_bs_xml=>c_type_mhtml.

  lv_xml      = gr_table->to_xml( xml_type = lv_xml_type ).

  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      buffer        = lv_xml
    IMPORTING
      output_length = gt_len
    TABLES
      binary_tab    = gt_srctab.

  lv_file_xlsx = lc_archivo.
  CALL METHOD cl_gui_frontend_services=>gui_download
    EXPORTING
      bin_filesize            = gt_len
      filename                = lv_file_xlsx
      filetype                = 'BIN'
    CHANGING
      data_tab                = gt_srctab
    EXCEPTIONS
      file_write_error        = 1
      no_batch                = 2
      gui_refuse_filetransfer = 3
      invalid_type            = 4
      no_authority            = 5
      unknown_error           = 6
      header_not_allowed      = 7
      separator_not_allowed   = 8
      filesize_not_allowed    = 9
      header_too_long         = 10
      dp_error_create         = 11
      dp_error_send           = 12
      dp_error_write          = 13
      unknown_dp_error        = 14
      access_denied           = 15
      dp_out_of_memory        = 16
      disk_full               = 17
      dp_timeout              = 18
      file_not_found          = 19
      dataprovider_exception  = 20
      control_flush_error     = 21
      not_supported_by_gui    = 22
      error_no_gui            = 23
      OTHERS                  = 24.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    MESSAGE 'Excel file downloaded!' TYPE 'S'.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD_EXCEL_CL
*&---------------------------------------------------------------------*
*       Descarga Excel.
*----------------------------------------------------------------------*
FORM download_excel_cl .
  TRY.
      DATA(lo_excel) = NEW zcl_mm_utility_excel( ).
      DATA(lv_bytes) = lo_excel->download_xlsx( EXPORTING iv_file_path = |{ lc_archivo }.xlsx| ir_table = REF #( <fs_it> ) iv_server = abap_true ).
    CATCH zcx_mm_utility_excel INTO DATA(lx_err).
      MESSAGE lx_err->get_text( ) TYPE 'I' DISPLAY LIKE 'E'.
  ENDTRY.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    SKIP.
    WRITE: /1 'Resumen descarga de datos:', lc_archivo.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  RECUPERAR_DATOS_ME2N
*&---------------------------------------------------------------------*
*       ME2N
*----------------------------------------------------------------------*
FORM recuperar_datos_me2n.
  DATA g_varnt TYPE variant VALUE 'MIGRACION_PED'.
  DATA g_listu TYPE listu VALUE 'X_GRP_ART'.
  DATA g_knttp TYPE knttp VALUE 'F'.
  DATA: lv_lines TYPE i,
        l_subrc  TYPE sy-subrc.
  DATA: list_tab TYPE TABLE OF abaplist.
  DATA lit_string TYPE list_string_table.
  DATA: lv_string TYPE string,
        lt_split  TYPE TABLE OF char80.

  DATA lv_tb_lng TYPE i.

*--- BOM 20250902 jotaiz01
*--- se mejora la manera en que se rescatan los datos de la tx ME2N
*--- en vez de trabajarlo por la lista en memoria, se trabaja con la
*--- clase ALV cl_salv_bs_runtime_info
*--- declaraciones necesarias
  DATA: gfs_datpd TYPE REF TO data,
        lit_line  TYPE REF TO data.

  FIELD-SYMBOLS: <gft_datpd>  TYPE ANY TABLE,
                 <gfs_datpd>  TYPE any,
                 <gfs_custom> TYPE any.

*--- se setea la clase cl_alv_bs_runtime_info para traer los datos a una tabla interna
*--- de una transacción standard en este caso la ME2N por el submit al programa RM06EN00
*--- Settings - No ALV display, No metadata(Layout, Field Catalog) needed, ALV Data is needed
  cl_salv_bs_runtime_info=>set( EXPORTING display  = abap_false
                                          metadata = abap_false
                                          data     = abap_true ).

*--- hago el submit sin traer los datos exportados como lista a memoria
*--- solo le paso la variante la fecha y la base
  SUBMIT rm06en00
    USING SELECTION-SET g_varnt
    WITH listu   = g_listu
    WITH s_bedat IN p_aedat
  AND RETURN.

*--- se importan los datos del alv del reporte standard
  TRY.
      cl_salv_bs_runtime_info=>get_data_ref( IMPORTING r_data = gfs_datpd ).
      IF gfs_datpd IS NOT INITIAL.
        TRY.
            ASSIGN gfs_datpd->* TO <gft_datpd>.
          CATCH cx_salv_bs_sc_runtime_info.
            MESSAGE 'No se pudo recuperar los datos del ALV' TYPE 'E'.
        ENDTRY.
      ENDIF.
  ENDTRY.

*--- se llena la tabla interna dinamica con los campos requeridos
  IF <gft_datpd> IS NOT INITIAL.
    CREATE DATA lit_line LIKE LINE OF <gft_datpd>.
    ASSIGN lit_line->* TO <gfs_datpd>.

*--- se iteran los datos para asignarlos a la tabla de los datos de la ME2N
    LOOP AT <gft_datpd> ASSIGNING <gfs_datpd>.
      ASSIGN COMPONENT 'EBELN' OF STRUCTURE <gfs_datpd> TO <gfs_custom>.
      IF sy-subrc EQ 0.
        ls_me2n-ebeln = <gfs_custom>.
      ENDIF.
      ASSIGN COMPONENT 'EBELP' OF STRUCTURE <gfs_datpd> TO <gfs_custom>.
      IF sy-subrc EQ 0.
        ls_me2n-ebelp = <gfs_custom>.
      ENDIF.
      ASSIGN COMPONENT 'MGLIEF' OF STRUCTURE <gfs_datpd> TO <gfs_custom>.
      IF sy-subrc EQ 0.
        ls_me2n-mglief = <gfs_custom>.
      ENDIF.
      ASSIGN COMPONENT 'MGINV' OF STRUCTURE <gfs_datpd> TO <gfs_custom>.
      IF sy-subrc EQ 0.
        ls_me2n-mginv = <gfs_custom>.
      ENDIF.

      APPEND ls_me2n TO lt_me2n.
      CLEAR: ls_me2n.
    ENDLOOP.

    cl_salv_bs_runtime_info=>clear_all( ).

    DELETE lt_me2n WHERE mginv = 0.
  ENDIF.

****  SUBMIT RM06EN00 USING SELECTION-SET G_VARNT
****    WITH LISTU   = G_LISTU
****    WITH S_BEDAT IN P_AEDAT
****  EXPORTING LIST TO MEMORY
****  AND RETURN.


****  CALL FUNCTION 'LIST_FROM_MEMORY'
****    TABLES
****      LISTOBJECT = LIST_TAB
****    EXCEPTIONS
****      NOT_FOUND  = 1
****      OTHERS     = 2.
****
****  CALL FUNCTION 'LIST_TO_ASCI'
****    EXPORTING
****      LIST_INDEX         = -1
****      WITH_LINE_BREAK    = ' '
****    IMPORTING
****      LIST_STRING_ASCII  = LIT_STRING         "Screen Output/Readable Format
****    TABLES
****      LISTOBJECT         = LIST_TAB
****    EXCEPTIONS
****      EMPTY_LIST         = 1
****      LIST_INDEX_INVALID = 2
****      OTHERS             = 3.

****  LOOP AT LIT_STRING INTO DATA(WA_DATA).
****    IF SY-TABIX > 3.
****      CLEAR LT_SPLIT[].
****      MOVE WA_DATA+1 TO LV_STRING .
****      CONDENSE LV_STRING NO-GAPS.
****      SPLIT LV_STRING AT '|' INTO TABLE LT_SPLIT.
****      CLEAR L_SUBRC.
****
****      DESCRIBE TABLE LT_SPLIT LINES LV_TB_LNG.
****
****      LOOP AT LT_SPLIT INTO DATA(WA).
****        REPLACE ALL OCCURRENCES OF ',' IN WA WITH SPACE.
****        CONDENSE WA NO-GAPS.
****        IF LV_TB_LNG = 75.
****          CASE SY-TABIX.
****            WHEN 1.
****              LS_ME2N-EBELN = WA.
****              CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
****                EXPORTING
****                  INPUT  = LS_ME2N-EBELN
****                IMPORTING
****                  OUTPUT = LS_ME2N-EBELN.
****            WHEN 2.
****              LS_ME2N-EBELP = WA.
****            WHEN 20.
****              IF WA NE 'Ctd.pedido'.
****                LS_ME2N-MENGE = WA.
****              ENDIF.
****            WHEN 40.
****              IF WA NE 'Porcalcular' AND WA NE 'Cantidad'.
****                LS_ME2N-PORCA = WA.
****              ENDIF.
****          ENDCASE.
****        ENDIF.
****        IF LV_TB_LNG = 76.
****          CASE SY-TABIX.
****            WHEN 1.
****              LS_ME2N-EBELN = WA.
****              CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
****                EXPORTING
****                  INPUT  = LS_ME2N-EBELN
****                IMPORTING
****                  OUTPUT = LS_ME2N-EBELN.
****            WHEN 2.
****              LS_ME2N-EBELP = WA.
****            WHEN 21.
****              IF WA NE 'Ctd.pedido'.
****                LS_ME2N-MENGE = WA.
****              ENDIF.
****            WHEN 23.
****              IF WA NE 'Porcalcular'.
****                LS_ME2N-PORCA = WA.
****              ENDIF.
****          ENDCASE.
****        ENDIF.
****      ENDLOOP.
****      APPEND LS_ME2N TO LT_ME2N.
****    ENDIF.
****
****  ENDLOOP.
****  " 1.  Si la cantidad por calcular MGINV es igual a cero, el pedido ya se contabilizó
****  DELETE LT_ME2N WHERE PORCA = 0 and menge = 0.

ENDFORM.

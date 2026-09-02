**------------------------------------------------------------------------------------*
** Title   : Z_ARC_FIREFIGHTER                                                        *
**------------------------------------------------------------------------------------*
** Copyright  (c) 2025 Archon Meridian GbR, Deutschland All rights reserved           *
**                                                                                    *
** Project : SAP Firefighter ID (“ARCFFID”)                                           *
**                                                                                    *
** Author  : Uwe Schlegel                                                             *
**                                                                                    *
** Description: This application allows SAP users to request temporary Firefighter    *
**              ID access for system debugging. The process includes submitting a     *
**              request with a reason, approval by an admin, and tracking of user     *
**              activities during the access period. Admins can manage approvals &    *
**              maintain a list of authorized users through a dedicated admin screen. *
**              The app ensures secure, auditable, and controlled debugging access.   *
**                                                                                    *
**------------------------------------------------------------------------------------*
**    Dev.          DATE            Description                                       *
**------------------------------------------------------------------------------------*
**   <ALIABID>     20250711   Firefighter ID access for system debugging              *
**------------------------------------------------------------------------------------*
** CHANGE  HISTORY                                                                    *
**------------------------------------------------------------------------------------*
** Dev.          DATE          Description                                            *
**------------------------------------------------------------------------------------*
*
**-> Start of Code added by Abid Ali
REPORT z_arc_firefighter.  "Program
TABLES: zfire_req.
DATA: ok_code TYPE sy-ucomm,
     save_ok TYPE sy-ucomm.
**-> End of Code added by Abid Ali
*DATA: lv_ts         TYPE timestamp,
*      lv_date       TYPE d,
*      lv_time       TYPE t,
*      lv_created_at TYPE char14,
*      lv_ts_start   TYPE timestamp,
*      lv_ts_end     TYPE timestamp,
*      lv_acc_start  TYPE char14,
*      lv_acc_end    TYPE char14,
*      lv_tzone      TYPE tzone.
*
*DATA:
*  lv_date_103  TYPE d,
*  lv_time_103  TYPE t,
*  lv_tzone_str TYPE string.
*
*DATA: lv_char14 TYPE char14.
*DATA: gv_error TYPE c.
*DATA gv_error_text TYPE string. "Collect the error message
*
**KANISHK - SHOW THE USER ALL OF ITS REQUESTS -----------------------
*
**TYPES: BEGIN OF ty_req_list,
**         req_id                 TYPE zfire_req-req_id,
**         req_user               TYPE zfire_req-req_user,
**         req_ffid               TYPE zfire_req-req_ffid,
**         target_system          TYPE zfire_req-target_system,
**         status                 TYPE zfire_req-status,
**         ctrl_doc_ok            TYPE zfire_req-ctrl_doc_ok,
**         justification          TYPE zfire_req-justification,
**
**         access_start           TYPE zfire_req-access_start,
**         access_start_utc       TYPE string,
**         access_start_tz        TYPE string,
**         access_end             TYPE zfire_req-access_end,
**         access_end_utc         TYPE string,
**         access_end_tz          TYPE string,
**         req_tzone              TYPE zfire_req-req_tzone,
**         req_ianatzone          TYPE zfire_req-req_ianatzone,
**         " Custom Output Fields for Timezones
**
**         approver               TYPE zfire_req-approver,
**         approved_at            TYPE zfire_req-approved_at,
**         approved_at_disp       TYPE string,
**         created_at             TYPE zfire_req-created_at,
**         created_at_disp        TYPE string,
**         changed_at             TYPE zfire_req-changed_at,
**         changed_at_disp        TYPE string,
**         email_addr             TYPE zfire_req-email_addr,
**         ticket_no              TYPE zfire_req-ticket_no,
**         planned_activity       TYPE zfire_req-planned_activity,
**         stage_no               TYPE zfire_req-stage_no,
**         " ZFILE_STORE Table Fields
**         file_id                TYPE zfile_store-file_id,
**         post_doc_justification TYPE zfile_store-post_doc_justification,
**         filename               TYPE zfile_store-filename,
**         mimetype               TYPE zfile_store-mimetype,
**         created_by             TYPE zfile_store-created_by,
**         created_on             TYPE zfile_store-created_on,
**         row_color              TYPE lvc_t_scol,
**
**       END OF ty_req_list.
*
**FIELD-SYMBOLS <fs_req_list> TYPE ty_req_list.
*
*DATA:
**gt_req_list TYPE STANDARD TABLE OF ty_req_list,
*      go_cont     TYPE REF TO cl_gui_custom_container,
*      go_grid     TYPE REF TO cl_gui_alv_grid,
*      gt_fcat     TYPE lvc_t_fcat,
*      gs_fcat     TYPE lvc_s_fcat,
*      gs_layo     TYPE lvc_s_layo.
*
*DATA lv_formatted_ts TYPE string.
*
*
**--------------------------------------------------------------------
*
**KANISHK - SHOW ACTIVE FFID SESSION OF USER - SCREEN 103 ------------
*
*DATA:
**gv_req_id_103         TYPE "zfire_req-req_id,
**      gv_ff_id_103          TYPE zfire_req-req_ffid,
**      gv_acc_start_103      TYPE zfire_req-access_start,
**      gv_acc_end_103        TYPE zfire_req-access_end,
*      gv_acc_start_103_disp TYPE string,
*      gv_acc_end_103_disp   TYPE string,
*      gv_remaining_103      TYPE char30.
*
**--------------------------------------------------------------------
*
**KANISHK - SEND EMAIL TO APPROVERS ON REQUEST SAVE ------------------
*
*TYPES: tty_addr TYPE STANDARD TABLE OF ad_smtpadr WITH EMPTY KEY.
*
**--------------------------------------------------------------------
*
**DATA: gv_planned_activity TYPE zfire_req-planned_activity.
*
**-> Start of Code added by Abid Ali
**DATA: itab_1      TYPE TABLE OF zfire_req,
**      itab_status TYPE TABLE OF zfire_req_status.
*DATA: "lt_req_status TYPE TABLE OF zfire_req_status,
*      lo_cust       TYPE REF TO cl_gui_custom_container,
*      lo_alv        TYPE REF TO cl_gui_alv_grid,
*      lo_cust_104   TYPE REF TO cl_gui_custom_container,
*      lo_alv_104    TYPE REF TO cl_gui_alv_grid.
*
*CONTROLS ffid TYPE TABLEVIEW USING SCREEN 101.
*DATA: cols         LIKE LINE OF ffid-cols,
*      lines        TYPE i,
*      gv_modified  TYPE c,
*      it_bapiret2  TYPE TABLE OF bapiret2,
*      lt_bal_t_msg TYPE STANDARD TABLE OF bal_s_msg.
*
*DATA: go_cc_just     TYPE REF TO cl_gui_custom_container,
*      go_textedit    TYPE REF TO cl_gui_textedit,
*      gt_just_stream TYPE STANDARD TABLE OF char255 WITH EMPTY KEY,
*      gv_just_text   TYPE string.
*CONSTANTS:  gc_cc_just      TYPE scrfname VALUE 'CC_JUST'.
*DATA: gv_edit_mode TYPE abap_bool VALUE abap_false.  "abap_false = display, abap_true = edit
*
*DATA: gv_save TYPE abap_bool.
*
*
*LOOP AT ffid-cols INTO cols. "WHERE index GT 1.
*  cols-screen-input = '0'.
*  MODIFY ffid-cols FROM cols INDEX sy-tabix.
*ENDLOOP.
*
*CALL SCREEN 100.
*CLASS lcl_event_receiver DEFINITION.
*  PUBLIC SECTION.
*    METHODS on_double_click
*      FOR EVENT double_click OF cl_gui_alv_grid
*      IMPORTING e_row e_column.
*
*ENDCLASS.
*
*DATA: go_evt TYPE REF TO lcl_event_receiver.
*
*CLASS lcl_event_receiver IMPLEMENTATION.
*  METHOD on_double_click.
*
**    DATA ls_req TYPE ty_req_list.
**    READ TABLE gt_req_list INDEX e_row INTO ls_req.
**    CHECK sy-subrc = 0.
**
**    EXPORT
**      req_id   = ls_req-req_id
**      req_user = ls_req-req_user
**      approver = ls_req-approver
**      req_ffid = ls_req-req_ffid
**      TO MEMORY ID 'ZREQ_MEM'.
**
**    SUBMIT zmp_file_upload AND RETURN.
*
*  ENDMETHOD.
*
*ENDCLASS.
*
*MODULE status_0100 OUTPUT.
*  SET PF-STATUS 'STATUS'.
*  SET TITLEBAR 'TITLE'.
*ENDMODULE.
**&---------------------------------------------------------------------*
**&      Module  USER_COMMAND_0100  INPUT
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
*MODULE user_command_0100 INPUT.
*  save_ok = ok_code.
*  CLEAR ok_code.
*  CASE save_ok.
*    WHEN 'REQUEST'.
*      CALL SCREEN 101.
*    WHEN 'STATUS'.
*      PERFORM data_fetch.
*      CALL SCREEN 102.
*    WHEN 'ACTIVE'.
*      CALL SCREEN 103.
*    WHEN 'DOCU'.
*      PERFORM data_fetch.
*      CALL SCREEN 104.
*    WHEN 'EXIT' OR 'BACK'.
*      PERFORM dequeue_lock.   " release lock
*      LEAVE PROGRAM.
*
*  ENDCASE.
*ENDMODULE.
**&---------------------------------------------------------------------*
**&      Module  CANCEL  INPUT
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
*MODULE cancel INPUT.
*  PERFORM dequeue_lock.   " release lock
*  LEAVE PROGRAM.
*ENDMODULE.
**&---------------------------------------------------------------------*
**& Module STATUS_0101 OUTPUT
**&---------------------------------------------------------------------*
**&
**&---------------------------------------------------------------------*
*MODULE status_0101 OUTPUT.
*  SET PF-STATUS 'STATUS_101'.
*  SET TITLEBAR 'TITLE'.
** DESCRIBE TABLE itab_1 LINES lines.
**  ffid-lines = lines.
*  ffid-lines = 1.   " Show only one row
*
*  IF go_cc_just IS INITIAL.
*    CREATE OBJECT go_cc_just
*      EXPORTING
*        container_name = gc_cc_just.
*
*    CREATE OBJECT go_textedit
*      EXPORTING
*        parent = go_cc_just.
*  ENDIF.
*
*  "Always force mode here (default display)
*  IF go_textedit IS BOUND.
*    IF gv_edit_mode = abap_true.
*      go_textedit->set_readonly_mode( readonly_mode = 0 ). "editable
*    ELSE.
*      go_textedit->set_readonly_mode( readonly_mode = 1 ). "display/read-only
*    ENDIF.
*  ENDIF.
*
*  LOOP AT ffid-cols INTO cols WHERE index GT 1.
*    IF gv_edit_mode = abap_true.
*      cols-screen-input = '1'.   " editable
*    ELSE.
*      cols-screen-input = '0'.   " read-only
*    ENDIF.
*    MODIFY ffid-cols FROM cols INDEX sy-tabix.
*  ENDLOOP.
*
*  IF gv_save = abap_true.
*    LOOP AT ffid-cols INTO cols WHERE index GT 1.
*      cols-screen-input = '0'.   " read-only
*      MODIFY ffid-cols FROM cols INDEX sy-tabix.
*    ENDLOOP.
*  ENDIF.
*
*  CLEAR gv_error.
*ENDMODULE.
**-> End of Code added by Abid Ali
*
**-> Start of Code added by Abid Ali
*
*FORM save.
**-> End of Code added by Abid Ali
*  DATA: ls_defaults TYPE bapidefaul,
*        lt_return   TYPE TABLE OF bapiret2.
*
*  DATA: lv_regex TYPE string VALUE
*        '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'.
*
** KANISHK - SET REQUEST STATUS TO PENDING ---------------------------
**  DATA: lv_ts         TYPE timestamp,
**        lv_date       TYPE d,
**        lv_time       TYPE t,
**        lv_created_at TYPE char14,
**        lv_ts_start   TYPE timestamp,
**        lv_ts_end     TYPE timestamp,
**        lv_acc_start  TYPE char14,
**        lv_acc_end    TYPE char14,
**        lv_tzone      TYPE tzone.
**
*  lv_tzone = cl_abap_context_info=>get_user_time_zone( ).
*
*  GET TIME STAMP FIELD lv_ts.                       " UTC timestamp
*  CONVERT TIME STAMP lv_ts TIME ZONE 'UTC'
*          INTO DATE lv_date TIME lv_time.           " split to date/time
*  lv_created_at = |{ lv_date }{ lv_time }|.         " 'YYYYMMDDHHMMSS'
*
*  CLEAR gv_error.
*  CLEAR gv_error_text.
*
****  LOOP AT itab_1 ASSIGNING FIELD-SYMBOL(<fs_req>).
****
****    <fs_req>-req_tzone = lv_tzone.
****
****    CALL FUNCTION 'BAPI_USER_GET_DETAIL'
****      EXPORTING
****        username = <fs_req>-req_user                " User Name
****      IMPORTING
****        defaults = ls_defaults            " Structure with User Defaults
****      TABLES
****        return   = lt_return.               " Return Structure
****
****    <fs_req>-req_ianatzone = ls_defaults-tzone_iana.
****
*****- Email ID Validation
****    IF <fs_req>-email_addr IS INITIAL.
****      gv_error = 'X'.
****      MESSAGE e010(zz_arc_firefighter) INTO gv_error_text.
****      RETURN.
****    ENDIF.
****
****    DATA: ls_sx_address TYPE sx_address.
****
****    ls_sx_address-address = <fs_req>-email_addr.
****    ls_sx_address-type = 'INT'.
****
****    CALL FUNCTION 'SX_INTERNET_ADDRESS_TO_NORMAL'
****      EXPORTING
****        address_unstruct = ls_sx_address                 " Unstrukturierte Adresse, evtl. mit Kommentar
*****       complete_address = 'X'              " Adresse ist vollständig (d.h. keine Wildcards)
****      EXCEPTIONS
****        error_address    = 1
****        OTHERS           = 2.
****    IF sy-subrc <> 0.
****      gv_error = 'X'.
****      MESSAGE e011(zz_arc_firefighter) INTO gv_error_text.
****      RETURN.
****    ENDIF.
****
*****    <fs_req>-planned_activity = gv_planned_activity.  " Comment by Abid
****    <fs_req>-planned_activity = gv_just_text.
****
****    " Check if FF_ID exists in pool
****    SELECT SINGLE ff_id INTO @DATA(lv_ff_id)
****       FROM zfire_id_pool
****      WHERE ff_id = @<fs_req>-req_ffid.
****    IF sy-subrc <> 0.
****      gv_error = 'X'.
****      MESSAGE e012(zz_arc_firefighter) WITH <fs_req>-req_ffid INTO gv_error_text.
****      RETURN.
****
****    ENDIF.
****
****    "Convert Access Start to UTC ---------------------------------------
****    DATA: lv_acc_start_tm TYPE timestamp,
****          lv_acc_end_tm   TYPE timestamp.
****
****    " --- Handle Access Start --------------------------------------
****    IF <fs_req>-access_start IS NOT INITIAL.
****      IF strlen( <fs_req>-access_start ) = 14
****         AND <fs_req>-access_start CO '0123456789'.
****        " Case 1: already YYYYMMDDhhmmss
****        lv_ts_start = <fs_req>-access_start.
****
****      ELSEIF strlen( <fs_req>-access_start ) >= 19.
****        " Case 2: TIME_IO dd.mm.yyyy hh:mm:ss
****        DATA(lv_day)   = <fs_req>-access_start+0(2).
****        DATA(lv_month) = <fs_req>-access_start+3(2).
****        DATA(lv_year)  = <fs_req>-access_start+6(4).
****        DATA(lv_hour)  = <fs_req>-access_start+11(2).
****        DATA(lv_min)   = <fs_req>-access_start+14(2).
****        DATA(lv_sec)   = <fs_req>-access_start+17(2).
****
****        lv_ts_start = |{ lv_year }{ lv_month }{ lv_day }{ lv_hour }{ lv_min }{ lv_sec }|.
****
****      ELSE.
****        gv_error = 'X'.
****        MESSAGE e014(zz_arc_firefighter) INTO gv_error_text.
****        RETURN.
****
****      ENDIF.
****
****      " Normalize to UTC CHAR14
****      CONVERT TIME STAMP lv_ts_start TIME ZONE 'UTC'
****        INTO DATE lv_date TIME lv_time.
****
****      CONVERT DATE lv_date TIME lv_time INTO TIME STAMP lv_acc_start_tm TIME ZONE lv_tzone.
****
****    ENDIF.
****
****    " --- Handle Access End ----------------------------------------
****    IF <fs_req>-access_end IS NOT INITIAL.
****      IF strlen( <fs_req>-access_end ) = 14
****         AND <fs_req>-access_end CO '0123456789'.
****        lv_ts_end = <fs_req>-access_end.
****
****      ELSEIF strlen( <fs_req>-access_end ) >= 19.
****        DATA(lv_day_e)   = <fs_req>-access_end+0(2).
****        DATA(lv_month_e) = <fs_req>-access_end+3(2).
****        DATA(lv_year_e)  = <fs_req>-access_end+6(4).
****        DATA(lv_hour_e)  = <fs_req>-access_end+11(2).
****        DATA(lv_min_e)   = <fs_req>-access_end+14(2).
****        DATA(lv_sec_e)   = <fs_req>-access_end+17(2).
****
****        lv_ts_end = |{ lv_year_e }{ lv_month_e }{ lv_day_e }{ lv_hour_e }{ lv_min_e }{ lv_sec_e }|.
****
****      ELSE.
****        gv_error = 'X'.
****        MESSAGE e015(zz_arc_firefighter) INTO gv_error_text.
****        RETURN.
****
****
****      ENDIF.
****      CONVERT TIME STAMP lv_ts_end TIME ZONE 'UTC'
****        INTO DATE lv_date TIME lv_time.
****
****      CONVERT DATE lv_date TIME lv_time INTO TIME STAMP lv_acc_end_tm TIME ZONE lv_tzone.
****    ENDIF.
****
****    " --- Validate range -------------------------------------------
****    IF <fs_req>-access_start IS NOT INITIAL
****       AND <fs_req>-access_end   IS NOT INITIAL.
****      IF lv_acc_start_tm >= lv_acc_end_tm.
****        gv_error = 'X'.
****        MESSAGE e013(zz_arc_firefighter) INTO gv_error_text.
****        RETURN.
****
****      ENDIF.
****    ENDIF.
****    "-------------------------------------------------------------------
****
*****KANISHK - NEW REQUEST ID USING GUID-------------------------------------
****
****    DATA: lv_guid TYPE sysuuid_c.
****
****    CALL FUNCTION 'GUID_CREATE'
****      IMPORTING
****        ev_guid_32 = lv_guid.
****
****    <fs_req>-req_id = lv_guid+22(10).   " use last 10 chars for CHAR10 field
****
****
*****------------------------------------------------------------------------
****
****    "--- Collision check: ensure REQ_ID does not already exist -----------------
****    DATA: lv_existing_reqid TYPE zfire_req-req_id,
****          lv_try            TYPE i VALUE 0.
****
****    WHILE lv_try < 5.
****      CLEAR lv_existing_reqid.
****
****      SELECT SINGLE req_id
****        INTO lv_existing_reqid
****        FROM zfire_req
****        WHERE req_id = <fs_req>-req_id.
****
****      IF sy-subrc <> 0.
****        "No collision -> ok
****        EXIT.
****      ENDIF.
****
****      "Collision -> generate a new one
****      lv_try = lv_try + 1.
****
****      CALL FUNCTION 'GUID_CREATE'
****        IMPORTING
****          ev_guid_32 = lv_guid
****        EXCEPTIONS
****          OTHERS     = 1.
****
****      IF sy-subrc = 0.
****        <fs_req>-req_id = lv_guid+22(10).
****      ENDIF.
****    ENDWHILE.
****    "---------------------------------------------------------------------------
****
****    <fs_req>-status = 'PENDING'.
****    <fs_req>-created_at = lv_created_at.
****
****    CLEAR:gv_planned_activity, gv_just_text.
****  ENDLOOP.
*
*
**---------------------------------------------------------------------
*
*  "-------------------------------------------------------------
*  " OPTIONAL: Debug / Verification check — place here
*  "-------------------------------------------------------------
****  LOOP AT itab_1 INTO DATA(ls_check).
****    WRITE: / 'REQ_ID generated:', ls_check-req_id.
****  ENDLOOP.
*
*  "-------------------------------------------------------------
*  " Insert records now — IDs are filled correctly
*  "-------------------------------------------------------------
*
*  IF gv_error IS INITIAL.
**    lv_acc_start = lv_acc_start_tm.
**    lv_acc_end   = lv_acc_end_tm.
*
**    IF <fs_req> IS ASSIGNED.
**      <fs_req>-access_start = lv_acc_start.
**      <fs_req>-access_end   = lv_acc_end.
**    ENDIF.
**    INSERT zfire_req FROM TABLE itab_1.
**    COMMIT WORK.
*
**    MOVE-CORRESPONDING itab_1 TO itab_status.
**    LOOP AT itab_status ASSIGNING FIELD-SYMBOL(<fs_stat>).
**      <fs_stat>-status = 'PENDING'.
**      <fs_stat>-created_at = lv_created_at.
**    ENDLOOP.
*
**--------------------------------------------------------------------
*
**    INSERT zfire_req_status FROM TABLE itab_status.
*    IF sy-subrc EQ 0.
*      MESSAGE TEXT-000 TYPE 'S' .
**            WITH zfire_req-req_user zfire_req-created_at.
*
** KANISHK - CLEAR SCREEN AFTER SAVING TO PREVENT SQL ERRORS ----------
*
*      COMMIT WORK.
*
*      " ✅ Show popup with the new Request ID
**      DATA(ls_last) = VALUE zfire_req( ).
**      READ TABLE itab_1 INTO ls_last INDEX 1.
*
*      " 🔹 Firefighter Request Logging
**    DATA(lv_details) = /ui2/cl_json=>serialize( data = ls_last ).
**
**    zcl_ff_logger=>log(
**      iv_req_id     = ls_last-req_id
**      iv_event_type = 'REQUEST_SUBMITTED'
**      iv_details    = lv_details
**    ).
*
*      DATA: lv_details_req TYPE string.
*
**      CONCATENATE
**        '{'
**        '"ACTION": "Request Submitted",'
**        '"MANDT": "'             sy-mandt                  '",'
**        '"REQUESTOR": "'          ls_last-req_user          '",'
**        '"FIREFIGHTER ID": "'             ls_last-req_ffid          '",'
**        '"JUSTIFICATION": "'     ls_last-justification     '",'
**        '"PLANNED ACTIVITY": "' ls_last-planned_activity  '",'
**        '"ACCESS START": "'      ls_last-access_start      '",'
**        '"ACCESS END": "'        ls_last-access_end        '",'
**        '"INCIDENT NUMBER": "'        ls_last-ticket_no        '",'
**        '"EMAIL ADDRESS OF REQUESTOR": "'        ls_last-email_addr        '"'
**        '}'
**      INTO lv_details_req.
*
***      zcl_ff_logger=>log(
***        iv_req_id     = ls_last-req_id
***        iv_event_type = 'REQUEST_SUBMITTED'
***        iv_details    = lv_details_req
***      ).
***
***      LOOP AT ffid-cols INTO cols WHERE index GT 1.
***        IF cols-screen-name = 'ZFIRE_REQ-STATUS'.
***          CONTINUE. " Skip STATUS field
***        ENDIF.
***
***        IF  cols-screen-input = '1'.
***          cols-screen-input = '0'.
***        ENDIF.
***        MODIFY ffid-cols FROM cols INDEX sy-tabix.
***      ENDLOOP.
***
***
***      IF sy-subrc = 0 AND ls_last-req_id IS NOT INITIAL.
****        DATA(lv_message) = |New Request with ID "{ ls_last-req_id }" submitted successfully.|.
***        DATA: lv_message TYPE string.
***
***        lv_message = TEXT-202.
***        REPLACE '&' IN lv_message WITH ls_last-req_id.
***
***        CALL FUNCTION 'POPUP_TO_INFORM'
***          EXPORTING
****           titel = 'Request Created'
***            titel = TEXT-201
***            txt1  = lv_message
***            txt2  = ''.
***
***        gv_save = abap_true.
***
***      ENDIF.
***
***
***      " Release the lock after successful save
***      PERFORM dequeue_lock.
***
***
*****KANISHK - EMAIL PROGRAM MOVED TO MULTI STAGE-----------------------------------------------------------------------------------------
***
***      CLEAR: itab_1, itab_status, gv_modified.
***
***      IF go_textedit IS BOUND.
***        CLEAR gt_just_stream.
***        go_textedit->set_text_as_stream( gt_just_stream ).
***      ENDIF.
***
***      CLEAR gv_just_text.
***
***      DESCRIBE TABLE itab_1 LINES lines.
***      ffid-lines = lines.         " -> 0 rows now
***
***      SET SCREEN '0101'.
***      LEAVE SCREEN.
***
***      SUBMIT z_arc_firefighter_email_multi AND RETURN.
***      LEAVE TO SCREEN 100.
***
****---------------------------------------------------------------------
***    ENDIF.
***  ENDIF.
***ENDFORM.
***
***
****&---------------------------------------------------------------------*
****&      Module  USER_COMMAND_0101  INPUT
****&---------------------------------------------------------------------*
****       text
****----------------------------------------------------------------------*
***MODULE user_command_0101 INPUT.
***  save_ok = ok_code.
***  CLEAR ok_code.
***  CASE save_ok .
***    WHEN 'BACK' OR 'CANCEL' OR 'EXIT' .
***      LOOP AT ffid-cols INTO cols WHERE index GT 1.
***        IF  cols-screen-input = '1'.
***          cols-screen-input = '0'.
***        ENDIF.
***        MODIFY ffid-cols FROM cols INDEX sy-tabix.
***      ENDLOOP.
***      gv_edit_mode = abap_false.
***
***      PERFORM dequeue_lock.   " release lock
***      CLEAR: itab_1, gv_just_text, gt_just_stream.
***
****      PERFORM clear_textedit.
***      IF go_textedit IS BOUND.
***        go_textedit->set_text_as_stream( gt_just_stream ).
***      ENDIF.
***
***      LEAVE TO SCREEN 0.
***
***    WHEN 'SAVE'.    " <-- Save Records
***
***      PERFORM get_justification.
***
****      gv_edit_mode = abap_false.
***
***      IF zfire_req-justification IS INITIAL OR zfire_req-access_start  IS INITIAL OR
***      zfire_req-access_end  IS INITIAL OR zfire_req-req_ffid  IS INITIAL .
***        MESSAGE TEXT-001 TYPE 'W' DISPLAY LIKE 'I'.
***      ELSE.
***        PERFORM save.
***        LOOP AT ffid-cols INTO cols WHERE index GT 1.
***          IF cols-screen-name = 'ZFIRE_REQ-STATUS'.
***            CONTINUE. " Skip STATUS field
***          ENDIF.
***
***          IF  cols-screen-input = '0'.
***            cols-screen-input = '1'.
***          ENDIF.
***          MODIFY ffid-cols FROM cols INDEX sy-tabix.
***        ENDLOOP.
***
***        IF gv_error = 'X'.
****          MESSAGE gv_error_text TYPE 'E'.
***          MESSAGE gv_error_text TYPE 'S' DISPLAY LIKE 'E'.
***          gv_edit_mode = abap_true.
***        ELSE.
***          gv_edit_mode = abap_false.
***        ENDIF.
****        LEAVE TO SCREEN 0.
***      ENDIF.
***
********-> End of Code added by Abid Ali
***
***    WHEN 'INSERT'.  " <-- Add new row
***
****KANISHK - ONLY ONE REQUEST MUST BE INSERTED AT A TIME
***
***      gv_edit_mode = abap_true.
***
***      DESCRIBE TABLE itab_1 LINES lines.
***      IF lines >= 1.
****        MESSAGE 'Only one request can be created at a time.' TYPE 'E'.
***        MESSAGE i020(zz_arc_firefighter).
***      ELSE.
***
****-----------------------------------------------------------------------
***
***        CLEAR : zfire_req.
****KANISHK - GENERATE NEW REQEST_ID AUTOMATICALLY - CONTINUED------------
***
***        zfire_req-req_user = sy-uname.
****----------------------------------------------------------------------
****-> Start of Code added by Abid Ali
***        LOOP AT ffid-cols INTO cols WHERE index GT 1.
***          IF cols-screen-name = 'ZFIRE_REQ-STATUS'.
***            CONTINUE. " Skip STATUS field
***          ENDIF.
***
***          IF  cols-screen-input = '0'.
***            cols-screen-input = '1'.
***          ENDIF.
***          MODIFY ffid-cols FROM cols INDEX sy-tabix.
***        ENDLOOP.
***
***        APPEND zfire_req TO itab_1.
***
***
***        DESCRIBE TABLE itab_1 LINES lines.
****      ffid-lines = lines.
***        ffid-lines = 1.
***        gv_modified = 'X'.
***        DATA(gv_save_flag) = 'X'.
***
***        PERFORM default_values.
***        PERFORM enqueue_lock.
***        IF it_bapiret2 IS NOT INITIAL.
***          lt_bal_t_msg = CORRESPONDING #( it_bapiret2 MAPPING msgty = type
***                                                              msgid = id
***                                                              msgno = number
***                                                              msgv1 = message_v1
***                                                               ).
****-> Log Details Anzeige
***          zz_cl_arc_bal_log_details=>log_display( it_bal_t_msg = lt_bal_t_msg ).
***        ENDIF.
***        CLEAR: gv_save_flag.
****-> End of Code added by Abid Ali
***      ENDIF.
***  ENDCASE.
***ENDMODULE.
***MODULE user_command_0104 INPUT.
***  save_ok = ok_code.
***  CLEAR ok_code.
***  CASE save_ok .
***    WHEN 'BACK' OR 'CANCEL' OR 'EXIT' .
***      PERFORM dequeue_lock.   " release lock
***      LEAVE TO SCREEN 0.
***  ENDCASE.
***ENDMODULE.
***MODULE read_table_control INPUT.
***  MODIFY itab_1 FROM zfire_req INDEX ffid-current_line.
***ENDMODULE.
***
****-> Start of Code added by Abid Ali
***
***FORM Dequeue_lock.
***
***  CALL FUNCTION 'DEQUEUE_EZFIRE_REQ'
****    EXPORTING
****      mode_zfire_req = 'S'              " Sperrmodus zur Tabelle ZFIRE_REQ
****      mandt          = SY-MANDT         " 01. Enqueue Argument
****      req_id         =                  " 02. Enqueue Argument
****      req_user       =                  " 03. Enqueue Argument
****      x_req_id       = space            " Argument 02 mit Initialwert belegen?
****      x_req_user     = space            " Argument 03 mit Initialwert belegen?
****      _scope         = '3'
****      _synchron      = space            " Synchron entsperren
****      _collect       = ' '              " Sperre zunächst nur Sammeln
***    .
***
***ENDFORM.
***
***FORM Enqueue_lock.
***  DATA: lv_subrc TYPE sy-subrc.
***  " Example: Lock one record
***  READ TABLE itab_1 INTO zfire_req INDEX ffid-current_line.
***  IF sy-subrc = 0.
***
***    CALL FUNCTION 'ENQUEUE_EZFIRE_REQ'
***      EXPORTING
***        mode_zfire_req = 'S'              " Sperrmodus zur Tabelle ZFIRE_REQ
***        mandt          = sy-mandt         " 01. Enqueue Argument
***        req_id         = zfire_req-req_id              " 02. Enqueue Argument
***        req_user       = zfire_req-req_user                   " 03. Enqueue Argument
****       x_req_id       = space            " Argument 02 mit Initialwert belegen?
****       x_req_user     = space            " Argument 03 mit Initialwert belegen?
****       _scope         = '2'
****       _wait          = space
****       _collect       = ' '              " Sperre zunächst nur Sammeln
***      EXCEPTIONS
***        foreign_lock   = 1                " Objekt ist bereits gesperrt
***        system_failure = 2                " Interner Fehler vom Enqueue-Server
***        OTHERS         = 3.
***    IF sy-subrc <> 0.
****      MESSAGE 'Record is currently locked by another user.' TYPE 'E'.
***      MESSAGE e000(zz_arc_firefighter) WITH zfire_req-req_id.
***    ENDIF.
***  ENDIF.
***ENDFORM.
****-> End of Code added by Abid Ali
***
****&---------------------------------------------------------------------*
****& Module DEFAULT_VALUES OUTPUT
****&---------------------------------------------------------------------*
****&
****&---------------------------------------------------------------------*
***FORM default_values.
***  zfire_req-req_user = sy-uname.
***  zfire_req-approver = sy-uname.
****  GET TIME STAMP FIELD DATA(lv_timestamp).
***  DATA: lv_timestamp TYPE char14.
***
***  lv_timestamp = |{ sy-datlo }{ sy-timlo }|.
***
***  zfire_req-created_at = lv_timestamp.
***
***  zfire_req-req_id = zfire_req-req_id + 1.
***  zfire_req-status = 'PENDING'.
***
***ENDFORM.
***MODULE default_values OUTPUT.
***  zfire_req-req_user = sy-uname.
***  zfire_req-approver = sy-uname.
****  GET TIME STAMP FIELD DATA(lv_timestamp).
***  DATA: lv_timestamp TYPE char14.
***
***  lv_timestamp = |{ sy-datlo }{ sy-timlo }|.
***
***  zfire_req-created_at = lv_timestamp.
***
***  zfire_req-req_id = zfire_req-req_id + 1.
****  zfire_req-status = 'PENDING'.
***ENDMODULE.
****&---------------------------------------------------------------------*
****& Module STATUS_0102 OUTPUT
****&---------------------------------------------------------------------*
****&
****&---------------------------------------------------------------------*
***MODULE status_0102 OUTPUT.
***  " 1. Filter logic (Sorting is required before DELETE ADJACENT)
***  SORT gt_req_list BY req_id req_user created_at.
***  DELETE ADJACENT DUPLICATES FROM gt_req_list COMPARING req_id req_user.
****
****  " Keep only COMPLETED or APPROVED
****  DELETE gt_req_list WHERE status NE 'COMPLETED'
****                       AND status NE 'APPROVED'.
***
***  SET PF-STATUS 'STATUS_0102'.
***  SET TITLEBAR 'TITLE_102'.
***ENDMODULE.
***
***MODULE status_0104 OUTPUT.
***  " 1. Filter logic (Sorting is required before DELETE ADJACENT)
***  SORT gt_req_list BY req_id req_user created_at.
***  DELETE ADJACENT DUPLICATES FROM gt_req_list COMPARING req_id req_user.
***
***  " Keep only COMPLETED or APPROVED
***  DELETE gt_req_list WHERE status NE 'COMPLETED'
***                       AND status NE 'APPROVED'.
***
***  SET PF-STATUS 'STATUS_0104'.
***  SET TITLEBAR 'TITLE_104'.
***ENDMODULE.
***
***FORM data_fetch.
***
***  DATA: ls_defaults TYPE bapidefaul,
***        lt_return   TYPE TABLE OF bapiret2.
***
***  DATA: lt_color TYPE lvc_t_scol,
***        ls_color TYPE lvc_s_scol.
***
***  CLEAR: gt_req_list, lt_color, ls_color.
***
***  " 1. Data Retrieval
***  SELECT  req~req_id,
***          req~req_user,
***          req~req_ffid,
***          req~target_system,
***          req~status,
***          req~ctrl_doc_ok,
***          req~justification,
***          req~access_start,
***          req~access_end,
***          req~req_tzone,
***          req~req_ianatzone,
***          req~approver,
***          req~approved_at,
***          req~created_at,
***          req~changed_at,
***          req~email_addr,
***          req~ticket_no,
***          req~planned_activity,
***          req~stage_no,
***          file~file_id,
***          file~post_doc_justification,
***          file~filename,
***          file~mimetype,
***          file~created_by,
***          file~created_on
***    INTO CORRESPONDING FIELDS OF TABLE @gt_req_list
***    FROM zfire_req AS req
***    LEFT OUTER JOIN zfile_store AS file
***      ON  req~req_id   = file~req_id
***      AND req~req_user = file~req_user
***    WHERE req~req_user = @sy-uname
***    ORDER BY created_at.
***
******  IF sy-subrc = 0.
******    " 2. Filter logic (Sorting is required before DELETE ADJACENT)
******    SORT gt_req_list BY req_id req_user.
******    DELETE ADJACENT DUPLICATES FROM gt_req_list COMPARING req_id req_user.
******
******    " Keep only COMPLETED or APPROVED
******    DELETE gt_req_list WHERE status NE 'COMPLETED'
******                         AND status NE 'APPROVED'.
******  ENDIF.
***
***  " 3. Process additional timezone fields
***  DATA: lv_timestamp TYPE timestampl,
***        lv_date      TYPE d,
***        lv_time      TYPE t,
***        lv_iana_tz   TYPE string,
***        lv_tabix     TYPE sy-tabix.
***
***  "LOOP AT gt_req_list INTO <fs_req_list>.
***  LOOP AT gt_req_list ASSIGNING FIELD-SYMBOL(<fs_req_list>).
***    lv_tabix = sy-tabix.
***
****    CLEAR lv_iana_tz.
***
***    CLEAR: ls_defaults, lt_return.
***
***    " Row Coloring
******    IF <fs_req_list>-file_id IS NOT INITIAL.
******      ls_color-color-col = 5. " Green
******      ls_color-color-int = 1. " Intensified
******      ls_color-color-inv = 0.
******    ELSEIF <fs_req_list>-ctrl_doc_ok EQ 'X' AND <fs_req_list>-file_id IS INITIAL..
******      ls_color-color-col = 6. " Red
******      ls_color-color-int = 0.
******      ls_color-color-inv = 0.
******    ENDIF.
******
******    APPEND ls_color TO lt_color.
******    <fs_req_list>-row_color = lt_color.
***
***    " ---- Process ACCESS_START ----
***    IF <fs_req_list>-access_start IS NOT INITIAL.
***      lv_timestamp = <fs_req_list>-access_start.
***
***      " Convert to UTC
***      CONVERT TIME STAMP lv_timestamp TIME ZONE 'UTC' INTO DATE lv_date TIME lv_time.
***      <fs_req_list>-access_start_utc = |{ lv_date+6(2) }.{ lv_date+4(2) }.{ lv_date(4) } { lv_time+0(2) }:{ lv_time+2(2) }:{ lv_time+4(2) } Timezone UTC|.
***
***      " Convert to User Timezone using IANA display name
***      CONVERT TIME STAMP lv_timestamp TIME ZONE <fs_req_list>-req_tzone INTO DATE lv_date TIME lv_time.
***      <fs_req_list>-access_start_tz = |{ lv_date+6(2) }.{ lv_date+4(2) }.{ lv_date(4) } { lv_time+0(2) }:{ lv_time+2(2) }:{ lv_time+4(2) } Timezone { <fs_req_list>-req_ianatzone }|.
***    ENDIF.
***
***    " ---- Process ACCESS_END ----
***    IF <fs_req_list>-access_end IS NOT INITIAL.
***      lv_timestamp = <fs_req_list>-access_end.
***
***      " Convert to UTC
***      CONVERT TIME STAMP lv_timestamp TIME ZONE 'UTC' INTO DATE lv_date TIME lv_time.
***      <fs_req_list>-access_end_utc = |{ lv_date+6(2) }.{ lv_date+4(2) }.{ lv_date(4) } { lv_time+0(2) }:{ lv_time+2(2) }:{ lv_time+4(2) } Timezone UTC|.
***
***      " Convert to User Timezone using IANA display name
***      CONVERT TIME STAMP lv_timestamp TIME ZONE <fs_req_list>-req_tzone INTO DATE lv_date TIME lv_time.
***      <fs_req_list>-access_end_tz = |{ lv_date+6(2) }.{ lv_date+4(2) }.{ lv_date(4) } { lv_time+0(2) }:{ lv_time+2(2) }:{ lv_time+4(2) } Timezone { <fs_req_list>-req_ianatzone }|.
***    ENDIF.
***
***    IF <fs_req_list>-approved_at IS NOT INITIAL.
***      lv_timestamp = <fs_req_list>-approved_at.
***      " Convert to UTC
***      CONVERT TIME STAMP lv_timestamp TIME ZONE 'UTC' INTO DATE lv_date TIME lv_time.
***      <fs_req_list>-approved_at_disp = |{ lv_date+6(2) }.{ lv_date+4(2) }.{ lv_date(4) } { lv_time+0(2) }:{ lv_time+2(2) }:{ lv_time+4(2) } Timezone UTC|.
***    ENDIF.
***
***    IF <fs_req_list>-created_at IS NOT INITIAL.
***      lv_timestamp = <fs_req_list>-created_at.
***      " Convert to UTC
***      CONVERT TIME STAMP lv_timestamp TIME ZONE 'UTC' INTO DATE lv_date TIME lv_time.
***      <fs_req_list>-created_at_disp = |{ lv_date+6(2) }.{ lv_date+4(2) }.{ lv_date(4) } { lv_time+0(2) }:{ lv_time+2(2) }:{ lv_time+4(2) } Timezone UTC|.
***    ENDIF.
***
***    IF <fs_req_list>-changed_at IS NOT INITIAL.
***      lv_timestamp = <fs_req_list>-changed_at.
***      " Convert to UTC
***      CONVERT TIME STAMP lv_timestamp TIME ZONE 'UTC' INTO DATE lv_date TIME lv_time.
***      <fs_req_list>-changed_at_disp = |{ lv_date+6(2) }.{ lv_date+4(2) }.{ lv_date(4) } { lv_time+0(2) }:{ lv_time+2(2) }:{ lv_time+4(2) } Timezone UTC|.
***    ENDIF.
***
***
***    " USE THE CAPTURED INDEX HERE INSTEAD OF SY-TABIX
***    MODIFY gt_req_list FROM <fs_req_list> INDEX lv_tabix TRANSPORTING access_start_utc
***                                                                    access_start_tz
***                                                                    access_end_utc
***                                                                    access_end_tz
***                                                                    req_tzone
***                                                                    approved_at_disp
***                                                                    created_at_disp
***                                                                    changed_at_disp
***                                                                    row_color.
***  ENDLOOP.
***ENDFORM.
***
***
****------------------------------------------------------------------------
***
****--------------------------------------------------------------------
**** Convert UTC CHAR14 timestamp -> Local readable text with TZ
****--------------------------------------------------------------------
***FORM format_timestamp USING    iv_char14   TYPE char14
***                      CHANGING cv_readable TYPE string.
***
***  DATA: lv_ts_utc     TYPE timestamp,
***        lv_date_local TYPE d,
***        lv_time_local TYPE t,
***        lv_tz_str     TYPE string.
***
***  " Convert CHAR14 (UTC) -> ABAP timestamp
***  lv_ts_utc = iv_char14.
***
***  " Convert to local system timezone (SY-ZONLO is not character-like, so we convert it)
***  CONVERT TIME STAMP lv_ts_utc
***          TIME ZONE sy-zonlo
***          INTO DATE lv_date_local
***               TIME lv_time_local.
***
***  cv_readable = |{ lv_date_local+6(2) }.{ lv_date_local+4(2) }.{ lv_date_local(4) } { lv_time_local+0(2) }:{ lv_time_local+2(2) }:{ lv_time_local+4(2) } ({ sy-zonlo })|.
***
***
***ENDFORM.
***
***
****&---------------------------------------------------------------------*
****& Module DISPLAY_ALV OUTPUT
****&---------------------------------------------------------------------*
****&
****&---------------------------------------------------------------------*
***
***MODULE display_alv OUTPUT.
***
***  IF go_cont IS INITIAL.
***    PERFORM build_alv.
***  ELSE.
***    go_grid->refresh_table_display( ).
***  ENDIF.
***
***ENDMODULE.
***
***MODULE display_alv_104 OUTPUT.
***  DATA:
***    ls_layout   TYPE lvc_s_layo,
***    lo_dyndoc   TYPE REF TO cl_dd_document,
***    lv_timezone TYPE timezone,
***    lo_splitter TYPE REF TO cl_gui_splitter_container,
***    lo_cont_top TYPE REF TO cl_gui_container,
***    lo_cont_alv TYPE REF TO cl_gui_container.
***
***  DATA: lt_color TYPE lvc_t_scol,
***        ls_color TYPE lvc_s_scol.
***
***  IF lo_alv_104 IS NOT BOUND.
***
***    " 1. Main Container
***    CREATE OBJECT lo_cust_104
***      EXPORTING
***        container_name = 'POSTDOC'.
***
***    " 2. Splitter for Header and Grid
***    CREATE OBJECT lo_splitter
***      EXPORTING
***        parent  = lo_cust_104
***        rows    = 2
***        columns = 1.
***
***    lo_splitter->set_row_height( id = 1 height = 15 ). " Header occupies 15%
***    lo_cont_top = lo_splitter->get_container( row = 1 column = 1 ).
***    lo_cont_alv = lo_splitter->get_container( row = 2 column = 1 ).
***
***    " 3. ALV Grid in bottom container
***    CREATE OBJECT lo_alv_104
***      EXPORTING
***        i_parent = lo_cont_alv.
***
***    " 4. Event Handler
***    CREATE OBJECT go_evt.
****    SET HANDLER go_evt->handle_double_click FOR lo_alv_104.
***    SET HANDLER go_evt->on_double_click FOR lo_alv_104.
***
***    PERFORM build_fieldcat.
***
***    " Optional: set layout (zebra pattern, optimize widths)
***    ls_layout-zebra      = abap_true.
***    ls_layout-cwidth_opt = abap_true.
***    ls_layout-sel_mode   = 'A'.
***    ls_layout-ctab_fname = 'ROW_COLOR'.
***
***    " 6. Static Header Construction (No TOP_OF_PAGE event needed)
***    CREATE OBJECT lo_dyndoc.
***    lo_dyndoc->add_text( text = 'Firefighter Post-Session Evidence Upload' sap_style = 'HEADING' ).
***    lo_dyndoc->new_line( ).
***    lo_dyndoc->add_text( text = |Information:| ).
***    lo_dyndoc->new_line( ).
***    lo_dyndoc->add_text( text = |1.) If row is green, then document is being uploaded| ).
***    lo_dyndoc->new_line( ).
***    lo_dyndoc->add_text( text = |2.) If row is red, then document is being approved/archived without evidence| ).
***    lo_dyndoc->new_line( ).
***    lo_dyndoc->add_text( text = |3.) Double click any row to download the evidence| ).
***    lo_dyndoc->new_line( ).
***    lo_dyndoc->new_line( ).
***    lo_dyndoc->add_text( text = |Program: { sy-repid }| ).
***    lo_dyndoc->add_gap( width = 10 ).
***    lo_dyndoc->add_text( text = |User ID: { sy-uname }| ).
***    lo_dyndoc->new_line( ).
***    WRITE sy-datum TO lv_date.
***    WRITE sy-timlo TO lv_time.
***    lv_timezone = sy-zonlo. " User's local time zone (e.g., 'CET')'
***    lo_dyndoc->add_text( text = | Timezone: { lv_timezone }| ).
***    lo_dyndoc->new_line( ).
***    lo_dyndoc->add_text( text = | Date / Time: { sy-datum DATE = USER } { sy-timlo TIME = USER }| ).
***
***    lo_dyndoc->display_document( parent = lo_cont_top ).
***
***    LOOP AT gt_req_list ASSIGNING <fs_req_list>.
***      " Row Coloring
***      IF <fs_req_list>-file_id IS NOT INITIAL.
***        ls_color-color-col = 5. " Green
***        ls_color-color-int = 1. " Intensified
***        ls_color-color-inv = 0.
***      ELSEIF <fs_req_list>-ctrl_doc_ok EQ 'X' AND <fs_req_list>-file_id IS INITIAL..
***        ls_color-color-col = 6. " Red
***        ls_color-color-int = 0.
***        ls_color-color-inv = 0.
***      ENDIF.
***
***      APPEND ls_color TO lt_color.
***      <fs_req_list>-row_color = lt_color.
***    ENDLOOP.
***
***    lo_alv_104->set_table_for_first_display(
***      EXPORTING
***        is_layout       = ls_layout
***        i_structure_name = 'TY_REQ_LIST'
***      CHANGING
***        it_outtab       = gt_req_list
***        it_fieldcatalog = gt_fcat
***    ).
***  ELSE.
***    "On later calls, just refresh with current table
***    lo_alv_104->refresh_table_display( ).
***  ENDIF.
***ENDMODULE.
***
***FORM build_alv.
***
***  CREATE OBJECT go_cont
***    EXPORTING
***      container_name = 'CUSTOM'
***    EXCEPTIONS
***      OTHERS         = 1.
***  IF sy-subrc <> 0.
***    MESSAGE 'Custom control CC_ALV not found on screen 0100' TYPE 'E'.
***    RETURN.
***  ENDIF.
***
***  CREATE OBJECT go_grid
***    EXPORTING
***      i_parent = go_cont.
***
***  PERFORM build_fieldcat.
***
***  gs_layo-cwidth_opt = abap_true.   " optimize column widths
***  gs_layo-zebra      = abap_true.
***  gs_layo-sel_mode   = 'A'.
***  gs_layo-ctab_fname = 'ROW_COLOR'.   " <-- color table field
***
***
***  go_grid->set_table_for_first_display(
***    EXPORTING
***      is_layout       = gs_layo
***    CHANGING
***      it_outtab       = gt_req_list
***      it_fieldcatalog = gt_fcat ).
***
***
***ENDFORM.
***
***FORM build_fieldcat.
***
***  CLEAR gt_fcat.
***
***  "                  FIELD                REF_TABLE     REF_FIELD                COLTEXT                              HIDE
***  PERFORM add_fcat USING 'REQ_ID'                 'ZFIRE_REQ'   'REQ_ID'                 space                                space.
***  PERFORM add_fcat USING 'REQ_USER'               'ZFIRE_REQ'   'REQ_USER'               space                                space.
***  PERFORM add_fcat USING 'REQ_FFID'               'ZFIRE_REQ'   'REQ_FFID'               space                                space.
***  PERFORM add_fcat USING 'TARGET_SYSTEM'          'ZFIRE_REQ'   'TARGET_SYSTEM'          space                                space.
***  PERFORM add_fcat USING 'STATUS'                 'ZFIRE_REQ'   'STATUS'                 space                                space.
***  PERFORM add_fcat USING 'CTRL_DOC_OK'            'ZFIRE_REQ'   'CTRL_DOC_OK'            space                                space.
***  PERFORM add_fcat USING 'JUSTIFICATION'          'ZFIRE_REQ'   'JUSTIFICATION'          space                                space.
***
***  PERFORM add_fcat USING 'ACCESS_START'           'ZFIRE_REQ'   'ACCESS_START'           space                                'X'.
***  PERFORM add_fcat USING 'ACCESS_START_UTC'       space         space                    'Access Start (UTC)'                 space.
***  PERFORM add_fcat USING 'ACCESS_START_TZ'        space         space                    'Access Start (Req User Timezone)'   space.
***
***  PERFORM add_fcat USING 'ACCESS_END'             'ZFIRE_REQ'   'ACCESS_END'             space                                'X'.
***  PERFORM add_fcat USING 'ACCESS_END_UTC'         space         space                    'Access End (UTC)'                   space.
***  PERFORM add_fcat USING 'ACCESS_END_TZ'          space         space                    'Access End (Req User Timezone)'     space.
***
***  PERFORM add_fcat USING 'REQ_TZONE'              'ZFIRE_REQ'   'REQ_TZONE'              space                                space.
***  PERFORM add_fcat USING 'APPROVER'               'ZFIRE_REQ'   'APPROVER'               space                                space.
***
***  PERFORM add_fcat USING 'APPROVED_AT'            'ZFIRE_REQ'   'APPROVED_AT'            space                                'X'.
***  PERFORM add_fcat USING 'APPROVED_AT_DISP'       space         space                    'Approved At (UTC)'                  space.
***  PERFORM add_fcat USING 'CREATED_AT'             'ZFIRE_REQ'   'CREATED_AT'             space                                'X'.
***  PERFORM add_fcat USING 'CREATED_AT_DISP'        space         space                    'Created At (UTC)'                   space.
***  PERFORM add_fcat USING 'CHANGED_AT'             'ZFIRE_REQ'   'CHANGED_AT'             space                                'X'.
***  PERFORM add_fcat USING 'CHANGED_AT_DISP'        space         space                    'Changed At (UTC)'                   space.
***
***  PERFORM add_fcat USING 'EMAIL_ADDR'             'ZFIRE_REQ'   'EMAIL_ADDR'             space                                space.
***  PERFORM add_fcat USING 'TICKET_NO'              'ZFIRE_REQ'   'TICKET_NO'              space                                space.
***  PERFORM add_fcat USING 'PLANNED_ACTIVITY'       'ZFIRE_REQ'   'PLANNED_ACTIVITY'       space                                space.
***  PERFORM add_fcat USING 'STAGE_NO'               'ZFIRE_REQ'   'STAGE_NO'               space                                space.
***
***  PERFORM add_fcat USING 'FILE_ID'                'ZFILE_STORE' 'FILE_ID'                space                                space.
***  PERFORM add_fcat USING 'POST_DOC_JUSTIFICATION' 'ZFILE_STORE' 'POST_DOC_JUSTIFICATION' space                                space.
***  PERFORM add_fcat USING 'FILENAME'               'ZFILE_STORE' 'FILENAME'               space                                space.
***  PERFORM add_fcat USING 'MIMETYPE'               'ZFILE_STORE' 'MIMETYPE'               space                                space.
***  PERFORM add_fcat USING 'CREATED_BY'             'ZFILE_STORE' 'CREATED_BY'             space                                space.
***  PERFORM add_fcat USING 'CREATED_ON'             'ZFILE_STORE' 'CREATED_ON'             space                                'X'.
***
***ENDFORM.
***
****&---------------------------------------------------------------------*
****&  FORM  add_fcat
****&---------------------------------------------------------------------*
***FORM add_fcat USING iv_field
***                    iv_reftab
***                    iv_reffld
***                    iv_text
***                    iv_hide.
***
***  CLEAR gs_fcat.
***  gs_fcat-fieldname = iv_field.
***  gs_fcat-ref_table = iv_reftab.
***  gs_fcat-ref_field = iv_reffld.
***
***  IF iv_text IS NOT INITIAL.
***    gs_fcat-coltext   = iv_text.
***    gs_fcat-scrtext_l = iv_text.
***    gs_fcat-scrtext_m = iv_text.
***    gs_fcat-scrtext_s = iv_text.
***  ENDIF.
***
***  gs_fcat-no_out = iv_hide.
***  APPEND gs_fcat TO gt_fcat.
***
***ENDFORM.
***
***
****&---------------------------------------------------------------------*
****&      Module  USER_COMMAND_0102  INPUT
****&---------------------------------------------------------------------*
****       text
****----------------------------------------------------------------------*
***MODULE user_command_0102 INPUT.
***  CASE ok_code.
***    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
***      LEAVE TO SCREEN 0.
***  ENDCASE.
***ENDMODULE.
****&---------------------------------------------------------------------*
****& Module STATUS_0103 OUTPUT
****&---------------------------------------------------------------------*
****&
****&---------------------------------------------------------------------*
***MODULE status_0103 OUTPUT.
***  SET PF-STATUS 'STATUS_0103'.
***  SET TITLEBAR 'TITLE_0103'.
***ENDMODULE.
***
****&---------------------------------------------------------------------*
****& Module LOAD_ACTIVE_SESSION OUTPUT
****&---------------------------------------------------------------------*
***MODULE load_active_session OUTPUT.
***  CLEAR: gv_req_id_103, gv_ff_id_103, gv_acc_start_103, gv_acc_end_103, gv_remaining_103.
***
***  " Step 1. Find active firefighter session for the current user
***  SELECT SINGLE ff_id, req_id
***    INTO @DATA(ls_active)
***    FROM zfire_id_activ
***    WHERE assigned_to     = @sy-uname
***      AND current_status  = 'IN_USE'.
***
***  IF sy-subrc = 0.
***    gv_ff_id_103 = ls_active-ff_id.
***    gv_req_id_103 = ls_active-req_id.
***
***    " Step 2. Fetch request details for this FF session
***    SELECT SINGLE access_start, access_end
***      INTO ( @gv_acc_start_103, @gv_acc_end_103 )
***      FROM zfire_req
***      WHERE req_id = @ls_active-req_id
***      AND req_ffid = @ls_active-ff_id.
***
***    lv_tzone = cl_abap_context_info=>get_user_time_zone( ).
***    lv_tzone_str = CONV string( lv_tzone ).
***
***    " Convert start time from stored UTC → local
***
***    IF gv_acc_start_103 IS NOT INITIAL.
***      CONVERT DATE gv_acc_start_103(8) TIME gv_acc_start_103+8(6)
***              INTO TIME STAMP lv_ts_start TIME ZONE 'UTC'.
***      CONVERT TIME STAMP lv_ts_start TIME ZONE lv_tzone
***              INTO DATE lv_date_103 TIME lv_time_103.
***      gv_acc_start_103_disp = |{ lv_date_103+6(2) }.{ lv_date_103+4(2) }.{ lv_date_103(4) } { lv_time_103(2) }:{ lv_time_103+2(2) }:{ lv_time_103+4(2) } { lv_tzone_str }|.
***    ENDIF.
***
***    IF gv_acc_end_103 IS NOT INITIAL.
***      CONVERT DATE gv_acc_end_103(8) TIME gv_acc_end_103+8(6)
***              INTO TIME STAMP lv_ts_end TIME ZONE 'UTC'.
***      CONVERT TIME STAMP lv_ts_end TIME ZONE lv_tzone
***              INTO DATE lv_date_103 TIME lv_time_103.
***      gv_acc_end_103_disp = |{ lv_date_103+6(2) }.{ lv_date_103+4(2) }.{ lv_date_103(4) } { lv_time_103(2) }:{ lv_time_103+2(2) }:{ lv_time_103+4(2) } { lv_tzone_str }|.
***    ENDIF.
***
***
***    " Step 3: Calculate remaining time correctly (UTC-safe & proper timestamp arithmetic)
***    IF gv_acc_end_103 IS NOT INITIAL.
***
***      DATA: lv_end_ts  TYPE timestamp,
***            lv_now_ts  TYPE timestamp,
***            lv_diff    TYPE decfloat34,
***            lv_days    TYPE i,
***            lv_hours   TYPE i,
***            lv_minutes TYPE i.
***
***      " Convert stored UTC CHAR14 → real timestamp value
***      CONVERT DATE gv_acc_end_103(8)
***              TIME gv_acc_end_103+8(6)
***              INTO TIME STAMP lv_end_ts TIME ZONE 'UTC'.
***
***      " Get current timestamp (already UTC)
***      GET TIME STAMP FIELD lv_now_ts.
***
***      " Compute difference (seconds)
***      lv_diff = cl_abap_tstmp=>subtract( tstmp1 = lv_end_ts tstmp2 = lv_now_ts ).
***
***      IF lv_diff > 0.
***        lv_days    = lv_diff DIV ( 24 * 60 * 60 ).
***        lv_hours   = ( lv_diff MOD ( 24 * 60 * 60 ) ) DIV 3600.
***        lv_minutes = ( lv_diff MOD 3600 ) DIV 60.
***
****        gv_remaining_103 = |{ lv_days }d { lv_hours }h { lv_minutes }m left|.
***        MESSAGE i040(zz_arc_firefighter)
***          WITH lv_days lv_hours lv_minutes
***          INTO gv_remaining_103.
***
***      ELSE.
****        gv_remaining_103 = 'ACCESS COMPLETED'.
***        MESSAGE i033(zz_arc_firefighter) INTO gv_remaining_103.
***
***      ENDIF.
***
***    ELSE.
****      gv_remaining_103 = 'No end time set'.
***      MESSAGE i034(zz_arc_firefighter) INTO gv_remaining_103.
***    ENDIF.
***  ENDIF.
***
***ENDMODULE.
***
****&---------------------------------------------------------------------*
****& Module USER_COMMAND_0103 INPUT
****&---------------------------------------------------------------------*
***MODULE user_command_0103 INPUT.
***  CASE sy-ucomm.
***    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
***      LEAVE TO SCREEN 0.
***
***    WHEN 'ENDSESS'.
***      IF gv_req_id_103 IS NOT INITIAL.
***
***       " 1️. Get current UTC time as CHAR14
***        GET TIME STAMP FIELD lv_now_ts.
***        CONVERT TIME STAMP lv_now_ts TIME ZONE 'UTC'
***                INTO DATE lv_date TIME lv_time.
***        lv_char14 = |{ lv_date }{ lv_time }|.  " YYYYMMDDhhmmss
***
***        " 2️. Update ACCESS_END for this request
***        UPDATE zfire_req
***          SET access_end = @lv_char14
***          WHERE req_id   = @gv_req_id_103
***            AND req_user = @sy-uname.
***
***        IF sy-subrc = 0.
***          COMMIT WORK.
***
***          " 🔹 Firefighter manual session termination logging
***          DATA: lv_details_endsess TYPE string.
***
***          CONCATENATE
***            '{"ACTION": "Manual Session Termination By User",'
***            ' "FF_ID": "'       gv_ff_id_103      '",'
***            '"ENDED_BY": "'      sy-uname          '",'
***            '"ENDED_AT": "'      lv_char14         '"}'
***          INTO lv_details_endsess.
***
***          zcl_ff_logger=>log(
***            iv_req_id     = gv_req_id_103
***            iv_event_type = 'SESSION_END_MANUAL'
***            iv_details    = lv_details_endsess
***          ).
***
***
***          " 3️. Trigger background program to revoke access immediately
***          SUBMIT z_arc_firefighter_background AND RETURN.
***
***          " Clear displayed fields
***          CLEAR: gv_acc_start_103, gv_acc_end_103, gv_acc_start_103_disp, gv_acc_end_103_disp, gv_remaining_103.
***
***
****          MESSAGE |Firefighter session { gv_ff_id_103 } ended successfully.| TYPE 'S'.
***          MESSAGE s030(zz_arc_firefighter)
***            WITH gv_ff_id_103.
***
***          " Refresh the screen
***          SET SCREEN 103.
***          LEAVE SCREEN.
***
***        ELSE.
****          MESSAGE 'Could not update access end for this session.' TYPE 'E'.
***          MESSAGE e032(zz_arc_firefighter).
***          RETURN.
***        ENDIF.
***
***      ELSE.
****        MESSAGE 'No active session to end.' TYPE 'I'.
***        MESSAGE i031(zz_arc_firefighter).
***        RETURN.
***
***      ENDIF.
***
***    WHEN 'REFRESH'.
***
***      SET SCREEN 103.
***      LEAVE SCREEN.
***      MESSAGE 'Refreshed' TYPE 'S'.
***
***    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
***      LEAVE TO SCREEN 0.
***
***  ENDCASE.
***ENDMODULE.
****&---------------------------------------------------------------------*
****& Form get_justification
****&---------------------------------------------------------------------*
****& text
****&---------------------------------------------------------------------*
****& -->  p1        text
****& <--  p2        text
****&---------------------------------------------------------------------*
***FORM get_justification .
***  CLEAR: gt_just_stream, gv_just_text.
***
***  IF go_textedit IS BOUND.
***    go_textedit->get_text_as_stream(
***      IMPORTING
***        text = gt_just_stream ).
***  ENDIF.
***
***  CONCATENATE LINES OF gt_just_stream INTO gv_just_text
***    SEPARATED BY cl_abap_char_utilities=>cr_lf.
***
***ENDFORM.

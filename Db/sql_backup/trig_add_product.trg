create or replace trigger SMZJ."TRIG_ADD_PRODUCT"

after insert on BUSI_PRODUCT

for each row



  ---- *************************************************************************

-- SUBSYS:     托管服务

-- PROGRAM:     TRIG_ADD_PRODUCT

-- RELATED TAB:

-- SUBPROG:

-- REFERENCE:

-- AUTHOR:

-- DESCRIPTION:  当产品新增时，触发更新授权产品中间表

-- CREATE DATE:  2016-06-21

-- VERSION:

-- EDIT HISTORY:

-- *************************************************************************

declare

    v_job_name varchar2(1000):='TRIG_ADD_PRODUCT';

    v_pt_id varchar2(32);--产品主键id

    v_msg varchar2(6000 char);

    CURSOR mgr_product_cursor IS SELECT T2. ID, T2.CP_ID  FROM BUSI_MANAGER t2 WHERE T2.AUTHORIZE_ALL = 1 and t2.CP_ID =:new.cp_id;

begin

   v_pt_id := :new.id;

FOR c IN mgr_product_cursor loop

  INSERT INTO BUSI_PRODUCT_AUTHORIZATION (ID, PRODUCT_ID, MGR_ID, CP_ID)  VALUES    (sys_guid(),v_pt_id , c.ID, c.CP_ID) ;

END loop ;

   exception

     when others then

     DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);

     DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);

     v_msg:='pt_id:' || v_pt_id ||':'||sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace();

     insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);

     return;

end TRIG_ADD_PRODUCT;
/


create or replace trigger SMZJ.trig_update_product_name
  after update on busi_product
  for each row

  ---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:     trig_update_product_name
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       liujian
-- DESCRIPTION:  当产品名称被修改时，触发修改有产品名称的表
-- CREATE DATE:  2015-10-29
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
declare
   v_job_name varchar2(1000):='trig_update_product_name';
   v_pt_id varchar2(32);--更新的列id
   v_pt_name busi_product.name%type;--更新的产品名
    v_msg varchar2(6000 char);
begin
  v_pt_id := :new.id;
   v_pt_name := :new.name;

   update busi_product_factor ptf set ptf.name = v_pt_name where ptf.id = v_pt_id; -- 更新产品要素表
   update busi_mgr_netval mn set mn.product_name = v_pt_name where mn.pt_id = v_pt_id; --更新管理人净值表
   update busi_tz_netval tn set tn.product_name = v_pt_name where tn.pt_id = v_pt_id; --更新投资人净值表
   update busi_public_netval pn set pn.product_name = v_pt_name where pn.pt_id = v_pt_id; --更新公开净值表
   update busi_pp_account pa set pa.product_name = v_pt_name where pa.product_id = v_pt_id; --更新产品银行账户表


   exception
     when others then

     DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
     DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
     v_msg:='pt_id:' || v_pt_id ||':'||sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace();

     insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
     return;
end trig_update_product_name;
/


create or replace trigger SMZJ.trig_update_company_name
  after update on busi_company
  for each row

---- *************************************************************************
-- SUBSYS:     �йܷ���
-- PROGRAM:     trig_update_company_name
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       liujian
-- DESCRIPTION:  ����˾���Ʊ��޸�ʱ�������޸��й�˾���Ƶı�
-- CREATE DATE:  2015-10-29
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
declare
   v_job_name varchar2(1000):='trig_update_company_name';
   v_cp_id varchar2(32);--���µ���id
   v_cp_name busi_company.cp_name%type;--���µĹ�˾��
    v_msg varchar2(6000 char);
begin
  v_cp_id := :new.id;
   v_cp_name := :new.cp_name;
   update busi_product_factor ptf set ptf.cp_name = v_cp_name where ptf.cp_id = v_cp_id; --���²�ƷҪ�ر�
   update busi_product pt set pt.cp_name = v_cp_name where pt.cp_id = v_cp_id;  --���²�Ʒ��
   update busi_manager mgr set mgr.cp_name = v_cp_name where mgr.cp_id = v_cp_id;  --���¹������˻���
   update busi_notice nt set nt.cp_name = v_cp_name where nt.cp_id = v_cp_id; --���¹����

   exception
     when others then

     DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
     DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
     v_msg:='cp_id:' || v_cp_id ||':'||sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace();

     insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
     return;

end trig_update_company_name;
/


create or replace procedure smzj.calcul_cp_pt_count is
---- *************************************************************************
-- SUBSYS:     �йܷ���
-- PROGRAM:      calcul_cp_pt_count
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       liujian
-- DESCRIPTION:  ������פ��˾����Ʒ���������ڹ�����ʾ
-- CREATE DATE:  2015-10-23
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
v_job_name varchar2(100) :='calcul_cp_pt_count';
v_msg   varchar2(4000);
cp_count number; --����פ��˾����
pt_count number; --����פ��Ʒ����
begin
  delete from busi_count;
  select count(1) into cp_count from busi_company where is_delete = '0';
  -- ȡ������Ʒ���ּ���Ʒĸ��Ʒ
  select count(1) into pt_count from busi_product where is_delete = '0' and (is_grade = '0' or (is_grade = '1' and IS_MASTER_CODE = '1'));
   insert into busi_count(type,count) values('1', cp_count);
   insert into busi_count(type,count) values('2', pt_count);
    v_msg :='ͬ���ɹ���   ' ||     to_char(sysdate,'yyyyMMdd');

   insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
   commit;
 exception
    when others then
      rollback;
      v_msg :='ͬ��ʧ�ܣ�ԭ��' || to_char(sysdate,'yyyyMMdd') || '     '  || sqlcode || ':' || sqlerrm  || dbms_utility.format_error_backtrace() ;
      insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
end calcul_cp_pt_count;
/


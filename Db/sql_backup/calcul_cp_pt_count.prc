create or replace procedure smzj.calcul_cp_pt_count is
---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:      calcul_cp_pt_count
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       liujian
-- DESCRIPTION:  计算入驻公司，产品数量，用于官网显示
-- CREATE DATE:  2015-10-23
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
v_job_name varchar2(100) :='calcul_cp_pt_count';
v_msg   varchar2(4000);
cp_count number; --已入驻公司数量
pt_count number; --已入驻产品数量
begin
  delete from busi_count;
  select count(1) into cp_count from busi_company where is_delete = '0';
  -- 取正常产品，分级产品母产品
  select count(1) into pt_count from busi_product where is_delete = '0' and (is_grade = '0' or (is_grade = '1' and IS_MASTER_CODE = '1'));
   insert into busi_count(type,count) values('1', cp_count);
   insert into busi_count(type,count) values('2', pt_count);
    v_msg :='同步成功！   ' ||     to_char(sysdate,'yyyyMMdd');

   insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
   commit;
 exception
    when others then
      rollback;
      v_msg :='同步失败，原因：' || to_char(sysdate,'yyyyMMdd') || '     '  || sqlcode || ':' || sqlerrm  || dbms_utility.format_error_backtrace() ;
      insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
end calcul_cp_pt_count;
/


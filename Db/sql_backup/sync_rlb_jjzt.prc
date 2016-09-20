create or replace procedure smzj.SYNC_RLB_JJZT
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      SYNC_COMPANY_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  同步基金状态信息，只同步晚于当前日期的信息
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       luoyuan
-- CREATE DATE:  2015-07-28
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
AS
    v_lastday   varchar2(8); --前一天
    v_job_name varchar2(100):= '同步基金状态信息';
    v_msg      varchar2(100);
    v_count integer;
BEGIN
  
   select count(1) into v_count from t_rlb_jjzt;
   if v_count< 1 then --初始化
     v_lastday:='20120101';
   else
     select to_char(sysdate-1,'yyyymmdd') into v_lastday from dual;
   end if;
   
    
    delete from t_rlb_jjzt t where t.rq >= v_lastday; 
    insert into t_rlb_jjzt select * from zsta.rlb_jjzt@TA_DBLINK t where t.rq >= v_lastday;
    v_msg :='同步成功';
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    commit;
EXCEPTION
    when others then
        rollback;
        v_msg :='同步失败，原因：' || sqlcode || ':' || sqlerrm;
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_RLB_JJZT;
/


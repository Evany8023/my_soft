create or replace procedure smzj.SYNC_MASTERFEEDER_INFO
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      SYNC_MASTERFEEDER_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  同步masterfeeder关系，全量同步
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       luoyuan
-- CREATE DATE:  2015-07-29
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
is
    v_job_name varchar2(100):= '同步masterfeeder关系';
    v_msg      varchar2(100);
    v_sql      varchar2(100):= 'truncate table t_fundmasterfeeder_info';
BEGIN
    execute immediate v_sql;
    insert into t_fundmasterfeeder_info( fundcode,  mfundcode,  taaccountid,  distributorcode,triggertype, parstatus) 
     select t.fundcode,t.mfundcode,t.taaccountid,t.distributorcode,t.triggertype,t.parstatus from zsta.fundmasterfeeder@TA_DBLINK t;--test
    v_msg :='同步成功';
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    commit;
EXCEPTION
    when others then
        rollback;
        v_msg :='同步失败，原因：' || sqlcode || ':' || sqlerrm;
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_MASTERFEEDER_INFO;
/


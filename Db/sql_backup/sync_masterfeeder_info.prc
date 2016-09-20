create or replace procedure smzj.SYNC_MASTERFEEDER_INFO
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      SYNC_MASTERFEEDER_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  ͬ��masterfeeder��ϵ��ȫ��ͬ��
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       luoyuan
-- CREATE DATE:  2015-07-29
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
is
    v_job_name varchar2(100):= 'ͬ��masterfeeder��ϵ';
    v_msg      varchar2(100);
    v_sql      varchar2(100):= 'truncate table t_fundmasterfeeder_info';
BEGIN
    execute immediate v_sql;
    insert into t_fundmasterfeeder_info( fundcode,  mfundcode,  taaccountid,  distributorcode,triggertype, parstatus) 
     select t.fundcode,t.mfundcode,t.taaccountid,t.distributorcode,t.triggertype,t.parstatus from zsta.fundmasterfeeder@TA_DBLINK t;--test
    v_msg :='ͬ���ɹ�';
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    commit;
EXCEPTION
    when others then
        rollback;
        v_msg :='ͬ��ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm;
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_MASTERFEEDER_INFO;
/


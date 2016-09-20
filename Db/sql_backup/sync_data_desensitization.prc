create or replace procedure smzj.SYNC_DATA_DESENSITIZATION
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      SYNC_DATA_DESENSITIZATION
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  ͬ�����ݺ���е���������
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       luoyuan
-- CREATE DATE:  2015-08-03
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
is
    v_msg varchar2(1000);
    v_job_name varchar2(100):= 'SYNC_DATA_DESENSITIZATION';
begin
  
    --1.BUSI_INVESTOR_CREDIT �ͻ����ƺͿͻ�֤�������������
    update BUSI_INVESTOR_CREDIT t 
    set t.credit_no = substr(t.credit_no,0,5) || '0000'||substr(t.credit_no,length(t.credit_no)-3,length(t.credit_no)),
        t.name = substr(t.name,0,1) || '**',
        t.update_by = 'userjob',
        t.update_date = sysdate
    where t.update_by = 'userjob' and (length(t.credit_no) >= 13 or length(t.name) >= 3); 
    
    --2.BUSI_INVESTOR_DETAIL �ͻ����ƺͿͻ�֤�������������
    update BUSI_INVESTOR_DETAIL t 
    set t.credit_no = substr(t.credit_no,0,5) || '0000'||substr(t.credit_no,length(t.credit_no)-3,length(t.credit_no)),
        t.name = substr(t.name,0,1) || '**',
        t.update_by = 'userjob',
        t.update_date = sysdate
    where t.update_by = 'userjob' and (length(t.credit_no) >= 13 or length(t.name) >= 3);  
    
    --3.��˾��Ϣ����
    update Busi_Company t 
    set t.CP_NAME = substr(t.CP_NAME,0,2) || '**',
        t.update_by = 'userjob',
        t.update_date = sysdate
    where length(t.CP_NAME) >= 3;      
exception
    when others then
        rollback;
        v_msg :='ͬ�����ݺ���е�����������ԭ��' || sqlcode || ':' || sqlerrm || to_char(sysdate,' yyyy-mm-dd hh24:mi:ss');
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
end SYNC_DATA_DESENSITIZATION;
/


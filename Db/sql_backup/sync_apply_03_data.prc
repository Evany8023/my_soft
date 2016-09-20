create or replace procedure smzj.SYNC_APPLY_03_DATA
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      SYNC_APPLY_DATA
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  ͬ��03�ļ�����ʷ����Ӧdbms_jobs-'254'
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       xiaxiaonan
-- CREATE DATE:  2016-02-17
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
is
    v_sql varchar2(100) := 'truncate table ut_t_typt_03';
    v_msg varchar2(1000  char );
    v_job_name varchar2(100):= 'ͬ������������Ϣ';
    v_applicationNo varchar2(100 char);
    v_count integer;

cursor applicationNo_cur is
select APPSHEETSERIALNO
from ut_t_typt_03;

begin
   open applicationNo_cur;
   loop
      fetch applicationNo_cur into v_applicationNo;
      if applicationNo_cur%notfound then
        exit;
       end if;

       select count(*) into v_count from ut_t_typt_03_his where APPSHEETSERIALNO = v_applicationNo;
       if v_count>0 then
         delete from ut_t_typt_03_his where APPSHEETSERIALNO = v_applicationNo;
       end if;
   end loop;
   close applicationNo_cur;
   insert into ut_t_typt_03_his select * from ut_t_typt_03;
   execute immediate v_sql;
   commit;
EXCEPTION
    when others then
        rollback;
        v_msg :='ͬ��ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm ||' '|| SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    commit;
end SYNC_APPLY_03_DATA;
/


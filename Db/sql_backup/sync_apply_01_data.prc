create or replace procedure smzj.SYNC_APPLY_01_DATA
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      SYNC_APPLY_DATA
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  同步01文件到历史表,每天0:00自动执行。对应dbms_jobs-'253'
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       xiaxiaonan
-- CREATE DATE:  2016-02-17
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
is
    v_sql varchar2(100) := 'truncate table ut_t_typt_01';
    v_msg varchar2(1000  char );
    v_job_name varchar2(100):= '同步申请数据信息';
    v_applicationNo varchar2(100 char);
    v_count integer;
    v_pre_workday  varchar2(1000  char );
    v_curr_workday varchar2(1000  char );

cursor applicationNo_cur is
select APPSHEETSERIALNO
from ut_t_typt_01;

begin
   open applicationNo_cur;
   loop
      fetch applicationNo_cur into v_applicationNo;
      if applicationNo_cur%notfound then
         --select to_char(sysdate,'YYYYmmdd') into v_curr_workday from dual;
         --select getpreworkday(v_curr_workday) into v_pre_workday from dual;
         --insert into ut_t_typt_01_his(TRANSACTIONDATE,oorgno) select v_pre_workday,distributorcode from distributor ;
        exit;
       end if;

       select count(*) into v_count from ut_t_typt_01_his where APPSHEETSERIALNO = v_applicationNo;
       if v_count>0 then
         delete from ut_t_typt_01_his where APPSHEETSERIALNO = v_applicationNo;
       end if;
   end loop;
   close applicationNo_cur;
   insert into ut_t_typt_01_his select * from ut_t_typt_01;
   execute immediate v_sql;
   commit;
EXCEPTION
    when others then
        rollback;
        v_msg :='同步失败，原因：' || sqlcode || ':' || sqlerrm ||' '|| SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    commit;
end SYNC_APPLY_01_DATA;
/


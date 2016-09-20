CREATE OR REPLACE PROCEDURE SMZJ."TGYW_UPDATE_OPEN_DATE" is

---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:      tgyw_update_open_date
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       liujian
-- DESCRIPTION:  
--                 更新临时开放日，对过期的数据更新状态为失效
-- CREATE DATE:  2015-12-02
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************

v_job_name varchar2(100) :='tgyw_update_open_date';
v_msg varchar2(6000 char);--处理结果信息
v_id varchar2(32);
v_event_date varchar2(20); --开放日事件时间
v_current_date varchar2(20);
cursor all_open_date is select e.ID, to_char(e.EVENT_DATE,'yyyyMMdd') from BUSI_EVENT e where e.IS_DELETE = '0' and e.IS_EXAMINE = '0';

begin
  
  open all_open_date;
  loop
    fetch all_open_date into v_id,v_event_date;
    if all_open_date%notfound then
      exit;
     end if;
     begin
       select to_char(sysdate,'yyyyMMdd') into v_current_date from dual;
       if v_event_date < v_current_date then
          update BUSI_EVENT e set e.IS_EXAMINE = '2' where e.ID = v_id;
       end if;
     end;
  
  end loop;
  close all_open_date;
  v_msg := '更新成功！';
   insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
   commit;
   return;
   
     exception 
        when others then
        begin
            rollback;
            DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
            DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
            v_msg:=sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace(); 
            insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
            commit;
            return;
        end ; 
end tgyw_update_open_date;
/


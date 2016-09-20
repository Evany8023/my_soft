create or replace procedure smzj.TGYW_UPDATE_MESSAGR_STATUS is
---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:      TGYW_UPDATE_MESSAGR_STATUS
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       xiaxn
-- DESCRIPTION:  改变未删除，未结束，不是按点击次数结束的消息状态。
--               已审核（超过生效日期）-->已发布（更新发布时间）；
--               不是未审核通知-->已结束。每天12:00定时执行
-- CREATE DATE:  2016-05-26
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
v_id             varchar2(100);      --通知id
v_status         varchar2(100);      --通知状态
v_effectivedate  varchar2(100);      --生效日期
v_enddate        varchar2(100);      --失效日期
v_today          varchar2(100);      --当天日期
v_job_name       varchar2(100):='TGYW_UPDATE_MESSAGR_STATUS';
v_msg            varchar2(1000);

--取未删除，未结束，并且不是按次数计算的通知
cursor data_cur is select n.id,n.status,to_char(n.effective_date,'yyyyMMdd'),to_char(n.end_date,'yyyyMMdd')
                     from busi_message_notice n where n.is_delete<>'1' and n.status<>'4' and n.notice_method<>'1';

begin
  select to_char(sysdate,'yyyyMMdd') into v_today from dual;

  open data_cur;
  loop
      fetch data_cur into v_id,v_status,v_effectivedate,v_enddate;
      if data_cur%notfound then
          exit;
      end if;

      --如果通知状态是审核通过并且超过生效日期，状态变成已发布
      if v_status='2' and  v_today>=v_effectivedate and v_today<=v_enddate then
          update busi_message_notice n set n.status='3',n.notice_date=to_date(v_today,'yyyy/MM/dd')  where  n.id=v_id;
      end if;

      --如果通知状态不是未审核，如果超过失效日期，改成已结束
      if v_status<>'0'  and v_today>v_enddate then
          update busi_message_notice n set n.status='4' where n.id=v_id;
      end if;

  end loop;
  close data_cur;

  insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,'同步成功');
  commit;

EXCEPTION
    when others then
        if data_cur%isopen then
            close data_cur;
        end if;
        rollback;

        v_msg :='同步失败，原因：' || sqlcode || ':' || sqlerrm || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;


end TGYW_UPDATE_MESSAGR_STATUS;
/


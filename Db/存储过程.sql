create or replace procedure TGYW_PRODUCT_SYN_QUAR_REPORT(
      p_compid    in  varchar2,   --公司id
      p_mgrname   in  varchar2,   --管理人名称
      p_mgrid     in  varchar2,   --管理人id
      current_report_date  in  varchar2   --当前季报日期
)
as
---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:      TGYW_PRODUCT_SYN_QUAR_REPORT
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       
-- DESCRIPTION:  
-- CREATE DATE:  2016-06-23
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
v_p_name         varchar2(100);      --产品名称
v_p_no           varchar2(100);      --产品代码
v_p_date         date;      --产品创建日期
v_p_status       varchar2(100);      --是否是本季产品(1是  0 否)
v_today          date;      --当天日期
v_p_today        varchar2(100);      --当产品成立日期
v_time_difference varchar2(100);      --产品成立日期与今天的时间差
v_job_name       varchar2(100):='TGYW_PRODUCT_SYN_QUAR_REPORT';
v_msg            varchar2(1000);      
 
--取当前公司下本季产品
cursor data_cur is (
    select p1.name ,p1.product_no,p1.CREATE_DATE,p1.IS_CURRENT_QUAR_REPORT
    from BUSI_PRODUCT p1
    where p1.IS_CURRENT_QUAR_REPORT = '1' and  p1.cp_id =p_compid
    and p1.id not in(select p.id
    from BUSI_PRODUCT p,BUSI_QUARTERLY_REPORT y
    where y.PRODUCT_NO = p.PRODUCT_NO and p.IS_CURRENT_QUAR_REPORT = '1' and y.report_period =current_report_date and p.cp_id =p_compid)
     union 
    select p1.name ,p1.product_no,p1.CREATE_DATE,p1.IS_CURRENT_QUAR_REPORT
    from BUSI_PRODUCT p1
    where p1.cp_id =p_compid
    and p1.id not in(select p.id
    from BUSI_PRODUCT p,BUSI_QUARTERLY_REPORT y
    where y.PRODUCT_NO = p.PRODUCT_NO and y.report_period =current_report_date and p.cp_id =p_compid) 
  );

begin
  select sysdate into v_today from dual;       
  open data_cur;
  loop
      fetch data_cur into v_p_name,v_p_no,v_p_date,v_p_status;
      if data_cur%notfound then
          exit;
      end if;
      -- 如果状态为1，即为本季产品
    if v_p_status = '1'  then
      insert into BUSI_QUARTERLY_REPORT(id,product_no,product_name,cp_id,mgr_id,report_period,status,is_delete,create_by,create_date)
       values(sys_guid(),v_p_no,v_p_name,p_compid,p_mgrid,current_report_date,'3','0',p_mgrname,sysdate);
    end if;
    -- 如果状态为0，且当季成立满两个月的产品需出具月报，即当季第二个月第一个自然日及之前成立的产品，且当前仍在可用期的产品
    if v_p_status = '0'  and v_p_date is not null then   
         v_time_difference :=0;    
        SELECT (trunc(v_today) -  trunc(v_p_date)) into v_time_difference from dual; 
       if v_time_difference > 60 then
         insert into BUSI_QUARTERLY_REPORT(id,product_no,product_name,cp_id,mgr_id,report_period,status,is_delete,create_by,create_date)
         values(sys_guid(),v_p_no,v_p_name,p_compid,p_mgrid,current_report_date,'3','0',p_mgrname,sysdate);
        end if;
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
        v_msg:='同步失败，原因：'||':'||sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace();
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;   
  
end TGYW_PRODUCT_SYN_QUAR_REPORT;

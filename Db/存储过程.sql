create or replace procedure TGYW_PRODUCT_SYN_QUAR_REPORT(
      p_compid    in  varchar2,   --��˾id
      p_mgrname   in  varchar2,   --����������
      p_mgrid     in  varchar2,   --������id
      current_report_date  in  varchar2   --��ǰ��������
)
as
---- *************************************************************************
-- SUBSYS:     �йܷ���
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
v_p_name         varchar2(100);      --��Ʒ����
v_p_no           varchar2(100);      --��Ʒ����
v_p_date         date;      --��Ʒ��������
v_p_status       varchar2(100);      --�Ƿ��Ǳ�����Ʒ(1��  0 ��)
v_today          date;      --��������
v_p_today        varchar2(100);      --����Ʒ��������
v_time_difference varchar2(100);      --��Ʒ��������������ʱ���
v_job_name       varchar2(100):='TGYW_PRODUCT_SYN_QUAR_REPORT';
v_msg            varchar2(1000);      
 
--ȡ��ǰ��˾�±�����Ʒ
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
      -- ���״̬Ϊ1����Ϊ������Ʒ
    if v_p_status = '1'  then
      insert into BUSI_QUARTERLY_REPORT(id,product_no,product_name,cp_id,mgr_id,report_period,status,is_delete,create_by,create_date)
       values(sys_guid(),v_p_no,v_p_name,p_compid,p_mgrid,current_report_date,'3','0',p_mgrname,sysdate);
    end if;
    -- ���״̬Ϊ0���ҵ��������������µĲ�Ʒ������±����������ڶ����µ�һ����Ȼ�ռ�֮ǰ�����Ĳ�Ʒ���ҵ�ǰ���ڿ����ڵĲ�Ʒ
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
  
  insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,'ͬ���ɹ�');
  commit;  
  
EXCEPTION
    when others then
        if data_cur%isopen then
            close data_cur;
        end if;
        rollback;        
        v_msg:='ͬ��ʧ�ܣ�ԭ��'||':'||sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace();
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;   
  
end TGYW_PRODUCT_SYN_QUAR_REPORT;

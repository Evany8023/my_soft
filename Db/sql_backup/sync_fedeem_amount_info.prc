create or replace procedure smzj.SYNC_FEDEEM_AMOUNT_INFO
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      SYNC_FEDEEM_AMOUNT_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  快速赎回功能和TA同步赎回金额
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       xiaxiaonan
-- CREATE DATE:  2015-12-2
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
is
    v_msg varchar2(1000  char );
    v_job_name varchar2(100):= 'SYNC_FEDEEM_AMOUNT_INFO';
    v_sqdbh   busi_quick_sheet.sheet_no%type;
    v_date varchar(10 char);
    v_fund_code  varchar2(20 char);
    v_company_code  varchar2(20 char);
    v_count  integer;
    v_time   varchar(10 char);

cursor data_cur  is 
select t.SHEET_NO,t.PT_NO,c.insti_code
from busi_quick_sheet t, busi_company c
where t.company_id=c.id;

    

begin 
   select to_char(sysdate,'yyyymmdd') into v_date from dual;
   select to_char(sysdate,'hh24') into v_time from dual;
  if v_time < '13' or v_time > '21' then
    return ;
  end if ;
   
    select  count(*) into v_count from zsta.C_ACK_TRANS_ZD@TA_DBLINK;
    if v_count < 1 then
        return ;
    end if;
    
    
   
    open data_cur ;
    loop
        fetch data_cur into v_sqdbh,v_fund_code,v_company_code;
        if data_cur%notfound then
          exit;
        end if;
         
        select  count(*) into v_count from zsta.C_ACK_TRANS_ZD@TA_DBLINK f 
               where f.APPSHEETSERIALNO=v_sqdbh and f.FUNDCODE=v_fund_code and f.DISTRIBUTORCODE=v_company_code and f.transactiondate=v_date;
        
        if v_count=0 then
         exit;
         end if;
 
       update busi_quick_sheet t set (t.AMOUNT,t.CONFIRM_DATE)=
              (select to_char(f.CONFIRMEDAMOUNT),to_date(f.TRANSACTIONCFMDATE,'yyyy-mm-dd,hh24:mi:ss') from zsta.C_ACK_TRANS_ZD@TA_DBLINK f
                      where f.APPSHEETSERIALNO=v_sqdbh and f.FUNDCODE=v_fund_code and f.DISTRIBUTORCODE=v_company_code and f.transactiondate=v_date
               ) 
        where t.sheet_no = v_sqdbh and t.pt_no = v_fund_code;
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
        v_msg :='同步失败，原因：' || sqlcode || ':' || sqlerrm ||' '|| SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_FEDEEM_AMOUNT_INFO;
/


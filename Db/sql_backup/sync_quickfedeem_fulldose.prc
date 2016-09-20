create or replace procedure smzj.SYNC_QUICKFEDEEM_FULLDOSE
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      SYNC_QUICKFEDEEM_FULLDOSE
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  凌晨四点快速赎回的赎回金额和确认日期和TA全量同步
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
    v_job_name varchar2(100):= 'SYNC_QUICKFEDEEM_FULLDOSE';
    v_sqdbh   busi_quick_sheet.sheet_no%type;
    v_date varchar(10 char);
    v_qrje  varchar2(20 char);
    v_qrrq  varchar2(20 char);
    v_cpdm  varchar2(20 char);


cursor data_cur  is 
select APPSHEETSERIALNO,f.CONFIRMEDAMOUNT,f.TRANSACTIONCFMDATE,f.FUNDCODE 
from zsta.C_ACK_TRANS_ZD@TA_DBLINK f;

    

begin 
   select to_char(sysdate,'yyyymmdd') into v_date from dual;  
    open data_cur ;
    loop
        fetch data_cur into v_sqdbh,v_qrje,v_qrrq,v_cpdm;
        if data_cur%notfound then
          exit;
        end if;
         
 
        update busi_quick_sheet t set t.AMOUNT=v_qrje ,t.CONFIRM_DATE=to_date(v_qrrq,'yyyy-MM-dd')
        where t.sheet_no = v_sqdbh and t.pt_no = v_cpdm;
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
        v_msg :='同步失败，原因：' ||v_date ||sqlcode || ':' || sqlerrm ||' '|| SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_QUICKFEDEEM_FULLDOSE;
/


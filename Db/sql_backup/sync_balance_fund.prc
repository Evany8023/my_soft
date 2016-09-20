create or replace procedure smzj.SYNC_BALANCE_FUND
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      SYNC_BALANCE_FUND
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  同步份额余额信息，全量同步
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       luoyuan
-- CREATE DATE:  2015-07-28
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
is
    v_sql varchar2(100) := 'truncate table BUSI_SHARE_BALANCE';
    v_msg varchar2(1000  char );
    v_job_name varchar2(100):= '同步份额余额信息';
begin  
    execute immediate v_sql;
    insert into BUSI_SHARE_BALANCE
    (
        ID,
        PT_NO,
        PT_NAME,
        --CUSTOM_NAME,
        --PHONE,       
        REGIST_ACCOUNT,
        --CREDIT_NO,
        AVAILABLE,
        BALANCE,
        --CUSTOM_ID, --客户ID
        INSTI_CODE,
        CUSTOM_NO, --客户编号
        --UNIT_NET_VAL,--单位净值
        FUND_SHARE,
        FUND_NET_VAL,
        --NET_VAL_DATE,
        BONUS_WAY,
        UNPAY_INCOME,
        TOTAL_INCOME
    )
    select
        SYNC_TASK_SEQ.nextVal,
        t.FUNDCODE,      --PT_NO
        f.FUNDNAME,
        --ba.acc_name,   --CUSTER_NAME
        t.TAACCOUNTID,   --REGIST_ACCOUNT
        --ba.credit_no,  --CREDIT_NO 
        t.AVAILABLEVOL,  
        t.FUNDVOLBALANCE,
        t.DISTRIBUTORCODE,--INSTI_CODE
        t.transactionaccountid,
        --,--CUSTOM_NO
        --,--UNIT_NET_VAL
        t.FUNDVOLBALANCE,--FUND_SHARE
        t.ASSETVAL,--FUND_NET_VAL
        --,--NET_VAL_DATE
        t.DEFDIVIDENDMETHOD,--BONUS_WAY
        t.UNFOOTINCOME,--UNPAY_INCOME
        t.ADDUPINCOME
    from zsta.bal_fund@TA_DBLINK t,zsta.fundinfo@TA_DBLINK f
    where t.fundcode = f.fundcode
      and nvl(f.managercode, '88') <> '88'
      and t.fundvolbalance > 0;
     
    
     --代销客户
 update BUSI_SHARE_BALANCE t
       set (CUSTOM_NAME, CREDIT_NO, zjlx) =
           (select bi.name, bi.zjhm,bi.zjlx
              from TA_ALL_user bi
             where t.REGIST_ACCOUNT = bi.dzjh 
               and rownum <= 1)
     where exists (select bi.dzjh    from TA_ALL_user bi
             where t.REGIST_ACCOUNT = bi.dzjh );

     
       update BUSI_SHARE_BALANCE t
       set (t.pt_name,t.PT_ID) = 
           (select p.name,p.id from Busi_Product p where t.pt_no = p.product_no)
     where exists (select p.name from Busi_Product p where t.pt_no = p.product_no) ;
     
      -- 更新公司的名称
     update BUSI_SHARE_BALANCE t set (t.insti_name,t.sourcetype)= (select p.name,p.SOURCE from TA_ALL_COMPANY p where t.insti_code = p.code)
     where  exists (select p.name from TA_ALL_COMPANY p where t.insti_code = p.code);
     
      delete BUSI_SHARE_BALANCE info where
       exists(
             select id from   busi_product p where p.is_import_sales='0' and p.is_delete='0' and info.pt_no=p.product_no
      ) and info.sourcetype='1';
      
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,'同步成功');
    commit;
EXCEPTION
    when others then
        rollback;
        v_msg :='同步失败，原因：' || sqlcode || ':' || sqlerrm ||' '|| SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    commit;
end SYNC_BALANCE_FUND;
/


create or replace procedure smzj.SYNC_BALANCE_DETAIL
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      SYNC_BALANCE_DETAIL
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  同步份额详细信息，全量同步
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
    v_sql varchar2(100) := 'truncate table BUSI_SHARE_DETAIL';
    v_msg varchar2(1000 char );
    v_job_name varchar2(100):= '同步份额详细信息';
  
begin
    execute immediate v_sql;
    insert into BUSI_SHARE_DETAIL
    (
        ID,
        PT_NO,
        CUSTOM_NAME,
        PHONE,        --客户手机号码在acct_cust中，但是这个表依靠增量表更新
        CREDIT_NO,    --证件号码
        CONFIRM_DATE,   --确认日期
        BUSINESS_TYPE,  --业务类型 
        CONFIRM_AMOUNT, --确认金额 
        CONFIRM_SHARE,  --确认份额  
        SHARE_BALANCE,  --份额余额
        REGIST_ACCOUNT,  --登记账户
        APPLY_NO,
        CONFIRM_TRANS,
        INSTI_CODE,
        CUSTOM_NO,
        TARGET_CODE,
        BUY_UNIT_NET_VAL,
        BUY_TOTAL_NET_VAL,
        AVAILABLE,
        OWN_SHARE
    )
    select
        t.taserialno,    --TA流水号
        t.FUNDCODE,      --PT_NO
        '',     --PHONE
        '',     --CUSTER_NAME 
        '',     --CREDIT_NO
        to_date(t.TRANSACTIONCFMDATE,'yyyyMMdd'), --CONFIRM_DATE
        t.BUSINESSCODE,
        t.CONFIRMEDAMOUNT,
        t.CONFIRMEDVOL,
        t.FUNDVOLBALANCE,
        t.taaccountid,
        t.APPSHEETSERIALNO,--APPLY_NO
        t.TASERIALNO,--CONFIRM_TRANS
        t.DISTRIBUTORCODE,--INSTI_CODE
        t.transactionaccountid ,--CUSTOM_NO
        t.CODEOFTARGETFUND,--TARGET_CODE
        t.NAV,--BUY_UNIT_NET_VAL
        t.BUYACCUMULATIVENAV,--BUY_TOTAL_NET_VAL
        t.AVAILABLEVOL,--AVAILABLE
        t.FUNDVOLBALANCE--OWN_SHARE
    from zsta.bal_detail@TA_DBLINK t,zsta.fundinfo@TA_DBLINK f
    where t.fundcode = f.fundcode
    and nvl(f.managercode, '88') <> '88'
    and  t.fundvolbalance > 0 ;
     
 update BUSI_SHARE_DETAIL t
       set (CUSTOM_NAME, CREDIT_NO, zjlx) =
           (select bi.name, bi.zjhm,bi.zjlx
              from TA_ALL_user bi
             where t.REGIST_ACCOUNT = bi.dzjh 
               and rownum <= 1)
     where exists (select bi.dzjh    from TA_ALL_user bi
             where t.REGIST_ACCOUNT = bi.dzjh );

 

   update BUSI_SHARE_DETAIL t
       set t.pt_name = 
           (select p.name from Busi_Product p where t.pt_no = p.product_no)
     where exists (select p.name from Busi_Product p where t.pt_no = p.product_no) ;
     
     update BUSI_SHARE_DETAIL t set (t.insti_name,t.sourcetype)= (select p.name,p.source from TA_ALL_COMPANY p where t.insti_code = p.code)
     where  exists (select p.name from TA_ALL_COMPANY p where t.insti_code = p.code);
     
         delete BUSI_SHARE_DETAIL info where
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
end SYNC_BALANCE_DETAIL;
/


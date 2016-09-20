create or replace procedure smzj.SYNC_ACK_TRANS
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      SYNC_BALANCE_DETAIL
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  同步交易流水
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       luoyuan
-- CREATE DATE:  2015-07-28
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
AS
    lastDay     varchar2(8);                       --当前日上一日
    --b_isWorkDay char;
    v_count     integer;
    v_msg       varchar2(1000);
    v_job_name  varchar2(1000) := '同步交易流水';

    
BEGIN

    select to_char(sysdate-1,'yyyyMMdd') into lastDay from dual;
    delete from busi_trading_confirm t where to_char(t.confirm_date,'yyyyMMdd') = lastDay;
    
    select count(*) into v_count from busi_trading_confirm;
    if v_count = 0 then --表中无数据，进行全量同步
        insert into busi_trading_confirm
        (
            ID,
            PT_NO,
            CUSTOM_NAME,
            PHONE,
            APPLY_AMOUNT,     --申请金额
            APPLY_SHARE,      --申请份额
            BUSINESS_TYPE,    --业务类型
            CONFIRM_AMOUNT,   --确认金额
            CONFIRM_SHARE,    --确认份额
            CONFIRM_DATE,   
            UNIT_NET_VAL,      --单位净值
            FEE,               --手续费用
            REWARD,            --业绩报酬
            --UPDATE_BY,
            --UPDATE_DATE,
            APPLY_DATE,
            APPLY_NO,          --申请单号
            CONFIRM_TRANS,     --确认流水
            INSTI_CODE,        --机构编码
            CUSTOM_NO,       --客户编号
            REGIST_ACCOUNT,     --登记账户
            BONUS_WAY,         --分红方式
            BONUS_RATE,        --红利比例
            --TRANSFER_DATE,   --过户日期
            FUND_FEE,          --资产费用
            PROXY_FEE,         --代理费用
            PRINTSCRIPT_RATE,  --手续费率
            RETURN_CODE,       --返回代码
            RETURN_MSG,        --返回信息
            ORIG_APPLY_NO      --原申请单号
            ,DETAILFLAG
        )
        select
            h.taserialno,
            h.FUNDCODE,      --PT_NO
            '',              --CUSTER_NAME
            '',              --PHONE
            h.APPLICATIONAMOUNT,  --APPLY_AMOUNT
            h.APPLICATIONVOL,     --APPLY_SHARE
            h.BUSINESSCODE,
            h.CONFIRMEDAMOUNT,
            h.CONFIRMEDVOL,
            to_date(h.TRANSACTIONCFMDATE,'yyyymmdd'), --CONFIRM_DATE
            h.NAV,
            h.CHARGE, --FEE
            h.OTHERFEE1, --REWARD
            --ba.regist_account,    --REGIST_ACCOUNT
            --'userjob',    --UPDATE_BY 
            --sysdate,     --UPDATE_DATE
            --ba.credit_no,    --CREDIT_NO 
            h.TRANSACTIONDATE, --APPLY_DATE
            h.APPSHEETSERIALNO,--APPLY_NO
            h.TASERIALNO,--CONFIRM_TRANS
            h.DISTRIBUTORCODE,--INSTI_CODE
            h.transactionaccountid ,--CUSTOM_NO
            h.TAACCOUNTID,--REGIST_ACOUNT
            h.DEFDIVIDENDMETHOD,--BONUS_WAY
            h.DIVIDENDRATIO,--BONUS_RATE
            --h.,--TRANSFER_DATE
            h.FUNDFEE,--FUND_FEE
            h.SALEFEE,--PROXY_FEE
            h.RATEFEE,--PRINTSCRIPT_RATE
            h.RETURNCODE,--RETURN_CODE
            h.summary,--RETURN_MSG
            h.ORIGINALAPPSHEETNO,
             h.detailflag
        from zsta_his.h_c_ack_trans@TA_DBLINK h,zsta.fundinfo@TA_DBLINK f 
        where h.fundcode = f.fundcode
          and nvl(f.managercode, '88') <> '88';
    else  --增量同步
        insert into busi_trading_confirm
        (
            ID,
            PT_NO,
            CUSTOM_NAME,
            PHONE,
            APPLY_AMOUNT,     --申请金额
            APPLY_SHARE,      --申请份额
            BUSINESS_TYPE,    --业务类型
            CONFIRM_AMOUNT,   --确认金额
            CONFIRM_SHARE,    --确认份额
            CONFIRM_DATE,   
            UNIT_NET_VAL,      --单位净值
            FEE,               --手续费用
            REWARD,            --业绩报酬
            --UPDATE_BY,
            --UPDATE_DATE,
            APPLY_DATE,
            APPLY_NO,          --申请单号
            CONFIRM_TRANS,     --确认流水
            INSTI_CODE,        --机构编码
            CUSTOM_NO,       --客户编号
            REGIST_ACCOUNT,     --登记账户
            BONUS_WAY,         --分红方式
            BONUS_RATE,        --红利比例
            --TRANSFER_DATE,   --过户日期
            FUND_FEE,          --资产费用
            PROXY_FEE,         --代理费用
            PRINTSCRIPT_RATE,  --手续费率
            RETURN_CODE,       --返回代码
            RETURN_MSG,        --返回信息
            ORIG_APPLY_NO      --原申请单号
            ,DETAILFLAG
        )
        select
            h.taserialno,
            h.FUNDCODE,      --PT_NO
            '',     --CUSTER_NAME
            '',               --PHONE
            h.APPLICATIONAMOUNT,  --APPLY_AMOUNT
            h.APPLICATIONVOL,     --APPLY_SHARE
            h.BUSINESSCODE,
            h.CONFIRMEDAMOUNT,
            h.CONFIRMEDVOL,
            to_date(h.TRANSACTIONCFMDATE,'yyyymmdd'), --CONFIRM_DATE
            h.NAV,
            h.CHARGE, --FEE
            h.OTHERFEE1, --REWARD
            --ba.regist_account,    --REGIST_ACCOUNT
            --'userjob',    --UPDATE_BY 
            --sysdate,     --UPDATE_DATE
            --ba.credit_no,    --CREDIT_NO 
            h.TRANSACTIONDATE, --APPLY_DATE
            h.APPSHEETSERIALNO,--APPLY_NO
            h.TASERIALNO,--CONFIRM_TRANS
            h.DISTRIBUTORCODE,--INSTI_CODE
            h.transactionaccountid ,--CUSTOM_NO
            h.TAACCOUNTID,--REGIST_ACOUNT
            h.DEFDIVIDENDMETHOD,--BONUS_WAY
            h.DIVIDENDRATIO,--BONUS_RATE
            --h.,--TRANSFER_DATE
            h.FUNDFEE,--FUND_FEE
            h.SALEFEE,--PROXY_FEE
            h.RATEFEE,--PRINTSCRIPT_RATE
            h.RETURNCODE,--RETURN_CODE
            h.summary,--RETURN_MSG
            h.ORIGINALAPPSHEETNO,
            h.detailflag
        from zsta_his.h_c_ack_trans@TA_DBLINK h,zsta.fundinfo@TA_DBLINK f 
        where h.fundcode = f.fundcode
          and nvl(f.managercode, '88') <> '88'
          and h.TRANSACTIONCFMDATE = lastDay
         ;
          
    end if;
   commit;
  
    update busi_trading_confirm t
       set (CUSTOM_NAME, CREDIT_NO, zjlx) =
           (select bi.name, bi.zjhm,bi.zjlx
              from TA_ALL_user bi
             where t.REGIST_ACCOUNT = bi.dzjh 
               and rownum <= 1)
     where exists (select bi.dzjh    from TA_ALL_user bi
             where t.REGIST_ACCOUNT = bi.dzjh );
              

    update busi_trading_confirm t
       set t.pt_name = 
           (select p.name from Busi_Product p where t.pt_no = p.product_no)
     where exists (select p.name from Busi_Product p where t.pt_no = p.product_no) ;
    
     update busi_trading_confirm t set (t.insti_name,t.sourcetype)= (select p.name,p.source from TA_ALL_COMPANY p where t.insti_code = p.code)
     where  exists (select p.name from TA_ALL_COMPANY p where t.insti_code = p.code) ;
       --删除 代销不同步的记录
       delete busi_trading_confirm info where
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
end SYNC_ACK_TRANS;
/


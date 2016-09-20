create or replace procedure smzj.SYNC_ACK_TRANS
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      SYNC_BALANCE_DETAIL
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  ͬ��������ˮ
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       luoyuan
-- CREATE DATE:  2015-07-28
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
AS
    lastDay     varchar2(8);                       --��ǰ����һ��
    --b_isWorkDay char;
    v_count     integer;
    v_msg       varchar2(1000);
    v_job_name  varchar2(1000) := 'ͬ��������ˮ';

    
BEGIN

    select to_char(sysdate-1,'yyyyMMdd') into lastDay from dual;
    delete from busi_trading_confirm t where to_char(t.confirm_date,'yyyyMMdd') = lastDay;
    
    select count(*) into v_count from busi_trading_confirm;
    if v_count = 0 then --���������ݣ�����ȫ��ͬ��
        insert into busi_trading_confirm
        (
            ID,
            PT_NO,
            CUSTOM_NAME,
            PHONE,
            APPLY_AMOUNT,     --������
            APPLY_SHARE,      --����ݶ�
            BUSINESS_TYPE,    --ҵ������
            CONFIRM_AMOUNT,   --ȷ�Ͻ��
            CONFIRM_SHARE,    --ȷ�Ϸݶ�
            CONFIRM_DATE,   
            UNIT_NET_VAL,      --��λ��ֵ
            FEE,               --��������
            REWARD,            --ҵ������
            --UPDATE_BY,
            --UPDATE_DATE,
            APPLY_DATE,
            APPLY_NO,          --���뵥��
            CONFIRM_TRANS,     --ȷ����ˮ
            INSTI_CODE,        --��������
            CUSTOM_NO,       --�ͻ����
            REGIST_ACCOUNT,     --�Ǽ��˻�
            BONUS_WAY,         --�ֺ췽ʽ
            BONUS_RATE,        --��������
            --TRANSFER_DATE,   --��������
            FUND_FEE,          --�ʲ�����
            PROXY_FEE,         --�������
            PRINTSCRIPT_RATE,  --��������
            RETURN_CODE,       --���ش���
            RETURN_MSG,        --������Ϣ
            ORIG_APPLY_NO      --ԭ���뵥��
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
    else  --����ͬ��
        insert into busi_trading_confirm
        (
            ID,
            PT_NO,
            CUSTOM_NAME,
            PHONE,
            APPLY_AMOUNT,     --������
            APPLY_SHARE,      --����ݶ�
            BUSINESS_TYPE,    --ҵ������
            CONFIRM_AMOUNT,   --ȷ�Ͻ��
            CONFIRM_SHARE,    --ȷ�Ϸݶ�
            CONFIRM_DATE,   
            UNIT_NET_VAL,      --��λ��ֵ
            FEE,               --��������
            REWARD,            --ҵ������
            --UPDATE_BY,
            --UPDATE_DATE,
            APPLY_DATE,
            APPLY_NO,          --���뵥��
            CONFIRM_TRANS,     --ȷ����ˮ
            INSTI_CODE,        --��������
            CUSTOM_NO,       --�ͻ����
            REGIST_ACCOUNT,     --�Ǽ��˻�
            BONUS_WAY,         --�ֺ췽ʽ
            BONUS_RATE,        --��������
            --TRANSFER_DATE,   --��������
            FUND_FEE,          --�ʲ�����
            PROXY_FEE,         --�������
            PRINTSCRIPT_RATE,  --��������
            RETURN_CODE,       --���ش���
            RETURN_MSG,        --������Ϣ
            ORIG_APPLY_NO      --ԭ���뵥��
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
       --ɾ�� ������ͬ���ļ�¼
       delete busi_trading_confirm info where
        exists(
               select id from   busi_product p where p.is_import_sales='0' and p.is_delete='0' and info.pt_no=p.product_no
        ) and info.sourcetype='1';
        
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,'ͬ���ɹ�');
    commit;
EXCEPTION
when others then
    rollback;
    v_msg :='ͬ��ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm ||' '|| SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    commit;
end SYNC_ACK_TRANS;
/


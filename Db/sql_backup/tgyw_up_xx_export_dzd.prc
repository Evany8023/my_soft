create or replace procedure smzj.tgyw_up_xx_export_dzd

(
    v_companyId     in   varchar2,
    v_source         in  varchar2,
    v_ptNo         in  varchar2,
    v_registAccount  in  varchar2,
    v_endDate       in    varchar2,
    po_refcur         out  sys_refcursor  -- 返回记录集
)

-- *************************************************************************
-- SYSTEM:       私募系统
-- SUBSYS:       私募之家
-- PROGRAM:      up_xx_export_dzd
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  导出电子对账单的份额余额
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       pangzq
-- CREATE DATE:  20151021
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

AS
    po_returnmsg        VARCHAR2(100 char);        -- 错误信息
    vc_sql         varchar2(2014);
    ve_exception EXCEPTION;
    vn_cnt integer;
    v_fund_code VARCHAR2(12);
    v_registaccount_value VARCHAR2(20);
    v_insti_code  VARCHAR2(20);
    v_last_kf_rq  VARCHAR2(20);
    v_last_rq  VARCHAR2(20);
    v_feye  VARCHAR2(20);
cursor data_cur  is select  f.fundcode,f.registaccount,f.insti_code from busi_user_share_tmp f;
BEGIN

    -- 参数控制
    if v_companyId is null  then
        po_returnmsg  := '需要指定公司';
        raise ve_exception;
    end if;

    -- 临时表是否存在
    vc_sql := 'begin select count(0) into :out from user_tables where TABLE_NAME = upper(''busi_user_share_tmp''); end;';
    execute immediate vc_sql using out vn_cnt;
    if vn_cnt > 0 then
        execute immediate 'truncate table busi_user_share_tmp'; -- 删除数据\

     else
        vc_sql := 'create global temporary table busi_user_share_tmp
                   (
                      cpid VARCHAR2(32) not null,
                      fundcode VARCHAR2(12),
                      fundname VARCHAR2(100 char),
                      feye VARCHAR2(30),
                      dwzj VARCHAR2(10),
                      jzrq VARCHAR2(8),
                      sz VARCHAR2(20),
                      source VARCHAR2(50),
                      registAccount   VARCHAR2(20),
                      insti_code VARCHAR2(20)
                   ) on commit preserve rows;';
           Execute Immediate vc_sql;


    end if;
 vc_sql:='insert into busi_user_share_tmp(cpid,fundcode,fundname,registaccount,insti_code,source)
          select bc.id,pt.product_no,pt.name,ba.regist_account,ba.insti_code,  CASE ba.INSTI_CODE WHEN bc.INSTI_CODE THEN ''直销'' ELSE ba.insti_name END AS taComName
          from BUSI_SHARE_BALANCE ba inner join BUSI_PRODUCT pt on ba.PT_NO = pt.PRODUCT_NO join BUSI_COMPANY bc ON pt.CP_ID=bc.ID  where pt.CP_ID='''||v_companyId || '''';
    if trim(v_registAccount) is not null then
     vc_sql:=vc_sql || ' and ba.regist_account =''' ||v_registAccount|| '''' ;
    end if;

   if  trim(v_ptNo) is not null then
      vc_sql:=vc_sql || ' AND ba.PT_NO =''' ||v_ptNo || '''' ;
   end if;

   if v_source ='directSale' then
      vc_sql:=vc_sql || '  AND ba.insti_code = bc.INSTI_CODE' ;
   end if;
   if v_source ='agentSale' then
      vc_sql:=vc_sql || '  AND ba.insti_code <> bc.INSTI_CODE' ;
   end if;
   if   trim(v_source) is not null and  v_source <>'agentSale' and  v_source <> 'directSale' then
      vc_sql:=vc_sql || '  AND ba.insti_code <> bc.INSTI_CODE;' ;
   end if;

 execute immediate vc_sql;

 open    data_cur;
 loop
   fetch data_cur into v_fund_code ,v_registaccount_value,v_insti_code;
    if data_cur%notfound then
      exit;
    end if;
    select MAX(t.fund_tradedate) into v_last_kf_rq from busi_all_mgr_fund_value t where t.fund_code=v_fund_code and t.fund_tradedate<=to_char(sysdate,'yyyymmdd');
    if v_last_kf_rq <v_endDate then
       v_last_rq:=v_last_kf_rq;
    else
       v_last_rq:=v_endDate;
    end if;
    v_feye:=null;
     vc_sql:= 'begin select sum(decode(t.business_type, ''122'', t.CONFIRM_SHARE,''127'', t.CONFIRM_SHARE,
                                  ''130'', t.CONFIRM_SHARE,
                                  ''134'', t.CONFIRM_SHARE,
                                  ''137'', t.CONFIRM_SHARE,
                                  ''139'', t.CONFIRM_SHARE,
                                  ''143'', t.CONFIRM_SHARE,
                                  ''144'', t.CONFIRM_SHARE,
                                  ''122'', t.CONFIRM_SHARE,
                                  ''124'', -t.CONFIRM_SHARE,
                                  ''128'', -t.CONFIRM_SHARE,
                                  ''135'', -t.CONFIRM_SHARE,
                                  ''138'', -t.CONFIRM_SHARE,
                                  ''142'', -t.CONFIRM_SHARE,
                                  ''145'', -t.CONFIRM_SHARE, 0))  into :v_feye
            from Busi_Trading_Confirm t
            where  t.return_code = ''0000''  and nvl(t.detailflag, ''0'') = ''0''  ';

    if trim(v_registaccount_value) is not null then
       vc_sql:=vc_sql || ' and  t.regist_account =''' ||v_registaccount_value || '''';
    end if;

   if trim(v_fund_code) is not null then
      vc_sql:=vc_sql || ' AND t.PT_NO =''' ||v_fund_code || '''';
   end if;
   if  trim(v_insti_code) is not null  then
      vc_sql:=vc_sql || '  AND t.insti_code =''' ||v_insti_code|| '''';
   end if;

   if  trim(v_last_rq)  is not null then
      vc_sql:=vc_sql || ' and  to_char(t.CONFIRM_DATE,''yyyymmdd'')  <=''' ||v_endDate || '''' ;
   end if;
    vc_sql:=vc_sql|| ' group by t.pt_no, t.regist_account, t.insti_code; exception   when no_data_found then null; end ;'  ;


   execute immediate vc_sql using out v_feye;



  update busi_user_share_tmp t set t.feye=v_feye  where  t.fundcode=v_fund_code  and t.registaccount=v_registaccount_value and t.insti_code=v_insti_code;

   update busi_user_share_tmp t set (t.dwzj,t.jzrq)=
  (
    select nav,rq from (  select row_number() over(partition by a.fundcode order by a.tradeday desc) as rn ,a.nav,a.tradeday as rq  from BUSI_ALL_FUND_VAUES a where a.FUNDCODE=v_fund_code and a.tradeday <=v_last_rq) m where m.rn=1
  )
   where exists(
     select bn.nav from BUSI_ALL_FUND_VAUES bn where bn.fundcode=v_fund_code and bn.tradeday<=v_last_rq
   ) and t.fundcode=v_fund_code ;

 end loop   ;
 close data_cur;
 COMMIT;

open  po_refcur for 'select * from busi_user_share_tmp';

EXCEPTION
    WHEN ve_exception then
        rollback;
         po_returnmsg:='失败'||sqlerrm || sqlcode;
         insert into T_FUND_JOB_RUNNING_LOG(JOB_NAME,JOB_RUNNING_LOG) values(po_returnmsg|| v_companyId , v_ptNo || '  ' || v_registAccount || '  '|| v_endDate ||vc_sql || dbms_utility.format_error_backtrace());
        vc_sql := 'select * from busi_user_share_tmp where 1 = 2';
        COMMIT;
        open po_refcur for vc_sql;
        RETURN;
    WHEN OTHERS THEN
        ROLLBACK;
         po_returnmsg:='失败'||sqlerrm || sqlcode;
         insert into T_FUND_JOB_RUNNING_LOG(JOB_NAME,JOB_RUNNING_LOG) values(po_returnmsg, v_ptNo || '  ' || v_registAccount || '  '|| v_endDate || vc_sql|| dbms_utility.format_error_backtrace());
        COMMIT;

        vc_sql := 'select * from busi_user_share_tmp where 1 = 2';
        open po_refcur for vc_sql;
        return;
end tgyw_up_xx_export_dzd;
/


CREATE OR REPLACE VIEW SMZJ.T_FUND_TRADE AS
SELECT
--客户类型
t.id as id,
t.credit_id  as CUST_ID,
decode(t.status,1,1,0) as ISVALID,
to_char(t.sheet_create_time,'yyyymmdd')  as TRADE_SQRQ,
t.business_type as TRADE_TYPE_CODE,

 (case  when t.business_type = '022' then '申购'
    when t.business_type ='020'  then ' 认购'
    when t.business_type ='024'  then '赎回'
    when t.business_type='029' then '分红方式'
end ) as TRADE_TYPE,
t.apply_amount as TRADE_SQJE,
t.sheet_no as TRADE_SQDH,
c.insti_code as jgbm,
t.apply_share as TRADE_SQFE,
t.pt_id as FUND_ID,
t.BONUS_WAY  as TRADE_FHFS,
t.is_delete AS is_delete

FROM  busi_sheet t,busi_company c where c.id=t.company_id;


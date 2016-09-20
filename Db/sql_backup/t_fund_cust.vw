CREATE OR REPLACE VIEW SMZJ.T_FUND_CUST AS
SELECT
--客户类型
t.id ,
t.custom_no  as khbh,
t.credit_type as IDTYPECODE,
t.credit_no as IDCARD,
t.name  as USER_NAME,
t.is_delete ,
t.regist_account as DJZH

FROM  BUSI_INVESTOR_CREDIT t;


CREATE OR REPLACE VIEW SMZJ.T_FUND_ACCOUNT AS
SELECT
--客户类型
t.is_delete  as is_delete,
t.is_back_account as IS_FHSH_ACCOUNT,
t.credit_id as CUST_ID,
t.product_id as FUND_ID,
c.insti_code  AS ACC_XSSDM,
t.user_name as ACC_KHMC,
t.user_name as ACC_YHHM,
replace(t.account_no,' ','')  as ACC_YHZH,
t.open_bank_name as ACC_KHHMC,
t.bank_no as ACC_YHBH_CODE,
t.province_name as ACC_KHHSZSF,
t.city_name as ACC_KHHSZS,
t.bank_name as ACC_YHBH

FROM  busi_bind_bank_card  t, BUSI_COMPANY C
where c.id =t.company_id;


create or replace view smzj.v_raise_bank as
select d.product_id proId,
       t.product_no proNo,
       t.cp_name proName,
       账户 bankAcc,
       账户名称 accountName,
       开户行 openBank,
       账户余额 acctBal,
       可用余额 availableBal,
       币种 curType,
       to_char(更新时间,'yyyy-mm-dd hh24:mi:ss') updateTime,
       处理说明 procFlag,
       d.company_id companyId
  from EA_FT2.VW_BI_BANK_BAL_ZS@XY_DBLINK k,busi_bind_bank_card d, busi_product t
 where k.账户=d.account_no
       and t.id=d.product_id;


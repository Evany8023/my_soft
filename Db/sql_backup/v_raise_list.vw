create or replace view smzj.v_raise_list as
select d.product_id PROID,
       交易日期 BUSIDATE,
       发生时间 BUSITIME,
       收付方向 DIRECTFLAG,
       t.product_no PRONO,
       t.cp_name PRONAME,
       交易金额 AVAILABLEBAL,
       账户余额 ACCTBAL,
       对方账户 BANKACC,
       对方账户名称 ACCNAME,
       本方账户 OWERBANKACC,
       本方账户名称 OWERACCNAME,
       d.COMPANY_ID companyId,
       '' mark,
       摘要 NOTE
  from EA_FT2.VW_BI_BANK_JOUR_ZS@XY_DBLINK K,busi_bind_bank_card d, busi_product t
  WHERE K.本方账户=d.account_no
        and d.product_id=t.id;


create or replace view smzj.v_raise_list as
select d.product_id PROID,
       �������� BUSIDATE,
       ����ʱ�� BUSITIME,
       �ո����� DIRECTFLAG,
       t.product_no PRONO,
       t.cp_name PRONAME,
       ���׽�� AVAILABLEBAL,
       �˻���� ACCTBAL,
       �Է��˻� BANKACC,
       �Է��˻����� ACCNAME,
       �����˻� OWERBANKACC,
       �����˻����� OWERACCNAME,
       d.COMPANY_ID companyId,
       '' mark,
       ժҪ NOTE
  from EA_FT2.VW_BI_BANK_JOUR_ZS@XY_DBLINK K,busi_bind_bank_card d, busi_product t
  WHERE K.�����˻�=d.account_no
        and d.product_id=t.id;


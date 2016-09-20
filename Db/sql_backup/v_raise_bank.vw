create or replace view smzj.v_raise_bank as
select d.product_id proId,
       t.product_no proNo,
       t.cp_name proName,
       �˻� bankAcc,
       �˻����� accountName,
       ������ openBank,
       �˻���� acctBal,
       ������� availableBal,
       ���� curType,
       to_char(����ʱ��,'yyyy-mm-dd hh24:mi:ss') updateTime,
       ����˵�� procFlag,
       d.company_id companyId
  from EA_FT2.VW_BI_BANK_BAL_ZS@XY_DBLINK k,busi_bind_bank_card d, busi_product t
 where k.�˻�=d.account_no
       and t.id=d.product_id;


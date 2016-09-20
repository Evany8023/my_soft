CREATE OR REPLACE VIEW SMZJ.T_FUND_INFO AS
SELECT
--�ͻ�����
t.name  as FUND_NAME,
t.product_no as FUND_CODE,
t.id as id,
t.public_net_period as FUND_JZTBZQ,
t.mgr_net_period as FUND_GLRJZTBZQ,
t.invest_net_period as FUND_TZZJZTBZQ,
to_char(t.publish_date,'yyyymmdd') as FUND_CLRQ,
t.TRUSTEESHIP_INSTI as FUND_TGR,
 (case  when t.product_type = '1' then '֤ȯͶ�ʹ�����'
    when t.product_type ='2'  then '��ȨͶ�ʹ�����'
    when t.product_type ='3'  then '��ҵͶ�ʹ�����'
    when t.product_type='4' then '����Ͷ�ʹ�����'
    else '����Ͷ�ʹ�����'
end ) as FUND_TYPE_VALUE,
t.product_type as FUND_TYPE,


p.product_no as FUND_MDM
FROM  Busi_Product t ,Busi_Product p
where t.parent_id =p.id(+);


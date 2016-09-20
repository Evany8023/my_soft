CREATE OR REPLACE VIEW SMZJ.T_FUND_INFO AS
SELECT
--客户类型
t.name  as FUND_NAME,
t.product_no as FUND_CODE,
t.id as id,
t.public_net_period as FUND_JZTBZQ,
t.mgr_net_period as FUND_GLRJZTBZQ,
t.invest_net_period as FUND_TZZJZTBZQ,
to_char(t.publish_date,'yyyymmdd') as FUND_CLRQ,
t.TRUSTEESHIP_INSTI as FUND_TGR,
 (case  when t.product_type = '1' then '证券投资管理人'
    when t.product_type ='2'  then '股权投资管理人'
    when t.product_type ='3'  then '创业投资管理人'
    when t.product_type='4' then '其他投资管理人'
    else '其他投资管理人'
end ) as FUND_TYPE_VALUE,
t.product_type as FUND_TYPE,


p.product_no as FUND_MDM
FROM  Busi_Product t ,Busi_Product p
where t.parent_id =p.id(+);


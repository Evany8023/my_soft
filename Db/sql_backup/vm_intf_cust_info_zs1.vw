CREATE OR REPLACE VIEW SMZJ.VM_INTF_CUST_INFO_ZS1 AS
SELECT
--客户类型
trim(tfi.product_no) || trim(tfc.custom_no) as trade_acc,
tfc.regist_account as ACC_DJZH,
     TFA.User_Name as ACC_KHMC, --客户名称
       TFA.BANK_name as   ACC_YHBH, --银行编号
       TFA.Account_No as  ACC_YHZH, --银行账号
       TFA.User_Name as  ACC_YHHM, --银行户名
       TFA.OPEN_BANK_NAME as    ACC_KHHMC, --开户银行
       TFA.Link_Bank_No as   ACC_LHH, --联行号
       TFA.Province_Name as  ACC_KHHSZSF, --开户行省份
       TFA.City_Name as  ACC_KHHSZS, --开户行城市
       DECODE(SUBSTR(TFC.CREDIT_TYPE,1,1),0,1,1,0,SUBSTR(TFC.CREDIT_TYPE,1,1)) CUST_TYPE

from busi_bind_bank_card tfa,
busi_investor_credit tfc,
busi_product tfi

where tfa.product_id =tfi.id(+)
and tfa.credit_id =tfc.id(+)
and tfa.is_back_account=1 and tfa.is_delete=0;


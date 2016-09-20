CREATE OR REPLACE VIEW SMZJ.VM_INTF_CUST_INFO_ZS1 AS
SELECT
--�ͻ�����
trim(tfi.product_no) || trim(tfc.custom_no) as trade_acc,
tfc.regist_account as ACC_DJZH,
     TFA.User_Name as ACC_KHMC, --�ͻ�����
       TFA.BANK_name as   ACC_YHBH, --���б��
       TFA.Account_No as  ACC_YHZH, --�����˺�
       TFA.User_Name as  ACC_YHHM, --���л���
       TFA.OPEN_BANK_NAME as    ACC_KHHMC, --��������
       TFA.Link_Bank_No as   ACC_LHH, --���к�
       TFA.Province_Name as  ACC_KHHSZSF, --������ʡ��
       TFA.City_Name as  ACC_KHHSZS, --�����г���
       DECODE(SUBSTR(TFC.CREDIT_TYPE,1,1),0,1,1,0,SUBSTR(TFC.CREDIT_TYPE,1,1)) CUST_TYPE

from busi_bind_bank_card tfa,
busi_investor_credit tfc,
busi_product tfi

where tfa.product_id =tfi.id(+)
and tfa.credit_id =tfc.id(+)
and tfa.is_back_account=1 and tfa.is_delete=0;


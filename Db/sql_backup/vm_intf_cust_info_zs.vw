CREATE OR REPLACE VIEW SMZJ.VM_INTF_CUST_INFO_ZS AS
SELECT
trim(bc.insti_code)||trim(tfi.product_no) || trim(tfc.custom_no) as trade_acc,
tfc.regist_account as ACC_DJZH,
       (case when asciistr(TFA.user_name) like  '%\%' then replace(TFA.User_Name,' ','')
                          else TFA.User_Name  end)  as ACC_KHMC, --�ͻ�����
       TFA.BANK_name as   ACC_YHBH, --���б��
       replace(TFA.Account_No,' ','') as  ACC_YHZH, --�����˺�
       (case when asciistr(TFA.user_name) like  '%\%' then replace(TFA.User_Name,' ','')
                          else TFA.User_Name  end)
        as  ACC_YHHM, --���л���
       TFA.OPEN_BANK_NAME as    ACC_KHHMC, --��������
       TFA.Link_Bank_No as   ACC_LHH, --���к�
       TFA.Province_Name as  ACC_KHHSZSF, --������ʡ��
       TFA.City_Name as  ACC_KHHSZS, --�����г���
       DECODE(SUBSTR(TFC.CREDIT_TYPE,1,1),0,1,1,0,SUBSTR(TFC.CREDIT_TYPE,1,1)) CUST_TYPE,
       tfa.is_back_account,
       tfa.is_delete,
       tfc.name as tzzmc,
       bc.insti_code as comcode
from  busi_investor_credit tfc  inner join busi_credit_company bcc on bcc.CREDIT_ID=tfc.id join busi_company bc on bcc.company_id=bc.id
 left join busi_bind_bank_card tfa  on tfc.id=tfa.credit_id and tfa.company_id=bc.id
left join busi_product tfi on tfa.product_id=tfi.id and tfi.cp_id=bc.id;


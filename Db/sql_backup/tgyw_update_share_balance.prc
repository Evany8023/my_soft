create or replace procedure smzj.TGYW_UPDATE_SHARE_BALANCE
(
  p_sheet_id     in   varchar2,      
  p_type         in   varchar2,  --A ������ӣ� C����ȡ��
  msg         out  varchar2  
)

-- *************************************************************************
-- SYSTEM:       ˽ļϵͳ
-- SUBSYS:       ˽ļ֮��
-- PROGRAM:      TGYW_UPDATE_SHARE_BALANCE
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  ȷ�����������ֻ�����һ���
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       pangzq
-- CREATE DATE:  20151021
-- VERSION:
-- EDIT HISTORY:
--  select t.AVAILABLEVOL,  t.FUNDVOLBALANCE,t.FUNDVOLBALANCE--FUND_SHARE 
--          into  v_available,v_balance,v_fund_share
--          from zsta_tgpt.bal_fund@TA_DBLINK t,zsta_tgpt.fundinfo@TA_DBLINK f
--          where t.fundcode = f.fundcode
--           and nvl(f.managercode, '88') <> '88'
--           and t.distributorcode in (select t.distributorcode from zsta_tgpt.distributor@TA_DBLINK t where lower(t.SYWJ_KZM) <> '.txt') 
--           and  t.TAACCOUNTID=v_regist_account and t.FUNDCODE=v_product_no and t.DISTRIBUTORCODE=v_insti_code;
     
-- *************************************************************************

is 

v_job_name varchar2(100) :='TGYW_UPDATE_SHARE_BALANCE';
v_msg varchar2(1000); --������Ϣ
v_sheet_id varchar2(32);
v_apply_share varchar2(32); 
v_apply_amount varchar2(32); 
v_business_type varchar2(32); 
v_sheet_create_time timestamp; 
v_product_no varchar2(32); 
v_product_id varchar2(32); 
v_name varchar2(200); 
v_cp_name varchar2(200); 
v_insti_code varchar2(200); 
v_credit_type varchar2(200); 
v_credit_no varchar2(200); 
v_regist_account varchar2(200); 
v_custom_no varchar2(200); 
v_cust_name varchar2(200); 
v_sheet_no varchar2(200);
v_count integer;
v_available varchar2(200);
v_balance varchar2(200);
v_fund_share varchar2(200);
v_total_share varchar2(200);
v_confirm_status varchar2(32);       --����ȷ��״̬�ж�
v_insert_status varchar2(2);
v_banlance_id varchar2(20);
begin
 
 select t.id ,t.apply_share,t.apply_amount,t.business_type,
 t.sheet_create_time,p.product_no,p.name,c.cp_name,c.insti_code,
 ic.credit_type,ic.credit_no,ic.regist_account,ic.custom_no ,p.id,ic.name,t.sheet_no,t.confirm_status     

 into v_sheet_id,v_apply_share,v_apply_amount,v_business_type,
  v_sheet_create_time,v_product_no,v_name,v_cp_name,v_insti_code,
  v_credit_type,v_credit_no,v_regist_account,v_custom_no,v_product_id,v_cust_name,v_sheet_no,v_confirm_status
  
  from busi_sheet t inner join busi_product p on t.pt_id=p.id inner join busi_company c on t.company_id =c.id inner join busi_investor_credit ic on ic.id =t.credit_id 
 where ic.is_delete='0' and c.is_delete='0' and p.is_delete='0' and t.is_delete='0' and t.id = p_sheet_id ;
 
 --�����p_type����ӣ�����ȷ��״̬����ȷ�ϣ������ٴ�ȷ��
 if v_confirm_status = '1' and p_type = 'A' then
   msg:='��������ȷ�ϣ������ٴ�ȷ��';
   return;
 end if;
 
  --�����p_type��ȡ��������ȷ��״̬��δȷ�ϣ������ٴ�ȡ��ȷ��
 if v_confirm_status = '0' and p_type = 'C' then
   msg:='������δȷ�ϣ�����ȡ��ȷ��';
   return;
 end if;
 
 
  --����ÿͻ�û�еǼ��˺�
  if   v_regist_account is null then      
    msg:='�˶����ͻ�û�еǼ��˺�:'|| v_credit_no || '���֣�'||v_cust_name;
    return ;
  end if;
 
  --����ò�Ʒ���ǻ��һ���
  select count(1) into  v_count from  busi_product_add t where t.product_id=v_product_id and t.fund_type='1';   
  if v_count < 1 then
    msg:='���ǻ��һ���û�а취����ݶ�';
    return ;
  end if ;
  
  --�������뵥�ţ���Ʒ���룬�����ۻ������ж�busi_trading_confirm���Ƿ��Ѿ�ȷ��
    select count(1) into  v_count  from busi_trading_confirm c where c.apply_no=v_sheet_no and c.pt_no=v_product_no and c.insti_code=v_insti_code;
    if v_count > 0 then
      msg:='�����Ѿ�ȷ�ϣ�����Ҫ����ȷ��';
      return ;
    end if ;
  v_total_share:='0';
  if p_type ='A' then 
              --���ݵǼ��˺�,��Ʒ��������ۻ�������ѯ���û��Ƿ���ڷݶ�
               select count(1) into v_count from   busi_share_balance v where v.regist_account=v_regist_account and v.pt_no=v_product_no and v.insti_code=v_insti_code;
                      
               
               if v_count > 0 then  --���ڷݶ�����ݶ�
                       select v.available,v.balance,v.fund_share into v_available,v_balance,v_fund_share from  busi_share_balance v where v.regist_account=v_regist_account and v.pt_no=v_product_no and v.insti_code=v_insti_code;
                       if v_business_type='024' then
                         update busi_share_balance b set b.available=(v_available-v_apply_share),b.balance=(v_balance-v_apply_share),b.fund_share=(v_fund_share-v_apply_share)
                         ,b.SHEET_IDS =SHEET_IDS||','||v_sheet_id where b.regist_account=v_regist_account and b.pt_no=v_product_no and b.insti_code=v_insti_code;
                          v_total_share:=v_available-v_apply_share;
                       else 
                          update busi_share_balance b set b.available=(v_available+v_apply_amount),b.balance=(v_balance+v_apply_amount),b.fund_share=(v_fund_share+v_apply_amount)
                         ,b.SHEET_IDS =SHEET_IDS||','||v_sheet_id where b.regist_account=v_regist_account and b.pt_no=v_product_no and b.insti_code=v_insti_code;
                           v_total_share:=v_available+v_apply_amount;
                       end if;
                     
                else --�����ڷݶ�
                  
                    if v_business_type='024'  then
                        msg:='����û�зݶû�а취����ز�����';
                    return ;
                  else 
                      select c.name into v_cp_name from ta_all_company c where c.code=  v_insti_code;
                       insert into  busi_share_balance(id,pt_no,pt_name,custom_name,regist_account,credit_no,available,balance,insti_code,custom_no
                                                       ,unit_net_val,fund_share,net_val_date,bonus_way,unpay_income,total_income,apply_no,zjlx,insti_name,sourcetype,pt_id,sheet_ids)
                        values(id_seq.nextval,v_product_no,v_name,v_cust_name,v_regist_account,v_credit_no,v_apply_amount,v_apply_amount,v_insti_code,v_custom_no,
                         '1',v_apply_amount,sysdate,null,null,null,'1',v_credit_type,v_cp_name,'1',v_product_id,v_sheet_id
                        );
                        v_total_share:=v_apply_amount;
                  end if;
               end if;
                msg:='�ݶ����ɹ�,�ܷݶ�Ϊ��'||v_total_share;
    elsif p_type='C' then
                  select count(1) into v_count from   busi_share_balance v where v.regist_account=v_regist_account and v.pt_no=v_product_no and v.insti_code=v_insti_code;
                  if v_count < 1 then 
                      msg:='�ݶ������ڣ�û�а취ȡ����';
                      return ;
                  end if ;        
                  
                    select v.apply_no,v.id into v_insert_status,v_banlance_id from   busi_share_balance v where v.regist_account=v_regist_account and v.pt_no=v_product_no and v.insti_code=v_insti_code;
                    --������뵥����1����ʾ���ֹ��ڷݶ������в�������ݣ��ӷݶ����ɾ��
                    if v_insert_status ='1' then
                           delete from busi_share_balance v where v.id=v_banlance_id;    
                    else
                            select v.available,v.balance,v.fund_share into v_available,v_balance,v_fund_share from  busi_share_balance v where v.regist_account=v_regist_account and v.pt_no=v_product_no and v.insti_code=v_insti_code;
                               if v_business_type='024' then    --��أ��ݶ�+����ݶ�
                                 update busi_share_balance b set b.available=(v_available+v_apply_share),b.balance=(v_balance+v_apply_share),b.fund_share=(v_fund_share+v_apply_share)
                                 ,b.SHEET_IDS =null where b.regist_account=v_regist_account and b.pt_no=v_product_no and b.insti_code=v_insti_code;
                                  v_total_share:=v_available+v_apply_share;
                               else  --���깺���ݶ�-����ݶ�
                                  update busi_share_balance b set b.available=(v_available-v_apply_amount),b.balance=(v_balance-v_apply_amount),b.fund_share=(v_fund_share-v_apply_amount)
                                 ,b.SHEET_IDS =null where b.regist_account=v_regist_account and b.pt_no=v_product_no and b.insti_code=v_insti_code;
                                   v_total_share:=v_available-v_apply_amount;
                               end if;

                    end if;
                    
                       msg:='ȡ���ɹ����ܷݶ�Ϊ��'||v_total_share;
           
    else 
        msg:='ҵ�����Ͳ�֧�֣�';
       return ;
    
    end if;
    
    
    
    --�������ӣ������busi_sheet���е�ȷ��״̬Ϊ��ȷ��
    if p_type = 'A' then 
       update busi_sheet set confirm_status = '1' where sheet_no = v_sheet_no;
    end if;
    --�����ȡ���������busi_sheet���е�ȷ��״̬Ϊδȷ��
    if p_type = 'C' then
       update busi_sheet set confirm_status = '0' where sheet_no = v_sheet_no;
    end if;
    
    commit;
  
    
EXCEPTION
    when no_data_found then 
      msg:='û���ҵ���¼�������Ƿ�˼�¼��ɾ��'||sqlerrm || sqlcode;
      return;
  WHEN OTHERS THEN
      ROLLBACK;
       msg:='ʧ��'||sqlerrm || sqlcode;
       v_msg:= sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace() || p_sheet_id || msg;
       insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
       commit;  
      return;
        
end TGYW_UPDATE_SHARE_BALANCE;
/


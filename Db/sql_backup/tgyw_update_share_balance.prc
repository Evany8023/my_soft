create or replace procedure smzj.TGYW_UPDATE_SHARE_BALANCE
(
  p_sheet_id     in   varchar2,      
  p_type         in   varchar2,  --A 代表添加， C代表取消
  msg         out  varchar2  
)

-- *************************************************************************
-- SYSTEM:       私募系统
-- SUBSYS:       私募之家
-- PROGRAM:      TGYW_UPDATE_SHARE_BALANCE
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  确认日赎回需求，只做货币基金
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
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
v_msg varchar2(1000); --错误信息
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
v_confirm_status varchar2(32);       --增加确认状态判断
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
 
 --如果是p_type是添加，并且确认状态是已确认，则不能再次确认
 if v_confirm_status = '1' and p_type = 'A' then
   msg:='该申请已确认，不能再次确认';
   return;
 end if;
 
  --如果是p_type是取消，并且确认状态是未确认，则不能再次取消确认
 if v_confirm_status = '0' and p_type = 'C' then
   msg:='该申请未确认，不能取消确认';
   return;
 end if;
 
 
  --如果该客户没有登记账号
  if   v_regist_account is null then      
    msg:='此订单客户没有登记账号:'|| v_credit_no || '名字：'||v_cust_name;
    return ;
  end if;
 
  --如果该产品不是货币基金
  select count(1) into  v_count from  busi_product_add t where t.product_id=v_product_id and t.fund_type='1';   
  if v_count < 1 then
    msg:='不是货币基金，没有办法计算份额';
    return ;
  end if ;
  
  --根据申请单号，产品代码，和销售机构来判断busi_trading_confirm中是否已经确认
    select count(1) into  v_count  from busi_trading_confirm c where c.apply_no=v_sheet_no and c.pt_no=v_product_no and c.insti_code=v_insti_code;
    if v_count > 0 then
      msg:='交易已经确认，不需要重新确认';
      return ;
    end if ;
  v_total_share:='0';
  if p_type ='A' then 
              --根据登记账号,产品代码和销售机构来查询该用户是否存在份额
               select count(1) into v_count from   busi_share_balance v where v.regist_account=v_regist_account and v.pt_no=v_product_no and v.insti_code=v_insti_code;
                      
               
               if v_count > 0 then  --存在份额，增减份额
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
                     
                else --不存在份额
                  
                    if v_business_type='024'  then
                        msg:='现在没有份额，没有办法做赎回操作！';
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
                msg:='份额计算成功,总份额为：'||v_total_share;
    elsif p_type='C' then
                  select count(1) into v_count from   busi_share_balance v where v.regist_account=v_regist_account and v.pt_no=v_product_no and v.insti_code=v_insti_code;
                  if v_count < 1 then 
                      msg:='份额余额不存在，没有办法取消！';
                      return ;
                  end if ;        
                  
                    select v.apply_no,v.id into v_insert_status,v_banlance_id from   busi_share_balance v where v.regist_account=v_regist_account and v.pt_no=v_product_no and v.insti_code=v_insti_code;
                    --如果申请单号是1，表示是手工在份额余额表中插入的数据，从份额表中删除
                    if v_insert_status ='1' then
                           delete from busi_share_balance v where v.id=v_banlance_id;    
                    else
                            select v.available,v.balance,v.fund_share into v_available,v_balance,v_fund_share from  busi_share_balance v where v.regist_account=v_regist_account and v.pt_no=v_product_no and v.insti_code=v_insti_code;
                               if v_business_type='024' then    --赎回，份额+申请份额
                                 update busi_share_balance b set b.available=(v_available+v_apply_share),b.balance=(v_balance+v_apply_share),b.fund_share=(v_fund_share+v_apply_share)
                                 ,b.SHEET_IDS =null where b.regist_account=v_regist_account and b.pt_no=v_product_no and b.insti_code=v_insti_code;
                                  v_total_share:=v_available+v_apply_share;
                               else  --认申购，份额-申请份额
                                  update busi_share_balance b set b.available=(v_available-v_apply_amount),b.balance=(v_balance-v_apply_amount),b.fund_share=(v_fund_share-v_apply_amount)
                                 ,b.SHEET_IDS =null where b.regist_account=v_regist_account and b.pt_no=v_product_no and b.insti_code=v_insti_code;
                                   v_total_share:=v_available-v_apply_amount;
                               end if;

                    end if;
                    
                       msg:='取消成功，总份额为：'||v_total_share;
           
    else 
        msg:='业务类型不支持！';
       return ;
    
    end if;
    
    
    
    --如果是添加，则更新busi_sheet表中的确认状态为已确认
    if p_type = 'A' then 
       update busi_sheet set confirm_status = '1' where sheet_no = v_sheet_no;
    end if;
    --如果是取消，则更新busi_sheet表中的确认状态为未确认
    if p_type = 'C' then
       update busi_sheet set confirm_status = '0' where sheet_no = v_sheet_no;
    end if;
    
    commit;
  
    
EXCEPTION
    when no_data_found then 
      msg:='没有找到记录，请检查是否此记录被删除'||sqlerrm || sqlcode;
      return;
  WHEN OTHERS THEN
      ROLLBACK;
       msg:='失败'||sqlerrm || sqlcode;
       v_msg:= sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace() || p_sheet_id || msg;
       insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
       commit;  
      return;
        
end TGYW_UPDATE_SHARE_BALANCE;
/


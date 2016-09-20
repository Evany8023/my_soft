create or replace procedure smzj."SYNC_TRADE_CONFIRM" as

---- *************************************************************************
-- SUBSYS:     ��ֵ����ͬ������
-- PROGRAM:      sync_trade_confirm
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       sunyang
-- DESCRIPTION:  ÿ������7��ͬ����ֵ��Ϣ
-- CREATE DATE:  2015��12��11��16:55:10
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************



 v_msg   varchar2(1000);
 v_job_name varchar2(100):= 'ͬ����ֵ����';

 v_open_date varchar2(20);  -- ��������
 v_busi_date varchar2(20); -- ��������
 v_today varchar2(30); -- ���ڵ�ʱ��
 cur_ptno SYNC_TRADE_DATA.PT_NO%type; -- ��Ʒ����
 
 v_ptname varchar2(100); -- ��Ʒ����
 v_nav_date varchar2(20);   --�����������
 v_unit_val number(10,4); -- ��λ��ֵ
 v_confirm_amount number; -- �깺ȷ���ܽ��
 v_confirm_share number; -- ���ȷ���ܷݶ�
 v_ransom_money number;  -- Ԥ����ؽ��
 v_busi_money number;    -- Ԥ��׼�������ʽ�
 
 
 cursor cur_pro  is 
 select m.jjdm,m.rq ,t.nav from   (select rl.jjdm,rl.rq,  row_number() over(partition by  rl.jjdm order by rl.rq desc) rn from t_rlb_jjzt rl 
      where rl.jjzt in('0','5','6') and rl.gzr = '1'  and rl.rq <to_char(sysdate,'yyyyMMdd') ) m,
      v_fundnav@wbdb_link t 
      where m.rn =1 and t.tradedate=m.rq and t.fundcode=m.jjdm;


BEGIN
  delete SYNC_TRADE_DATA;
 
  
   
   v_today := to_char(sysdate,'yyyy-MM-dd hh24:mi:ss'); -- ����ͬ��ʱ��
   
  
    open cur_pro;
    loop
      fetch cur_pro into cur_ptno,v_nav_date,v_unit_val;
      
      if cur_pro%notfound then
        exit;
      end if;
    
           
       begin
             -- ��Ʒ����
             select  p.name into v_ptname from Busi_Product p where p.product_no = cur_ptno;
        exception   when no_data_found then
          v_ptname:=null;
        end;
        if v_ptname is not null then
          
         -- ��������
           select min(rq) into v_busi_date from t_rlb_jjzt rl where rl.rq >to_char(sysdate,'yyyyMMdd') and 
            rl.gzr = '1' and  rl.jjdm=cur_ptno;
                   
               --��һ��������    
           select max(rq) into v_open_date from t_rlb_jjzt rl where rl.rq <to_char(sysdate,'yyyyMMdd') and 
            rl.gzr = '1' and  rl.jjdm=cur_ptno;
              
             -- �깺ȷ���ܽ��
            select round(sum(confirm_amount),4) into v_confirm_amount from 
            busi_trading_confirm where business_type = '122' and pt_no = cur_ptno and apply_date=v_open_date; 
                
            -- ���ȷ���ܷݶ�
            select round(sum(confirm_share),4) into v_confirm_share from 
            busi_trading_confirm where business_type = '124' and pt_no = cur_ptno and apply_date=v_open_date;
                
            -- Ԥ����ؽ��
            v_ransom_money := round((v_confirm_share*v_unit_val),4);
                
            -- Ԥ��׼�������ʽ�
            if (v_ransom_money-v_confirm_amount)>0 then
              v_busi_money := round((v_ransom_money-v_confirm_amount),4);
            else
              v_busi_money := 0;
            end if;

            insert into SYNC_TRADE_DATA
            (pt_no,pt_name,unit_net_val,apply_all_amount,confirm_share,
            open_date,busi_date,hope_ransom,hope_busi_money,sync_date)
            values
            (cur_ptno,v_ptname,v_unit_val,v_confirm_amount,v_confirm_share,
            v_open_date,v_busi_date,v_ransom_money,v_busi_money,v_today);
                  
                  
            end if;
              

 
  
  end loop;
  close cur_pro;
   v_msg:='ͬ��Ԥ���ճɹ�';
        insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
        
  commit;

  exception
    when others then
        rollback;
        v_msg:=sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace() || cur_ptno;
        insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
       commit;
end sync_trade_confirm;
/


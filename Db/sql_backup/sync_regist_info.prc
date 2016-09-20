CREATE OR REPLACE PROCEDURE SMZJ.SYNC_REGIST_INFO
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      SYNC_REGIST_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  ��ʱ����ͬ���ͻ��Ǽ��˺ŵ�֤����
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       ������
-- CREATE DATE:  2016-02-23
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
IS 
    v_msg                        varchar2(1000);
    v_job_name                   varchar2(100):= 'ͬ���ͻ��Ǽ��˺���Ϣ';
    
    v_cust_count                 integer;                       --�ͻ�����

    v_zjhm            Busi_Investor_Credit.Credit_No%type;      --֤������
    v_zjlx            Busi_Investor_Credit.Credit_Type%type;    --֤������
    v_djzh            Busi_Investor_Credit.Regist_Account%type; --�Ǽ��˺�
    
    cursor custinfo_cur is select t.djzh,t.zjhm,t.zjlx from zsta.uv_xx_khxx_sm@TA_DBLINK t 
                            inner join BUSI_INVESTOR_CREDIT c on t.zjhm=c.CREDIT_NO and t.zjlx=c.credit_type 
                           where c.REGIST_ACCOUNT is null and c.is_delete=0;
                           
    cursor custinfo_cur2 is  select t.taaccountid as djzh, t.certificateno as zjhm, case t.invtp when '1' then '0' when '0' then '1' end || t.certificatetype as zjlx from zsta.c_ack_acct_zd@TA_DBLINK t 
                            inner join BUSI_INVESTOR_CREDIT c on t.certificateno=c.CREDIT_NO and case t.invtp when '1' then '0' when '0' then '1' end || t.certificatetype=c.credit_type 
                           where c.REGIST_ACCOUNT is null and c.is_delete=0;

begin        --����ͬ���ͻ��Ǽ��˺ŵ�֤����ʼ     
    open custinfo_cur;
        loop
            fetch custinfo_cur into v_djzh,v_zjhm,v_zjlx;
            if custinfo_cur%notfound then
               exit;
            end if;
    
            select count(1) into v_cust_count from Busi_Investor_Credit t where  t.credit_no=v_zjhm and t.credit_type = v_zjlx and t.REGIST_ACCOUNT is null;

            if v_cust_count=1 then
                  update Busi_Investor_Credit t set t.regist_account=v_djzh where  t.credit_no = v_zjhm  and t.credit_type = v_zjlx; 
            elsif v_cust_count >1 then
                  v_msg := 'ͬ���ͻ���Ϣʱ�������ظ����û�����֤������:' || v_zjhm;
                  insert into t_fund_job_running_log (job_name, job_running_log) values (v_job_name, v_msg);
            end if;
      end loop;
      close custinfo_cur;
      
      
      open custinfo_cur2;
        loop
            fetch custinfo_cur2 into v_djzh,v_zjhm,v_zjlx;
            if custinfo_cur2%notfound then
               exit;
            end if;
    
            select count(1) into v_cust_count from Busi_Investor_Credit t where  t.credit_no=v_zjhm and t.credit_type = v_zjlx and t.REGIST_ACCOUNT is null;

            if v_cust_count=1 then
                  update Busi_Investor_Credit t set t.regist_account=v_djzh where  t.credit_no = v_zjhm  and t.credit_type = v_zjlx; 
            elsif v_cust_count >1 then
                  v_msg := 'ͬ���ͻ���Ϣʱ�������ظ����û�����֤������:' || v_zjhm;
                  insert into t_fund_job_running_log (job_name, job_running_log) values (v_job_name, v_msg);
            end if;
      end loop;
      close custinfo_cur2;
      
      

v_msg :='ͬ���ɹ�';
 insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
commit;

EXCEPTION
    when others then
        if custinfo_cur%isopen then
            close custinfo_cur;
        end if;
        rollback;
        
        if custinfo_cur2%isopen then
            close custinfo_cur;
        end if;
        rollback;
        
        
        v_msg :='ͬ��ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_REGIST_INFO;
/


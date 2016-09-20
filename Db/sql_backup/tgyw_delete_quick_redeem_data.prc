CREATE OR REPLACE PROCEDURE SMZJ.TGYW_DELETE_Quick_Redeem_DATA (p_fundid in  varchar2, p_compid in varchar2, todaydate in varchar2,flag out varchar2,msg out varchar2 ) is
---- *************************************************************************
-- SUBSYS:     �йܷ���
-- PROGRAM:      TGYW_PT_DELETE_TRADE_DATA
-- RELATED TAB:
-- AUTHOR:       pangzuoqing
-- DESCRIPTION:
--     ɾ���������
-- CREATE DATE:  2015-12-03
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

  v_job_name varchar2(100) :='tgyw_delete_Quick_Redeem_data';
  v_ch_job_name varchar2(100) :='����ɾ�������������';
  v_msg varchar2(4000);--������Ϣ
  v_flag integer :=0;--��־����֤�������Ӧ��������TA�������Ƿ�һ��
  ve_Exception   EXCEPTION;
  v_zjlb varchar2(50);--֤�����
  v_zjhm varchar2(50);--֤������
  v_cust_id varchar2(32 char );
  v_count integer :=0;



cursor sh_quick_data_cur  is select t.credit_no,t.credit_type_no
    from Busi_Batch_Quick_Redeem_Tmp  t
     where  t.company_id=p_compid
     and t.product_id=p_fundid
     and  to_char(t.apply_date,'yyyy-mm-dd')=todaydate
     and t.status=1;




begin

  if trim(p_compid) is null  or  trim(p_compid) is null or trim(todaydate) is null then
            v_flag := '9999';
            v_msg  := '�����Ʒ,����˾�����ڱ���';
            raise ve_Exception;
   end if;

   select count(*) into v_count from t_fund_job_status t where t.job_en_name = v_job_name;
   if v_count < 1 then
     insert into t_fund_job_status(job_en_name,job_cn_name) values(v_job_name,v_ch_job_name);
   end if;

   select count(*) into v_count from t_fund_job_status t where t.job_en_name = v_job_name and t.job_status=1;
   if v_count > 0  then
      v_msg :='����ִ���в������ظ�ִ�У����Ժ����ԣ�';
      insert into t_fund_job_running_log(job_name,job_running_log) values('',v_msg);
       raise ve_Exception;
    end if;



  update t_fund_job_status t set t.job_status = 1 where t.job_en_name = v_job_name;


  open sh_quick_data_cur ;
   loop
      fetch sh_quick_data_cur into v_zjhm,v_zjlb ;
          if sh_quick_data_cur%notfound then
               exit;
           end if;
             --�������ݸ��ݵ���Ŀͻ�֤����֤�����ͣ���������Ʒ��Ϣ���������ڣ�ɾ��
              select count(t.id) into  v_count from Busi_Investor_Credit  t ,busi_credit_company  cc where
               cc.credit_id=t.id and  t.credit_no =v_zjhm and t.credit_type=v_zjlb and
               cc.company_id=p_compid  and t.is_delete=0;
               v_cust_id:=null;

               if v_count > 0 then
                     select t.id into  v_cust_id from Busi_Investor_Credit  t ,busi_credit_company  cc,busi_product info where
                                   cc.credit_id=t.id and cc.company_id=info.cp_id and  t.credit_no =v_zjhm and t.credit_type=v_zjlb and
                                   cc.company_id=p_compid and info.id=p_fundid and t.is_delete=0;

                     delete from  Busi_Quick_Sheet t where t.credit_id= v_cust_id and t.pt_id=p_fundid and t.business_type='024' and   to_char(t.sheet_create_time,'yyyy-mm-dd')=todaydate ;

               end if ;

   end loop;

  delete from Busi_Batch_Quick_Redeem_Tmp t where   t.company_id=p_compid and t.product_id=p_fundid  and  to_char(t.apply_date,'yyyy-mm-dd')=todaydate and t.status=1;
  close sh_quick_data_cur;
  -- ɾ����������
  --delete busi_sale_data t where t.company_id=p_compid and t.product_id= p_fundid and   to_char(t.apply_date,'yyyy-mm-dd')=todaydate and t.status=1;


   update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;

  commit;
  flag:='000';
   msg  := 'ɾ���ͻ����� ������� ���ݵ��ɹ�';
  insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg||'  ,' || p_fundid || '  ,' || todaydate);



EXCEPTION
    WHEN ve_exception then
        rollback;

         if sh_quick_data_cur%isopen   then
           close sh_quick_data_cur;
         end if;

          flag:=v_flag;
           msg  := 'ɾ���ͻ����� ������� ���ݵ�ʧ�ܣ�'||todaydate ||'   ' ||sqlerrm;
          insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg||'  ,' || p_fundid || '  ,' || todaydate);
        RETURN;
    WHEN OTHERS THEN
        rollback;

         if sh_quick_data_cur%isopen   then
           close sh_quick_data_cur;
         end if;

          flag:='1000';
           msg  := 'ɾ���ͻ����� ������� ���ݵ�ʧ�ܣ�' || v_msg || '   '   || sqlerrm;
         insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg||'  ,' || p_fundid || '  ,' || todaydate);
        return;

end tgyw_delete_Quick_Redeem_data;
/


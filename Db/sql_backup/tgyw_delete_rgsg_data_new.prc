CREATE OR REPLACE PROCEDURE SMZJ.tgyw_delete_rgsg_data_new (p_fundid in  varchar2, p_compid in varchar2, todaydate in varchar2,flag out varchar2,msg out varchar2 ) is
---- *************************************************************************
-- SUBSYS:     �йܷ���
-- PROGRAM:      tgyw_delete_rgsg_data_new
-- RELATED TAB:
-- AUTHOR:       guxu
-- DESCRIPTION:
--    delete all data   , p_fundid   , p_compid , todaydate
-- CREATE DATE:  2016-04-11
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

  v_job_name varchar2(100) :='tgyw_delete_rgsg_data_new';
  v_ch_job_name varchar2(100) :='����ɾ�����깺����';
  v_msg varchar2(4000);--������Ϣ
  v_flag integer :=0;--��־����֤�������Ӧ��������TA�������Ƿ�һ��
  ve_Exception   EXCEPTION;
  v_zjlb varchar2(50);--֤�����
  v_zjhm varchar2(50);--֤������
  v_credit_id varchar2(32 char );

  v_count integer :=0;
  v_jy_count integer :=0;
  v_count_one_fund integer :=0;
  v_kh_count integer;
  v_kh_count2        pls_integer :=0;
  v_count1          integer :=0;
  v_yestoday date;
  v_count_jy integer :=0;
cursor sale_data_cur  is select t.credit_no,t.credit_type_code
    from  busi_sale_data t
     where  t.company_id=p_compid
     and  t.product_id=p_fundid
     and to_char(t.apply_date,'yyyy-mm-dd')=todaydate
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
  select to_date(to_char(sysdate-1,'yyyymmdd')||' 235959','yyyymmdd HH24:mi:ss')into v_yestoday  from dual;

  open sale_data_cur ;
   loop
      fetch sale_data_cur into v_zjhm ,v_zjlb;
       if sale_data_cur%notfound then
               exit;
        end if;
         --�������ݸ��ݵ���Ŀͻ�֤����֤�����ͣ���������Ʒ��Ϣ���������ڣ�ɾ��

             select count(t.id) into  v_count from Busi_Investor_Credit  t ,busi_credit_company  cc,busi_product info where
               cc.credit_id=t.id and cc.company_id=info.cp_id and  t.credit_no =v_zjhm and t.credit_type=v_zjlb and
               cc.company_id=p_compid and info.id=p_fundid and t.is_delete=0;
            v_credit_id:=null;
          if v_count >0 then

                select t.id into  v_credit_id  from Busi_Investor_Credit  t ,busi_credit_company  cc,busi_product info where
                                                   cc.credit_id=t.id and cc.company_id=info.cp_id and  t.credit_no =v_zjhm and t.credit_type=v_zjlb and
                                                   cc.company_id=p_compid and info.id=p_fundid and t.is_delete=0;

          v_kh_count:=0;
          v_count1:=0;
          v_jy_count:=0;
          v_count_jy:=0;

          -- ���쿪��
          select count(1) into v_kh_count from  Busi_Investor_Credit f  where f.id=v_credit_id  and f.create_date >v_yestoday;
          --ֻ��һ����˾����
          select count(*) into v_count1 from Busi_Credit_Company cc     where cc.credit_id=v_credit_id and cc.company_id <> p_compid;
          -- ���һ�β�Ʒ
          select count(*)  into v_count_one_fund from ( select count(1) from  Busi_Sheet t where t.credit_id=v_credit_id  and   t.business_type in('020','022') and t.is_delete='0'   group by  id  );
          --ɾ���͹�˾������ϵ������˾ֻ��һ������Ʒ����������ɾ��

          --��������һ����Ʒ���Ҳ�Ʒ�Ǳ���Ʒ
          if v_kh_count =1 and v_count1  =0   and  v_count_one_fund< 2 then
               delete  from Busi_Investor_Credit f where f.id=v_credit_id and   to_char(f.create_date,'yyyy-mm-dd')=todaydate;
          end if ;

        select count(1) into  v_jy_count from  Busi_Credit_Company cc     where cc.credit_id=v_credit_id and cc.company_id=p_compid;
        select count(*)  into v_count_jy from ( select count(1) from  Busi_Sheet t where t.credit_id=v_credit_id and t.company_id=p_compid   and   t.business_type in('020','022')  and t.is_delete='0'   group by  id  );
        if v_jy_count= 1   and v_count_jy=1 then
             delete from Busi_Credit_Company t where t.credit_id=v_credit_id and t.company_id=p_compid and t.sqrq> v_yestoday;
        end if;

        --ɾ�� ��������� ����sheet_no ȷ���Ǳ����������Ĳſ���ɾ��
         select count(*)  into v_count_jy from ( select count(1) from  Busi_Sheet t where t.credit_id=v_credit_id and t.company_id= p_compid  and   t.business_type in('020','022') and t.is_delete='0'   group by  id  );
         select count(*)  into v_kh_count2 from ( select count(1) from  Busi_Investor_Detail t where  t.company_id=p_compid and t.credit_id=v_credit_id and  t.is_delete='0' and  t.create_date >v_yestoday  );
        if  v_count_jy <2 and v_kh_count2 <2 then
            delete  from  Busi_Investor_Detail t  where t.company_id=p_compid and t.credit_id=v_credit_id and  t.is_delete='0' and   to_char(t.create_date,'yyyy-mm-dd')=todaydate ;
        end if;

        delete  from  busi_sheet t where t.credit_id=v_credit_id and t.pt_id=p_fundid and t.company_id=p_compid  and   t.business_type in('020','022')  and to_char(t.sheet_create_time,'yyyy-mm-dd')=todaydate ;

    end if ;
   end loop;

  close sale_data_cur;

  -- ɾ����������
  delete busi_sale_data t where t.company_id=p_compid and t.product_id= p_fundid and   to_char(t.apply_date,'yyyy-mm-dd')=todaydate and t.status=1;


   update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;

  commit;
  flag:='000';
  msg  := 'ɾ���ͻ������깺�Ϲ����ݵ��ɹ�'  ;
  insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg||'  ,' || p_fundid || '  ,' || todaydate);
 commit;


EXCEPTION
    WHEN ve_exception then
        rollback;
         if sale_data_cur%isopen   then
           close sale_data_cur;
         end if;

          flag:=v_flag;
           msg  := 'ɾ���ͻ������깺�Ϲ����ݵ�ʧ�ܣ�'||todaydate ||'   ' ||sqlerrm;
          insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg||'  ,' || p_fundid || '  ,' || todaydate);
           commit;
        RETURN;
    WHEN OTHERS THEN
        rollback;

         if sale_data_cur%isopen   then
           close sale_data_cur;
         end if;


          flag:='1000';
          msg  := 'ɾ���ͻ������깺�Ϲ����ݵ�ʧ�ܣ�' || v_msg || '   '   || sqlerrm;
          insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg||'  ,' || p_fundid || '  ,' || todaydate);
           commit;
        return;

end tgyw_delete_rgsg_data_new;
/

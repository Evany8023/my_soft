create or replace procedure smzj.tgyw_dvd_way is

---- *************************************************************************
-- SUBSYS:     �йܷ���
-- PROGRAM:      tgyw_dvd_way
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       liujian
-- DESCRIPTION:  �ֺ췽ʽ������ڸ���ͻ��ķֺ췽ʽ�����޸ģ��������������Ʒ�����޸ģ���
--        �ȴ�TA��ȡ�ͻ��ֺ췽ʽ��״̬��Ȼ������ϴ��޸��ļ���������Ӧ��03�޸��ļ���

-- CREATE DATE:  2015-10-23
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

v_msg   varchar2(4000);
v_job_name varchar2(100) :='tgyw_dvd_way' ;
v_job_log_name varchar2(100) :='tgyw_dvd_way :' || '�ֺ췽ʽͬ��' ;
v_com_name   VARCHAR2(256 CHAR);
v_com_code varchar2(16 CHAR);
v_com_id varchar2(32);
v_cust_id varchar2(32);  --֤��ID
v_id_card VARCHAR2(100 CHAR);
v_fund_id VARCHAR2(32);  --��Ʒid
v_fund_name VARCHAR2(200);  --��Ʒid
v_fund_code VARCHAR2(20);  --��Ʒid
v_user_name VARCHAR2(50 CHAR);
v_cust_djzh VARCHAR2(255 CHAR);
v_sql  varchar2(1000);
v_currenr_date  varchar2(8):='20140101';
fund_cust_cur    SYS_REFCURSOR;

v_pre_day VARCHAR2(10 CHAR);
v_count integer;
v_dvd_count integer;


begin
 select count(*) into v_count from t_fund_job_status t where t.job_en_name = v_job_name and t.job_status = 1;

   if v_count > 0  then
    v_msg :='����ִ���У��������ظ�ִ�У����أ�';
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
    return;
  end if;

  --����
  update t_fund_job_status t set t.job_status = 1 where t.job_en_name = v_job_name;
  commit;
  execute immediate 'truncate table busi_dvd_way'; -- ɾ������
  select count(1 ) into v_count from busi_dvd_way;
  if v_count > 0 then
          select to_char(max(CREATE_DATE),'yyyyMMdd') into v_currenr_date from busi_dvd_way;
  end if ;
   v_sql:='select m.credit_id ,m.pt_id,cr.credit_no,cr.regist_account,cr.name,cp.id,cp.insti_code,cp.cp_name, p.name,p.product_no from 
busi_investor_credit cr join busi_credit_company cc on cc.credit_id=cr.id join  busi_company cp on cc.company_id=cp.id,busi_product p,
(select t.credit_id,t.pt_id  from Busi_Sheet t where t.is_delete=0 group by t.credit_id,t.pt_id )m where 
cp.id=p.cp_id and p.id =m.pt_id and cr.id=m.credit_id and cr.is_delete=0 and cr.sourcetype=0 and p.is_delete=0 and cc.sourcetype=0 
and not exists( select w.id from Busi_Dvd_Way w where w.credit_id=m.credit_id and w.pt_id=p.id )';

  -- ��ʼ�� ��Ʒ��Ͷ���ߵĹ�ϵ
  open fund_cust_cur for v_sql;
  loop
    fetch fund_cust_cur into v_cust_id,v_fund_id,v_id_card,v_cust_djzh,v_user_name,v_com_id,v_com_code,v_com_name,v_fund_name,v_fund_code;
    if fund_cust_cur%notfound then
      exit;
    end if;

    select count(1) into v_dvd_count from busi_dvd_way t where t.credit_id =v_cust_id and t.pt_id = v_fund_id;
    if v_dvd_count <1 then

             select count(1) into  v_count from busi_product pt ,busi_sheet sh where pt.id=sh.pt_id and sh.credit_id =v_cust_id and pt.id=v_fund_id;

            if v_count >0 then
               begin
                      insert into busi_dvd_way(id,cp_id ,cp_no ,cust_name,credit_id,create_date,regist_account,credit_no,cp_name,pt_id,pt_no,pt_name)
                      values( sys_guid(),v_com_id,v_com_code,v_user_name,v_cust_id,sysdate,v_cust_djzh ,v_id_card ,v_com_name,v_fund_id , v_fund_code, v_fund_name 
                      );
                    
                exception
                   when others then
                        v_msg :='ͬ��ʧ�ܣ�ԭ��'|| sqlcode || ':' || sqlerrm ;
                        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
                end ;
      
            end if ;
    else
        update busi_dvd_way t set t.cust_name=v_user_name ,t.regist_account=v_cust_djzh,t.credit_no =v_id_card where t.pt_id=v_fund_id and t.credit_id=v_cust_id;
    end if;

  end loop;
  close fund_cust_cur;
  commit;

 --��ʼ�� ��Ʒ״̬
  update busi_dvd_way  a set (a.dvd_status,a.update_date )=(
     select   t.defdividendmethod,sysdate  from zsta.fundextrainfo@TA_DBLINK t where  t.fundcode=a.pt_no )
  where exists( select   t.defdividendmethod  from zsta.fundextrainfo@TA_DBLINK t where  t.fundcode=a.pt_no
  ) and a.dvd_status is null ;

 --ͬ�� �ͻ� �ֺ�״̬
  select getpreworkday( to_char(sysdate,'yyyyMMdd')) into v_pre_day from dual;


update busi_dvd_way  a set (a.dvd_status,a.update_date )=(
    select   t.defdividendmethod,sysdate from zsta.bal_fund@TA_DBLINK t where (t.defdividendmethod =1 or t.defdividendmethod =0 )
  and t.fundcode=a.pt_no and t.taaccountid =a.regist_account  and (a.apply_change_date is null or to_char(a.apply_change_date,'yyyymmdd')< v_pre_day ))

  where exists(
         select   t.defdividendmethod  from zsta.bal_fund@TA_DBLINK t where (t.defdividendmethod =1 or t.defdividendmethod =0 )
         and t.fundcode=a.pt_no and t.taaccountid =a.regist_account
  )  and (a.apply_change_date is null or to_char(a.apply_change_date,'yyyymmdd')< v_pre_day) ;


    --�ͷ�
  update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;
   v_msg :='ͬ���ɹ�';
   insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
  commit;


exception
    when others then
      rollback;
      v_msg :='ͬ��ʧ�ܣ�ԭ��'|| sqlcode || ':' || sqlerrm ;
      insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
       commit;

end tgyw_dvd_way;
/


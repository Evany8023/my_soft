create or replace procedure smzj.SYNC_parent_son_relation is

---- *************************************************************************
-- SUBSYS:     �йܷ���
-- PROGRAM:      SYNC_parent_son_relation
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       liujian
-- DESCRIPTION:  ͬ����ĸ��ϵ
-- CREATE DATE:  2015-10-23
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

v_count integer;
v_m_count integer;
v_cust_count integer;
v_cust_id  varchar2(19  char);
v_fund_count integer;
v_msg   varchar2(4000);
v_job_name varchar2(100) :='SYNC_parent_son_relation';
v_current_date  varchar2(8);
v_fund_clr busi_product.publish_date%type;
v_fund_id   varchar2(32);
v_fund_com_id   varchar2(32);
v_m_fund_com_id   varchar2(32);
v_fund_com_code    busi_company.insti_code%type;
v_fund_com_name   busi_company.cp_name%type;
v_m_fund_com_code    busi_company.insti_code%type;
v_m_fund_com_name   busi_company.cp_name%type;

v_id busi_pt_zm_relation.id%type;    --��ĸ��ϵ��id��32λ�����
v_fund_name busi_product.name%type;  --�ӻ�������
v_m_fund_id busi_product.id%type;
v_m_fund_name busi_product.name%type;
v_fund_code varchar2(16);
v_m_fund_code varchar2(16);            --ĸ�����Ʒ����
v_fund_code_tmp varchar2(16);          --�ӻ����Ʒ����
v_m_fund_status integer;
v_status_desc  varchar2(20);
v_ya_day varchar2(20):='δ����';                 --ѹ������
v_taaccountid busi_investor_credit.regist_account%type;    --�ӻ���Ǽ��˺�

cursor fundinfo_cur is select pt.id,pt.publish_date, pt.product_no, pt.name,pt.cp_id,
                              cp.insti_code,cp.cp_name,
                              f.fundcode,f.triggertype,f.taaccountid,
                              decode(t.APPLYTYPE,'0','1','N',to_char(DELAYCFMDAYS),'2', '2', t.APPLYTYPE) ya_day
                        from busi_product pt
                        inner join busi_company cp on cp.id=pt.cp_id
                        inner join zsta.fundmasterfeeder@ta_dblink f on pt.product_no=f.mfundcode
                        left join zsta.fundextrainfo@ta_dblink t on pt.product_no=t.FUNDCODE
                     where pt.is_examine = 1;
begin
 select count(*) into v_count from t_fund_job_status t where t.job_en_name = v_job_name and t.job_status = 1;

   if v_count > 0  then
    v_msg :='����ִ���У��������ظ�ִ�У����أ�';
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
  
  end if;

  --����
  select count(*) into v_count from t_fund_job_status t where t.job_en_name = v_job_name;
   if v_count > 0 then
      update t_fund_job_status t set t.job_status = 1 where t.job_en_name = v_job_name;
    else
      insert into t_fund_job_status(JOB_EN_NAME,JOB_CN_NAME,JOB_STATUS) values('SYNC_parent_son_relation', 'ͬ����ĸ��ϵ','1');
    end if;
  commit;
  v_current_date := to_char(sysdate,'yyyyMMdd');

  execute immediate 'truncate table busi_pt_zm_relation';
  open fundinfo_cur;
  loop
    fetch fundinfo_cur into v_m_fund_id,v_fund_clr, v_m_fund_code ,v_m_fund_name,v_m_fund_com_id,v_m_fund_com_code,v_m_fund_com_name,v_fund_code_tmp,v_m_fund_status,v_taaccountid,v_ya_day;
          if fundinfo_cur%notfound then
            exit;
          end if;

        --��ѯ�Ӳ�Ʒ��Ӧ�ͻ����
        v_cust_id:='δ����';
        select count(1) into v_cust_count from busi_investor_credit t where t.regist_account= v_taaccountid;
        if v_cust_count > 0 then
              select distinct t.custom_no into v_cust_id from busi_investor_credit t where t.regist_account= v_taaccountid and rownum=1;
         end if;

        if v_m_fund_status=0 then
            v_status_desc:='�����깺���';
         elsif  v_m_fund_status=1 then
            v_status_desc:='�������깺';
         elsif v_m_fund_status=2 then
            v_status_desc:='���������';
        end if ;

         --��ѯ�Ӳ�Ʒ�Ĳ�Ʒ���빫˾�������Ϣ
         select count(1) into  v_m_count from  busi_product pt inner join busi_company cp on pt.cp_id=cp.id where pt.product_no=v_fund_code_tmp;
        --�������
         v_fund_id:=null;v_fund_name:=null;v_fund_com_id:=null;v_fund_com_code:=null;v_fund_com_name:=null;
         if v_m_count>0 then
              select pt.id,pt.name,cp.id com_id,cp.insti_code,cp.cp_name into v_fund_id,v_fund_name,v_fund_com_id,v_fund_com_code,v_fund_com_name from  busi_product pt inner join busi_company cp on pt.cp_id=cp.id where pt.product_no=v_fund_code_tmp;
         end if ;

         --�ж���ĸ��ϵ�����Ƿ���ڼ�¼
         select count(1) into v_fund_count from busi_pt_zm_relation  t where  t.parent_pt_no=v_m_fund_code and t.son_pt_no=v_fund_code_tmp;
         if v_fund_count < 1 then
              select sys_guid() into v_id from dual;
              insert into busi_pt_zm_relation(id,parent_pt_id,parent_pt_no,parent_pt_name,parent_cp_id,parent_cp_name,parent_cp_no,son_cp_id,son_cp_no,son_cp_name,son_pt_id,son_pt_no,son_pt_name,trigger_no,trigger_desc,son_regist_acc,delay_day,cust_no,update_date)
                  values(v_id,v_m_fund_id,v_m_fund_code,v_m_fund_name,v_m_fund_com_id,v_m_fund_com_name,v_m_fund_com_code,v_fund_com_id,v_fund_com_code,v_fund_com_name,v_fund_id,v_fund_code_tmp,v_fund_name,v_m_fund_status,v_status_desc,v_taaccountid,v_ya_day,v_cust_id,sysdate);
         else
              update busi_pt_zm_relation t set t.son_regist_acc=v_taaccountid ,t.son_pt_name=v_fund_name,t.delay_day=v_ya_day,t.cust_no=v_cust_id,update_date=sysdate where t.parent_pt_no=v_m_fund_code and t.son_pt_no=v_fund_code_tmp;
        end if;
  end loop;
  close fundinfo_cur;
  commit;

    --�ͷ�
  update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;
    v_msg :='ͬ���ɹ���   ' ||     v_current_date;
   insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
   commit;
  
  

exception
    when others then
      rollback;
      v_msg :='ͬ��ʧ�ܣ�ԭ��' || v_current_date || '     '  || sqlcode || ':' || sqlerrm || '  ' ||v_fund_code || ' ' ||v_fund_name || dbms_utility.format_error_backtrace();
    update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;
     insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);

end SYNC_parent_son_relation;
/


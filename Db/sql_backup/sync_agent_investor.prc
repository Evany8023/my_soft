create or replace procedure smzj.sync_agent_investor
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      SYNC_CLEAR_PRODUCT
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION: ͬ�������ͻ�������
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
/*
a)֧�����������ѯ������������������ѡ�������ȫ����ֱ������������1����������2�ȴ����������������У���ȫ����������������;
b)��ͬһͶ����ֻͨ��ֱ������ù����˲�Ʒ����������������ʾ��ֱ������
c)��ͬһͶ����ֻͨ��һ��������������ù����˲�Ʒ����������������ʾ�ô���������
d)��ͬһͶ����ͨ�����������������ù����˲�Ʒ����������������ʾ������������
e)��ͬһͶ���˼�ͨ����ֱ������������ù����˲�Ʒ����ͨ��������������������������������ʾ������������
*/

-- AUTHOR:       ������
-- CREATE DATE:  2016-01-06
-- VERSION:
-- EDIT HISTORY:
-- ************************************************************************

is
    v_msg                        varchar2(1000);
    v_job_name                   varchar2(100):= 'ͬ�������ͻ���Ϣ';

    v_company_count              integer;                               --�ͻ��������������˾����
    v_regist_account             busi_investor_credit.regist_account%type; --�Ǽ��˺�

    v_pt_insti_code              busi_company.insti_code %type;               --��Ʒ������˾�Ĺ�˾code
    v_ta_insti_code_str          varchar2(100);                               --���ۻ��������ַ�������","�ָeg:'S31','S32','301'
    v_ta_insti_name_str         varchar2(100);               --��Ʒ������˾�Ĺ�˾code
    v_cust_count                 integer;
    v_ta_cust_count                 integer;                                   --��ʱ������
    v_ta_company_count           integer;
    v_cust_company_count           integer;                                         --��ʱ������
    v_password                   VARCHAR2(32);
    v_table_id                   VARCHAR2(32);                          --��ID,���ɵ�32λ�������Ϊcredit_id
    v_detail_table_id            VARCHAR2(32);                          --detail��ID,���ɵ�32λ�������Ϊid
    v_zjlx_count                 integer;
    v_user_type                  VARCHAR2(2);                           --�ͻ����ͣ�1�����ˣ�2��������
    v_user_frdm                  VARCHAR2(100);                           --�ͻ����ͣ�1�����ˣ�2��������
    v_user_jbr                   VARCHAR2(100);                           --�ͻ����ͣ�1�����ˣ�2��������
    v_user_name                  ta_all_user.name%type;                 --�ͻ�����
    v_user_zjlx                  ta_all_user.zjlx%type;                 --�ͻ�֤������
    v_user_zjhm                  ta_all_user.zjhm%type;                 --�ͻ�֤������
    v_user_custom_no             busi_trading_confirm.custom_no%type;   --�ͻ�֤�����

    v_company_id                 busi_credit_company.company_id%type;   --��˾id
    v_apply_no                   VARCHAR2(100);
    v_sourcetype                   VARCHAR2(100);
    v_flag                       VARCHAR2(100);
cursor regist_acct_cur is  select  t.pt_comcode,t.regist_account ,wm_concat(''''||t.ta_comcode||'''')  from
                   (select bc.INSTI_CODE pt_comcode,c.regist_account,c.insti_code ta_comcode from Busi_Trading_Confirm c
                            inner join  busi_product bp on bp.product_no=c.pt_no and c.sourcetype='1' inner join busi_company bc on bc.id=bp.cp_id
                            inner join  Ta_All_Company ap on c.insti_code=ap.code and ap.source='1' and bp.is_import_sales='1'
                            where   c.regist_account is not null  
                       group by  bc.insti_code,c.regist_account, c.insti_code
                    ) t where not exists(
                      select * from  Busi_Credit_Company cc join busi_investor_credit ic on  ic.id=cc.credit_id 
                      join busi_company c on c.id=cc.company_id where ic.regist_account=t.regist_account  
                      and c.insti_code=t.pt_comcode

                    )
                     group by  t.pt_comcode, t.regist_account;

begin
   open regist_acct_cur;
    loop
      fetch regist_acct_cur into v_pt_insti_code,v_regist_account,v_ta_insti_code_str;
      if regist_acct_cur%notfound then
          exit;
      end if;
      v_flag:='0';
      select count(1) into v_cust_count from Busi_Investor_Credit c where c.regist_account=v_regist_account;
       select count(1) into v_ta_cust_count from ta_all_user u where u.dzjh=v_regist_account and u.type='A';
      select count(1) into v_company_count from Busi_Company cc where cc.insti_code=v_pt_insti_code;
      EXECUTE IMMEDIATE 'select count(1) from Ta_All_Company ta where   ta.code in ( '||v_ta_insti_code_str||')' INTO v_ta_company_count;
      EXECUTE IMMEDIATE 'select wm_concat( ta.name) from Ta_All_Company ta where ta.code in ( '||v_ta_insti_code_str||')' INTO v_ta_insti_name_str;

      if v_cust_count < 1 AND  v_company_count=1 and v_ta_cust_count> 0 THEN

         select c.id into v_company_id from busi_company c where c.insti_code=v_pt_insti_code;
         select sys_guid() into v_table_id from dual;
         select sys_guid() into v_detail_table_id from dual;

         if v_ta_company_count> 0 then
             select u.name,u.zjhm,u.zjlx,u.KHBM,u.FRDB,u.JBRMC into v_user_name,v_user_zjhm,v_user_zjlx,v_user_custom_no,v_user_frdm,v_user_jbr from ta_all_user u where u.dzjh=v_regist_account and u.type='A' and rownum=1;
             select count(*) into v_cust_count from Busi_Investor_Credit t where t.credit_no   = v_user_zjhm and t.credit_type = v_user_zjlx; --֤������
             if v_cust_count< 1 then
                   --ͨ��֤�����ʹ��ֵ���ж��Ǹ��˻��ǻ����ͻ�
                 select count(1) into v_zjlx_count from sys_dict d where d.type='credit_type' and d.description='����֤������' and d.del_flag=0 and d.value=v_user_zjlx;
                    if v_zjlx_count=1 then
                         v_user_type:='2';
                     else
                         v_user_type:='1';
                    end if;

                     select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
                  select md5(substr(v_user_zjhm, length(v_user_zjhm) - 6 + 1, 6))  into v_password  from dual;

                 insert into busi_investor_credit (ID,NAME,credit_type,credit_no,custom_no,user_type,is_delete,regist_account,sourcetype,refrence,IS_EXAMINE,EXAMINE_BY,EXAMINE_DATE,PASSWORD,IS_ACTIVE,create_date,create_by,legal_person)
                  values (v_table_id,v_user_name,v_user_zjlx,v_user_zjhm,v_user_custom_no,v_user_type,'0',v_regist_account,'1','4','1','sync',sysdate,v_password,'0',sysdate,'sync',v_user_frdm);

                  v_flag:='1';
          
             end if;
         end if;


         if v_ta_company_count >= 2 and v_flag='1' THEN   -- 2������ֻ�д���
            insert into busi_credit_company (credit_id,company_id,sourcetype,INSTI_NAME,insti_code) values (v_table_id,v_company_id,v_ta_company_count,v_ta_insti_name_str,v_ta_insti_code_str);
         elsif v_ta_company_count = 1 and v_flag='1' THEN -- 1��������ʾ������������
              insert into busi_credit_company (credit_id,company_id,insti_code,insti_name,sourcetype) values (v_table_id,v_company_id,v_ta_insti_code_str,v_ta_insti_name_str,v_ta_company_count);
            end if;

       elsif v_cust_count > 0 AND  v_company_count=1 and v_ta_company_count > 0  and v_ta_cust_count> 0 then  -- �˴��ڣ�����û������м��ϵ
              select c.id into v_company_id from busi_company c where c.insti_code=v_pt_insti_code;
              select c.id into v_table_id from Busi_Investor_Credit c where c.regist_account=v_regist_account and rownum=1;
              select count(1) into v_cust_company_count  from busi_credit_company t where t.credit_id=v_table_id and t.company_id=v_company_id;

              if v_cust_company_count> 0 then
                 select t.sourcetype into v_sourcetype  from busi_credit_company t where t.credit_id=v_table_id and t.company_id=v_company_id;
                 if v_sourcetype >'0' then
                    update  busi_credit_company t set t.insti_code=v_ta_insti_code_str,t.insti_name=v_ta_insti_name_str,t.sourcetype=v_ta_company_count,t.create_date=sysdate where t.credit_id=v_table_id and t.company_id=v_company_id;
                  else
                     update  busi_credit_company t set t.insti_code=v_ta_insti_code_str,t.insti_name='ֱ��,'||v_ta_insti_name_str,t.sourcetype='0',t.create_date=sysdate where t.credit_id=v_table_id and t.company_id=v_company_id;
                 end if;
              else
                  insert into busi_credit_company (credit_id,company_id,insti_code,insti_name,sourcetype) values (v_table_id,v_company_id,v_ta_insti_code_str,v_ta_insti_name_str,v_ta_company_count);
              end if;

       end if;

    end loop;
    close regist_acct_cur;

    --������������
    update Busi_Credit_Company t set (t.sqrq,t.sourcetype)= (
    select sqrq,'0' from (select dd.company_id ,dd.credit_id,dd.create_date as sqrq,  ROW_NUMBER() over(partition by dd.company_id ,dd.credit_id order by dd.CREATE_DATE desc) rn  from Busi_Investor_Detail dd where dd.is_delete='0') m
     where rn=1 and t.credit_id=m.credit_id and t.company_id=m.company_id and t.sourcetype='0'
    )
    where exists(
       select sqrq from (select dd.company_id ,dd.credit_id,dd.create_date as  sqrq,  ROW_NUMBER() over(partition by dd.company_id ,dd.credit_id order by dd.CREATE_DATE desc) rn  from Busi_Investor_Detail dd where dd.is_delete='0') m
     where rn=1 and t.credit_id=m.credit_id and t.company_id=m.company_id and t.sourcetype='0'
    );


    v_msg :='ͬ���ɹ�';
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    commit;

EXCEPTION
    when others then
       rollback;

        if regist_acct_cur%isopen then
            close regist_acct_cur;
        end if;

        v_msg :='ͬ��ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm || v_regist_account ||'    ' || v_pt_insti_code || '   ' || v_ta_insti_code_str  ||SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end sync_agent_investor;
/


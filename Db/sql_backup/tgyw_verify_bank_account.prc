create or replace procedure smzj.TGYW_VERIFY_BANK_ACCOUNT(p_company_id in varchar2,   --��˾id
                                                     p_BATCH_NUMBER_ID in varchar2, --���κ�
                                                     p_apply_date in varchar2,      --��������
                                                     p_mgrid in varchar2,      --������id
                                                     p_ismgr in varchar2,      --�Ƿ�һ��������
                                                     p_flag2 out varchar2,
                                                     p_message out varchar2) is

---- *************************************************************************
-- SUBSYS:     �йܷ���
-- PROGRAM:      TGYW_VERIFY_BANK_ACCOUNT
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       xiaxn
-- DESCRIPTION:  ��֤�����˺�
-- CREATE DATE:  2016-05-05
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
v_ID                varchar2(100);           --��ʱ��id
v_NO                varchar2(100);           --�к�
v_INVESTOR_TYPE     varchar2(100);           --Ͷ�������ͣ�ȡ��busi_bank_data_temp��
v_CREDIT_TYPE       varchar2(100);           --Ͷ����֤������
v_CREDIT_NO         varchar2(100);           --Ͷ����֤������
v_CREDIT_ID         varchar2(100);           --Ͷ����id
v_INVESTOR_NAME     varchar2(100);           --Ͷ��������
v_PROVINCE_NAME     varchar2(100);           --������ʡ��
v_CITY_NAME         varchar2(100);           --�����г���
v_OPEN_BANK_NAME    varchar2(100);           --������
v_PRODUCT_NO        varchar2(100);           --��Ʒ����
v_IS_BACK_ACCOUNT   varchar2(100);           --�Ƿ�ֺ�����˺�


v_ACCOUNT_NO        varchar2(100);           --�˺�
v_USER_NAME         varchar2(100);           --��������,ȡ��busi_bind_bank_card��
v_USER_NAME2        varchar2(100);           --�������ƣ�ȡ��busi_investor_credit��
v_USER_TYPE         varchar2(100);           --Ͷ�������ͣ�ȡ��busi_investor_credit��
v_PRODUCT_ID        varchar2(100);           --��Ʒid
v_flag              number;                  --��������У��ɹ�ʧ�ܱ�־
v_msg               varchar2(1000);          --��������У����Ϣ
v_count             number;
v_msg2              varchar2(1000);          --��طֺ��˺���ϸ��Ϣ

v_count2            number:=0;                  --������Ϣ�����������10��ʱ���������Ӵ���p_message��ֵ

v_msg3              varchar2(1000):='TGYW_VERIFY_BANK_ACCOUNT';
v_job_name varchar2(100) :='sync_old_fund_value';


cursor data_cur is select t.id,t.row_number,CASE t.INVESTOR_TYPE when '����' then '1' ELSE '2' END,
                t.CREDIT_TYPE_CODE,t.CREDIT_NO,t.investor_name,t.province_name,t.city_name,t.open_bank_name,t.PRODUCT_NO,t.IS_BACK_ACCOUNT
       from busi_bank_data_temp t
       where t.BATCH_NUMBER_ID =  p_BATCH_NUMBER_ID and t.is_delete = '0' AND t.COMPANY_ID=p_company_id AND t.APPLY_DATE=p_apply_date order by t.row_number;


begin
  p_flag2:= 0;                 --��ʼ��Ϊ0����ʾû�д���


  open data_cur;
  loop
      fetch data_cur into v_ID,v_NO,v_INVESTOR_TYPE,v_CREDIT_TYPE,v_CREDIT_NO,v_INVESTOR_NAME,v_PROVINCE_NAME,v_CITY_NAME,v_OPEN_BANK_NAME,v_PRODUCT_NO,v_IS_BACK_ACCOUNT;
        if data_cur%notfound then
          exit;
        end if;

        v_flag:=0;
        v_msg:='�ļ���'||v_NO||'�У�'||' ';


        --1.�жϲ�Ʒ�Ƿ����
        IF v_flag=0 then
            select count(1) into v_count from busi_product p where p.product_no = v_PRODUCT_NO and is_delete='0';
            if v_count =0 then
                v_flag:='1';
                v_msg := v_msg||'��Ʒ'||v_PRODUCT_NO||'�����ڣ����ʵ�޸ĺ��ٴε���';
            else
                select p.id into v_PRODUCT_ID from busi_product p where  p.product_no = v_PRODUCT_NO and p.is_delete = '0'; --ȡ����Ʒid
            end if;
        END IF;

        --2.�жϲ�Ʒ�Ƿ�������ҹ�˾
        IF v_flag=0 then
            select count(1) into v_count from busi_product p where  p.cp_id = p_company_id and p.product_no=v_PRODUCT_NO  and p.is_delete = '0';
            if v_count=0 then
                v_flag:='1';
                v_msg := v_msg||'��Ʒ'||v_PRODUCT_NO||'�����ڸù����ˣ����ʵ�޸ĺ��ٴε���';
            end if;
        END IF;

        --����Ƕ�������Ա���ж��Ƿ�����Ȩ�Ĳ�Ʒ
        IF v_flag=0 and p_ismgr=0 then
             select count(1) into v_count from busi_product_authorization p  where p.product_id=v_PRODUCT_ID and p.mgr_id=p_mgrid and p.cp_id=p_company_id;
             if v_count=0 then
                v_flag:='1';
                v_msg := v_msg||'����Ȩ������Ʒ'||v_PRODUCT_NO||'�����ʵ�޸ĺ��ٴε���';
             end if;
         END IF;


        --3.�ж�Ͷ�������ͣ�Ͷ����֤�����ͣ�Ͷ����֤������,Ͷ���������Ƿ�һ��
        IF v_flag=0 then
            select count(1) into v_count from busi_investor_credit t where  t.credit_type = v_CREDIT_TYPE and t.credit_no = v_CREDIT_NO  and is_delete=0;
            if v_count=0 then
                   v_flag:=1;
                   v_msg := v_msg||'�Ҳ�����Ͷ���ˣ�����֤�����ͺ�֤�����룬��ʵ�޸ĺ��ٴε���';
            else
                   select t.id into v_CREDIT_ID from busi_investor_credit t where t.credit_type = v_CREDIT_TYPE and t.credit_no = v_CREDIT_NO;   --ȡ��credit_id
            end if;
            --У��Ͷ�������ͺ�Ͷ��������
            if v_flag=0 then
                 select t.name,t.user_type into v_USER_NAME2,v_USER_TYPE from busi_investor_credit t where t.credit_type = v_CREDIT_TYPE and  t.credit_no = v_CREDIT_NO  and is_delete=0;
                 if v_USER_NAME2 <> v_INVESTOR_NAME then
                        v_flag:=1;
                        v_msg := v_msg||'Ͷ�������ֲ���ȷ�����ʵ�޸ĺ��ٴε���';
                 end if;
                 if v_USER_TYPE <> v_INVESTOR_TYPE then
                        v_flag:=1;
                        v_msg := v_msg||'Ͷ�������Ͳ���ȷ�����ʵ�޸ĺ��ٴε���';
                 end if;
             end if;
        END IF;

        --4.�ж�Ͷ�����Ƿ�������ҹ�˾
        IF v_flag=0 then
            select count(1) into v_count from busi_credit_company c where  c.company_id = p_company_id and c.credit_id=v_CREDIT_ID;
            if v_count=0 and v_flag=0 then
                  v_flag:='1';
                  v_msg := v_msg||'�ͻ�'||v_INVESTOR_NAME||'�����ڸù����ˣ������ڡ������ͻ�������Ӹÿͻ�';
            end if;
         END IF;


        --5.У�鿪�������ƣ�������ʡ�ݺͿ����г���
        IF v_flag=0 then
            select count(1) into v_count from busi_region where name like '%'||v_PROVINCE_NAME||'%';
            if v_count=0 then
                  v_flag:='1';
                  v_msg := 'ʡ����Ϣ'||v_PROVINCE_NAME||'�������ʵ�޸ĺ��ٴε���';
            end if;

            select count(1) into v_count from busi_region where name like  '%'||v_CITY_NAME||'%';
            if v_count=0 and v_flag=0 then
                  v_flag:='1';
                  v_msg := '������Ϣ'||v_CITY_NAME||'�������ʵ�޸ĺ��ٴε���';
            end if;
        END IF;

      IF v_flag=1 then  --У����ȷ�������طֺ��˺�
           p_flag2 := 1;
           if v_count2 < 10 then
               p_message := p_message||v_msg||chr(13);
           end if;
           v_count2 := v_count2+1;
           delete busi_bank_data_temp t where t.batch_number_id=p_BATCH_NUMBER_ID and t.company_id=p_company_id;
           return;
       END IF;

      --�ж��Ƿ��Ѿ����ڷֺ�����˺�
      select count(1) into v_count from busi_bind_bank_card b where b.credit_id= v_CREDIT_ID and b.is_back_account='1' and b.product_id = v_PRODUCT_ID and is_delete='0';
      if v_count = 0 then                 --û����طֺ��˺�
         update busi_bank_data_temp t set t.REMARK = '��' where t.id = V_ID;
      else
         select c.OPEN_BANK_NAME,c.ACCOUNT_NO,USER_NAME into v_OPEN_BANK_NAME,v_ACCOUNT_NO,v_USER_NAME  from busi_bind_bank_card c
                where c.credit_id= v_CREDIT_ID and c.is_back_account='1' and c.product_id = v_PRODUCT_ID and c.is_delete='0';
         v_msg2 :=  '�����У�'||v_OPEN_BANK_NAME||'���˻���'||v_ACCOUNT_NO||'���������ƣ�'||v_USER_NAME;
         update busi_bank_data_temp t set t.REMARK = '������طֺ��˺�',t.REMARK_INFO = v_msg2 where t.id = v_ID;
      end if;

   end loop;
   close data_cur;
   --���Լ�¼ÿ��У����Ϣ��д��Ҫע�͵���
   if v_flag=0 then
      p_message := 'У��ɹ�';
      update busi_bank_data_temp t set t.check_result = v_flag, t.check_info=v_msg where t.row_number=v_NO;
   end if;
   insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg3);
   commit;
EXCEPTION
    when others then
        if data_cur%isopen then
            close data_cur;
        end if;
        rollback;

        v_msg3 :='ͬ��ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg3);
        commit;


end TGYW_VERIFY_BANK_ACCOUNT;
/


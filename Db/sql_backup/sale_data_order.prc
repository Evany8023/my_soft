create or replace procedure smzj.sale_data_order(p_companyid in varchar2,
                                            p_productid in varchar2,
                                          --  p_businesstype   in varchar2,
                                            p_flag   in varchar2,
                                            p_create_user in varchar2
                                            --r_flag out varchar2,
                                            --,r_msg out varchar2
                                            ,c_result out sys_refcursor) is

 v_count integer;--��¼�Ѿ�������������
 v_msg varchar2(4000);--������Ϣ
 v_hasimportdata integer :=1;--�ж��Ƿ��е�������
 v_sale_data_id busi_sale_data.id%type;--����������ʱ��ID
 v_investor_name busi_sale_data.investor_name%type;--Ͷ��������
 v_amount busi_sale_data.amount%type;--�Ϲ����
 v_investor_type busi_sale_data.investor_type%type;--Ͷ��������
 v_credit_type busi_sale_data.credit_type%type;--֤������
 v_credit_no busi_sale_data.credit_no%type;--֤������
 v_handel_person busi_sale_data.handel_person%type;--����������
 v_legal_person busi_sale_data.legal_person%type;--��������
 v_bank_accunt_no busi_sale_data.bank_accunt_no%type;--�����˺�
 v_bank_account_name busi_sale_data.bank_account_name%type;--���л���
 v_open_bank_name busi_sale_data.open_bank_name%type;--����������
 v_province_name busi_sale_data.province_name%type;--ʡ��
 v_city_name busi_sale_data.city_name%type;--����
 v_product_id busi_sale_data.product_id%type;--��ƷID
 v_company_id busi_sale_data.company_id%type;--˽ļ��˾ID
 v_business_type_name busi_sale_data.business_type%type;--ҵ������
 v_apply_date busi_sale_data.apply_date%type;--ҵ������

 v_investor_type_code  varchar2(50);--Ͷ�������ͱ���
 v_credit_type_code  varchar2(50);--֤�����ͱ���
 v_kh_count integer;--�жϿͻ����Ƿ���ڴ˿ͻ�
 v_investor_detail_count integer;--�ж��Ƿ��пͻ������¼
 v_mgr_customer_count integer;--�ж��Ƿ���ڿͻ��빫˾������¼
 v_investor_credit_id varchar2(32);--�ͻ�����ID
 v_investor_detail_id varchar2(32);--�ͻ�����������ϢID
 v_mgr_customer_id varchar2(32);--�ͻ���˽ļ��˾������ID
 v_bank_card_id varchar2(32);--�����˻�ID
 v_province_id varchar2(32);--ʡ��id
 v_city_id varchar2(32);--����id
 v_order_no varchar2(32);--�������
 v_business_type varchar2(32);--ҵ������
 v_apply_no varchar(64);

 --��ѯ���쵼������������ʱ��δ��������
 cursor data_cur  is select d.id,d.investor_name,d.amount,d.investor_type,d.credit_type,d.credit_no,d.handel_person,d.legal_person,
                            d.bank_accunt_no,d.bank_account_name,d.open_bank_name,d.province_name,d.city_name,d.product_id,d.company_id,
                            d.business_type,d.apply_date
    from busi_sale_data d
   where d.status = '0'
     and d.product_id = p_productid
     and d.company_id = p_companyid
     --and d.business_type = p_businesstype
     and to_date(to_char(d.create_date,'yyyy/MM/dd'),'yyyy/MM/dd') = to_date(to_char(sysdate,'yyyy/MM/dd'),'yyyy/MM/dd')
     and d.create_date = (select max(create_date) create_date from busi_sale_data );

 --����ʼ
 begin
     --��ѯ����������ʱ�����Ƿ��Ѵ���������
     select count(*) into v_count
      from busi_sale_data d
     where d.status = '1'
       and d.product_id = p_productid
       and d.company_id = p_companyid
       --and d.business_type = p_businesstype
       and to_date(to_char(d.create_date,'yyyy/MM/dd'),'yyyy/MM/dd') = to_date(to_char(sysdate,'yyyy/MM/dd'),'yyyy/MM/dd');

     --��ѯҵ����������
     --select d.label into v_business_type_name from sys_dict d where d.type = 'sheet_business_type' and d.value = p_businesstype;
     if v_count > 0 then
        v_msg := 'ָ����Ʒ��/�Ϲ����Զ����ɹ����ݣ������ٴ����ɡ�';
        --open c_result for select p_flag as flag,'faile' as res, v_msg as msg  from dual;
        --���������Ϣ
        open c_result for select p_flag as flag,'fail' as res, v_msg as msg from dual;
        --r_flag := 'faile';
        --r_msg := v_msg;
        return;
      end if;

      --��ѯ����������ʱ�����Ƿ��ѵ�������
      select count(*) into v_hasimportdata from  busi_sale_data d
       where d.status = '0'
         and d.product_id = p_productid
         and d.company_id = p_companyid
         --and d.business_type = p_businesstype
         and to_date(to_char(d.create_date,'yyyy/MM/dd'),'yyyy/MM/dd') = to_date(to_char(sysdate,'yyyy/MM/dd'),'yyyy/MM/dd')
         and d.create_date = (select max(create_date) create_date from busi_sale_data );
       if v_hasimportdata =0 then
       v_msg :='�޵������ݣ����ȵ���';
       open c_result for select p_flag as flag,'fail' as res, v_msg as msg from dual;
        --r_flag := 'faile';
        --r_msg := v_msg;
       return;
       end if;

       --ѭ��������ʱ������
       open data_cur ;
       loop
           fetch data_cur into v_sale_data_id,v_investor_name,v_amount,v_investor_type,v_credit_type,v_credit_no,v_handel_person,v_legal_person,v_bank_accunt_no,v_bank_account_name,
                               v_open_bank_name,v_province_name,v_city_name,v_product_id,v_company_id,v_business_type_name,v_apply_date;
           --�����ݾ��˳�����ѭ��
           if data_cur%notfound then
              v_msg :='û�е�������';
              open c_result for select p_flag as flag,'fail' as res, v_msg as msg from dual;
              exit;
           end if;

           --��ѯ�˿ͻ��Ƿ񿪻�������֤�����ͺ�֤�������ѯ
           select d.value into v_investor_type_code from sys_dict d where d.type = 'investor_user_type' and trim(d.label) = trim(v_investor_type);
           select d.value into v_credit_type_code from sys_dict d where d.type = 'credit_type' and trim(d.label) = trim(v_credit_type);
           select count(*) into v_kh_count  from busi_investor_credit c where c.credit_type = v_credit_type_code and c.credit_no = v_credit_no and c.is_delete = 0;

           --1.������¿ͻ�,���˺�
           if v_kh_count=0 then
            select sys_guid() into v_investor_credit_id from dual;

            --����ͻ�֤����
            insert into busi_investor_credit
              (ID,
               CREDIT_TYPE,
               CREDIT_NO,
               USER_TYPE,
               NAME,
               CREATE_BY,
               CREATE_DATE
              ) values (v_investor_credit_id,v_credit_type_code,v_credit_no,v_investor_type_code,v_investor_name,p_create_user,sysdate);

               --����ͻ����������
               select sys_guid() into v_investor_detail_id from dual;
               insert into busi_investor_detail
                (ID,
                 COMPANY_ID,
                 CREDIT_ID,
                 CREDIT_TYPE,
                 CREDIT_NO,
                 NAME,
                 INVESTOR_TYPE,
                 LEGAL_PERSON,
                 HANDLE_PERSON,
                 CREATE_BY,
                 CREATE_DATE
                )
                values
                (v_investor_detail_id,p_companyid,v_investor_credit_id,v_credit_type_code,v_credit_no,v_investor_name,v_investor_type_code,
                 v_legal_person,v_handel_person,p_create_user,sysdate
                );

               --����ͻ���˽ļ��˾������
               select sys_guid() into v_mgr_customer_id from dual;

               insert into busi_mgr_customer(
                  ID,
                  COMPANY_ID,
                  CREDIT_ID
                ) values (
                  v_mgr_customer_id,
                  p_companyid,
                  v_investor_credit_id
                );

            end if;

           --2.�ɿͻ�
           if v_kh_count >0 then
            select c.id into v_investor_credit_id  from busi_investor_credit c where c.credit_type = v_credit_type_code and c.credit_no = v_credit_no and c.is_delete = 0;
            select count(*) into v_investor_detail_count from busi_investor_detail d where d.credit_type = v_credit_type_code and d.credit_no = v_credit_no and d.company_id = p_companyid;

            --û�пͻ����飬�Ͳ���
              if v_investor_detail_count =0 then
                select sys_guid() into v_investor_detail_id from dual;
                select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
                 insert into busi_investor_detail
                  (ID,
                   COMPANY_ID,
                   CREDIT_ID,
                   CREDIT_TYPE,
                   CREDIT_NO,
                   NAME,
                   INVESTOR_TYPE,
                   LEGAL_PERSON,
                   HANDLE_PERSON,
                   APPLY_NO,
                   CREATE_BY,
                   CREATE_DATE
                  )
                  values
                  (v_investor_detail_id,p_companyid,v_investor_credit_id,v_credit_type_code,v_credit_no,v_investor_name,v_investor_type_code,
                   v_legal_person,v_handel_person,v_apply_no,p_create_user,sysdate
                  );

               select count(*) into v_mgr_customer_count from busi_mgr_customer c where c.company_id = p_companyid and c.credit_id = v_investor_credit_id;
               --��������˾
               if v_mgr_customer_count = 0 then
                 select sys_guid() into v_mgr_customer_id from dual;

                 insert into busi_mgr_customer(
                    ID,
                    COMPANY_ID,
                    CREDIT_ID
                  ) values (
                    v_mgr_customer_id,
                    p_companyid,
                    v_investor_credit_id
                  );
               end if;
              else
                  select d.id into v_investor_detail_id from busi_investor_detail d where d.credit_type = v_credit_type_code and d.credit_no = v_credit_no and d.company_id = p_companyid;
              end if;
            end if;

           --���������˺���Ϣ
           select sys_guid() into v_bank_card_id from dual;
           select r.id into v_province_id from busi_region r where r.name like v_province_name||'%' and r.parent_id is null;
           select r.id into v_city_id from busi_region r where r.name like v_city_name||'%' and r.parent_id is not null;

           insert into busi_bind_bank_card(
              ID,
              CREDIT_ID,
              PRODUCT_ID,
              COMPANY_ID,
              USER_NAME,
              ACCOUNT_NO,
              OPEN_BANK_NAME,
              PROVINCE_ID,
              PROVINCE_NAME,
              CITY_ID,
              CITY_NAME,
              BIND_DATE,
              IS_EXAMINE
            ) values (
              v_bank_card_id,
              v_investor_credit_id,
              p_productid,
              p_companyid,
              v_bank_account_name,
              v_bank_accunt_no,
              v_open_bank_name,
              v_province_id,
              v_province_name,
              v_city_id,
              v_city_name,
              sysdate,
              '1'
            );

           --���붩������
           --���ɶ������
            select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_order_no from dual;
           select d.value into v_business_type from sys_dict d where d.type = 'sheet_business_type' and d.label = v_business_type_name;

           insert into BUSI_SHEET(
              ID,
              SHEET_NO,
              PT_ID,
              DT_ID,
              CREDIT_ID,
              COMPANY_ID,
              BANK_CARD_ID,
              SHEET_CREATE_TIME,
              APPLY_AMOUNT,
              MANAGER_CONTRACT_STATUS,
              INVESTOR_CONTRACT_STATUS,
              TRUSTEE_CONTRACT_STATUS,
              FUND_IS_RECEIVE,
              STATUS,
              MANAGER_FUND_CONFIRM,
              BUSINESS_TYPE,
              CREATE_BY,
              CREATE_DATE
            ) values (
              sys_guid(),
              v_order_no,
              p_productid,
              v_investor_detail_id,
              v_investor_credit_id,
              p_companyid,
              v_bank_card_id,
              v_apply_date,
              v_amount,
              '1',
              '1',
              '1',
              '1',
              '1',
              '1',
              v_business_type,
              p_create_user,
              sysdate
            );

            --�ı䵼������������ʱ���״̬Ϊ�Ѵ���v_sale_data_id
            update busi_sale_data d set d.status = '1' where d.id = v_sale_data_id;

       end loop;
     close data_cur;
     v_msg :='�������ݳɹ�';
     open c_result for select p_flag as flag,'success' as res, v_msg as msg from dual;
     commit;


        --r_flag := 'faile';
        --r_msg := v_msg;
end sale_data_order;
/


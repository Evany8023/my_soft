create or replace procedure smzj.tgyw_unit_sheet_perfomance(p_apply_date in varchar2, --��������
                                            p_cp_id  in varchar2, -- ��˾ID
                                            p_pt_id in varchar2, --��ƷID
                                            p_credit_id in varchar2,--֤��id
                                            p_credit_type in varchar2, -- ֤������
                                            p_credit_no in varchar2,  --֤������
                                            p_name in varchar2, --�ͻ�����
                                            p_user_type in varchar2, --Ͷ�����û�����
                                            p_zip_code in varchar2, --��������
                                            p_address in varchar2, --ͨѶ��ַ
                                            p_telephone in varchar2, --��ϵ�绰
                                            p_phone in varchar2, --�ֻ�����
                                            p_email in varchar2, --����
                                            p_link_man in varchar2, --��ϵ������
                                            p_handel_person in varchar2, --������
                                            p_legal_person in varchar2, --���˴���
                                            p_dt_remark in varchar2, --������ע

                                            p_is_new_credit in varchar2, --�Ƿ���֤����1���ǣ�0����


                                            p_is_new_bank_card in varchar2, --�Ƿ��������˻���1���ǣ�0����
                                            p_bank_card_id in varchar2, -- ���п�ID
                                            p_bank_no in out varchar2, --���б��
                                            p_bank_name in varchar2, --��������
                                            p_link_bank_no in varchar2, --���к�
                                            p_account_no in out varchar2, --�����˺�
                                            p_account_name in varchar2, --���л���
                                            p_open_bank_name in varchar2, --����������
                                            p_province_id in varchar2, --ʡ��ID
                                            p_province_name in varchar2, -- ʡ������
                                            p_city_id in varchar2, --����ID
                                            p_city_name in varchar2, --��������
                                            p_is_back_account in  varchar2, --�Ƿ���طֺ��˺�
                                            p_bank_card_remark in varchar2, --���п���ע

                                            p_sheet_busi_type in varchar2, -- ����ҵ������
                                            p_amount in varchar2, --�������
                                            p_sheet_remark in varchar2, -- ������ע

                                            p_create_by in varchar2, --������
                                            c_result out sys_refcursor) is
---- *************************************************************************
-- SUBSYS:     �йܷ���
-- PROGRAM:      tgyw_unit_sheet
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       liujian
-- DESCRIPTION:
--                 �����˵���¼����/�깺����
-- CREATE DATE:  2015-10-30
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
 v_job_name varchar2(100) :='tgyw_unit_sheet';
 v_msg varchar2(1000); --������Ϣ
 v_is_sheet char(1); --��˾�Ƿ�ֹͣ¼��
 v_credit_id varchar2(32); --֤��ID
 v_detail_id varchar2(32); --����ID
 v_bank_card_id varchar(32); --���п�ID
 v_credit_no  varchar(32); -- ����֤������
 v_fundcomp_count number;


 v_name busi_investor_credit.name%type; --Ͷ��������
 v_credit_count number; --�ж�֤���Ƿ����
 v_detail_count number; --�ж��Ƿ񿪻�
 v_apply_no busi_investor_detail.apply_no%type; --�������뵥��

 v_bank_card_count number; --�ͻ����п��������ж��Ƿ���ӹ����п�
 v_is_back_account number; --�ж��Ƿ���طֺ��˻�
 v_same_bank_count number; --�ж����п��Ƿ��ظ�

 v_start_price busi_product.start_price%type; --���깺���
 v_plus_start_price busi_product.plus_start_price%type;  --׷���깺���
 v_is_limit_buy busi_product.is_limit_buy%type; --���깺�Ƿ�������
 v_buy_count number; --�������
 v_trade_count number; --�������
  v_investor_name_ta varchar2(50 char);--taͶ��������
 v_buy_amount number; --����������
 v_limit_amount number; --���ƽ��
 v_pt_no  varchar2(16); -- ��Ʒ���
 v_flag integer :=0;--ҵ�����������Ϊ1���ع�����
 v_current_date date; --��ǰʱ��
 v_double_count integer;
 v_double_ynzh_count integer;
 v_is_back_account_value varchar2(1);
 v_son_buy_monther varchar2(200 char); --����ĸ����ֵ
 v_sheet_id varchar2(50);             --�������id
begin
     v_flag:=0;
    v_bank_card_count := 0;
    select cp.is_sheet into v_is_sheet from busi_company cp where cp.id = p_cp_id;
    if v_is_sheet = '1' then
      v_msg := '������ֹͣ¼�������Ժ��ύ����';
      open c_result for select 'faile' as res, v_msg as msg from dual;
      return;
    end if;

     if trim(p_credit_no) is not null  then
      v_credit_no:=UPPER(p_credit_no);
    end if;

       begin
             select t.name into v_investor_name_ta  from busi_investor_credit t where  t.credit_type= p_credit_type and t.credit_no = p_credit_no and t.is_delete='0';
        exception
            when others then
            v_investor_name_ta :='';
        end;

        if v_investor_name_ta is not null and v_investor_name_ta <> p_name then
             v_flag :=1;
             v_msg := v_msg||'֤������('|| p_credit_no||')��Ӧ��Ͷ��������('|| p_name ||')��ƽ̨('||v_investor_name_ta||')��ƥ��,��ȷ�Ͽͻ�������֤������;<br>';
             open c_result for select 'faile' as res, v_msg as msg from dual;
              return;
        end if ;


   select to_date(p_apply_date||to_char(sysdate,'HH24:MI:SS'),'yyyy-mm-ddHH24:MI:SS') into v_current_date from dual;
 --�����ͻ�
    if p_is_new_credit = '1' then
                  select count(1) into v_credit_count from busi_investor_credit cr where cr.credit_type = p_credit_type and cr.credit_no = p_credit_no;
                   --�������֤���������ű�
                  if v_credit_count = 0 then
                        select sys_guid() into v_credit_id from dual;
                        select sys_guid() into v_detail_id from dual;
                        v_name:=p_name;
                        insert into busi_investor_credit(id,credit_type,credit_no,name,user_type,password, create_by,create_date,is_examine,is_active,is_delete)
                        values
                       (v_credit_id,p_credit_type,p_credit_no,p_name,p_user_type,md5(substr(p_credit_no,length(p_credit_no)-6+1,6)),p_create_by,sysdate,'1','0','0');

                       --�������뵥��
                       select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
                       insert into busi_investor_detail(id,investor_type,HANDLE_PERSON,legal_person,link_man,name,create_by,busi_type,company_id,apply_no,create_date,credit_id,credit_type,credit_no,MANAGE_FEE_MARK,ACHIEVE_FEE_MARK,ZIP_CODE,ADDRESS,TELEPHONE,PHONE,EMAIL,REMARK,is_delete,pt_id)
                             values(v_detail_id,p_user_type,p_handel_person,p_legal_person,p_link_man, p_name,p_create_by,'001',p_cp_id,v_apply_no,v_current_date,v_credit_id,p_credit_type,p_credit_no,'��','��',p_zip_code,p_address,p_telephone,p_phone,p_email,p_dt_remark,'0',p_pt_id);
                         --��������˾
                       insert into BUSI_CREDIT_COMPANY (credit_id,company_id,Sqrq,Ismustsetpass,Is_Active) values(v_credit_id,p_cp_id,v_current_date,1,0);
                  else
                      --���֤���Ѿ����ڣ����֤��ID������
                      select cr.id,cr.name,cr.credit_no into v_credit_id, v_name,v_credit_no from busi_investor_credit cr where cr.credit_type = p_credit_type and cr.credit_no = p_credit_no and rownum=1;
                          --֤������ʱ�ж������Ƿ���ͬ

                     select count(1) into v_detail_count from busi_investor_detail dt where dt.credit_id = v_credit_id and dt.company_id = p_cp_id  and dt.is_delete='0';
                          --�ͻ����ƶԵ���ʱ���ж��Ƿ��Ѿ�������
                     if v_detail_count < 1 then
                          --select count(1) into v_detail_count from busi_investor_detail dt where dt.credit_id = v_credit_id  and dt.is_delete='0';
                          select count(*) into v_detail_count from busi_investor_credit cr where cr.id = v_credit_id  and cr.is_delete='0' and cr.regist_account is not null;
                          select sys_guid() into v_detail_id from dual;
                              --�жϿͻ��Ƿ��Ѿ���������˾����������������ҵ������Ϊ�������ͻ���008����û����Ϊ�������ͻ���001��
                          select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
                          insert into busi_investor_detail(id,investor_type,HANDLE_PERSON,legal_person,link_man,name,create_by,busi_type,company_id,apply_no,create_date,credit_id,credit_type,credit_no,MANAGE_FEE_MARK,ACHIEVE_FEE_MARK,ZIP_CODE,ADDRESS,TELEPHONE,PHONE,EMAIL,REMARK,is_delete,pt_id)
                                   values(v_detail_id,p_user_type,p_handel_person,p_legal_person,p_link_man,p_name,p_create_by,(case when v_detail_count=0 then '001' else '008' end),p_cp_id,v_apply_no,v_current_date,v_credit_id,p_credit_type,p_credit_no,'��','��',p_zip_code,p_address,p_telephone,p_phone,p_email,p_dt_remark,'0',p_pt_id);
                     else
                          v_msg := '����ӵĿͻ��Ѿ����ڣ��벻Ҫ�ظ����';
                          open c_result for select 'faile' as res, v_msg as msg from dual;
                          return;
                     end if;

                     select count(*) into v_fundcomp_count from  busi_credit_company t where t.credit_id=v_credit_id  and t.company_id=p_cp_id;
                          --��������˾
                     if v_fundcomp_count = 0 then
                             insert into busi_credit_company (credit_id,company_id,sqrq) values(v_credit_id,p_cp_id,v_current_date);
                      end if;

                       UPDATE busi_investor_credit t SET t.SOURCETYPE='0',t.is_delete='0' WHERE  id=v_credit_id;
                       UPDATE BUSI_CREDIT_COMPANY c SET c.SOURCETYPE='0',c.insti_name='ֱ��,'||c.insti_name,c.sqrq=v_current_date WHERE c.credit_id=v_credit_id AND c.company_id=p_cp_id;

                  end if;

    else --���˻�
        v_credit_id := p_credit_id;
        begin
            select dt.id into v_detail_id from busi_investor_detail dt where dt.credit_id = v_credit_id and dt.company_id = p_cp_id and is_delete='0'and rownum=1;
            select cr.credit_no,cr.name into v_credit_no,v_name from  busi_investor_credit cr where cr.id=v_credit_id;
            UPDATE busi_investor_credit t SET t.SOURCETYPE='0',t.is_delete='0' WHERE  id=v_credit_id;
        exception   when no_data_found then
            v_msg := '�ͻ�������';
            open c_result for select 'faile' as res, v_msg as msg from dual;
            return;
        end;
    end if;


     select child_buy_or_sale_prarent(v_credit_id,p_pt_id,'01',null) into v_son_buy_monther from dual;
       if v_son_buy_monther='true' then
             v_flag := '1';
            v_msg := v_msg||'Ͷ����(''' ||v_credit_no ||''')�깺�ӻ��𣬻��Զ������ӻ����깺ĸ���������ظ�¼��<br>';
       elsif v_son_buy_monther <> 'true' and  v_son_buy_monther <> 'false' then
          insert into t_fund_job_running_log (JOB_NAME,job_running_log) values ('����ĸ����',v_son_buy_monther || '    '||v_credit_id || '    '|| p_pt_id || v_current_date );
       end  if;

    select count(1) into v_is_back_account from busi_bind_bank_card bc where bc.credit_id = v_credit_id and bc.product_id = p_pt_id and bc.is_back_account = '1'  and is_delete='0';
   if v_is_back_account > 0 then
         v_is_back_account_value:='0';
      else
         v_is_back_account_value:='1';
   end if;
    --���������˻�
    if p_is_new_bank_card = '1' then
        select count(1) into v_bank_card_count from busi_bind_bank_card bc where bc.credit_id = v_credit_id and bc.product_id = p_pt_id and is_delete='0';
        select count(1) into v_same_bank_count from busi_bind_bank_card bc where bc.credit_id = v_credit_id and bc.product_id = p_pt_id and bc.account_no = p_account_no and bc.bank_no = p_bank_no and is_delete='0';
        if v_is_back_account > 0 and p_is_back_account = '1' then
            v_flag := 1;
            v_msg := '�ÿͻ��������зֺ�����˻���ͬһ�ͻ���ͬһ��Ʒֻ������һ���ֺ��˻���';
        elsif v_same_bank_count > 0 then
            v_flag := 1;
            v_msg := '���п��Ѿ����ڣ��벻Ҫ�ظ����';
        else
            select sys_guid() into v_bank_card_id from dual;
            select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
            insert into busi_bind_bank_card(id,credit_id,user_name, bank_no, bank_name,open_bank_name, province_id,province_name, city_id, city_name, account_no,product_id, company_id, apply_no, bind_date, create_date,create_by, is_back_account,link_bank_no,remark)
                         values (v_bank_card_id,v_credit_id, p_account_name,p_bank_no, p_bank_name,p_open_bank_name, p_province_id,p_province_name, p_city_id, p_city_name,p_account_no, p_pt_id, p_cp_id, v_apply_no, v_current_date, sysdate, p_create_by, p_is_back_account,p_link_bank_no,p_bank_card_remark);
        end if;
    else

       select count(1) into v_double_count from busi_bind_bank_card  where id = p_bank_card_id;
       if v_double_count > 0 then
          select account_no,bank_no,1 into p_account_no, p_bank_no,v_bank_card_count from busi_bind_bank_card  where id = p_bank_card_id;
       end if;

       --��֤���п��Ƿ����
        if v_bank_card_count = 0 then
            v_flag := 1;
            v_msg := '���ܻ�ȡ�����˺���Ϣ����ѡ���������п��µ�';
        else
            v_bank_card_count := 0;
            select count(1) into v_double_ynzh_count   from busi_bind_bank_card bc  where bc.credit_id = p_credit_id and bc.product_id = p_pt_id
            and bc.account_no = p_account_no and bc.bank_no = p_bank_no  and is_delete='0' ;
            if v_double_ynzh_count> 0 then
                 select ID,1 into v_bank_card_id,v_bank_card_count from busi_bind_bank_card bc  where bc.credit_id = p_credit_id and bc.product_id = p_pt_id
                 and bc.account_no = p_account_no and bc.bank_no = p_bank_no  and is_delete='0' and rownum=1;
            end if;

            --�ж����п��Ƿ�͵�ǰ�Ĳ�Ʒ����������о�������û�о�������һ��

            if v_bank_card_count = 0 then
                  select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
                  select sys_guid() into v_bank_card_id from dual;
                  insert into busi_bind_bank_card(id,product_id,apply_no, bind_date, create_date,create_by, credit_id,user_name, bank_no, bank_name,open_bank_name,
                     province_id,province_name, city_id, city_name, account_no,company_id, is_back_account,link_bank_no,remark,is_delete)
                  select v_bank_card_id,p_pt_id, v_apply_no, v_current_date, sysdate,p_create_by,v_credit_id,user_name,bank_no,bank_name,open_bank_name,
                     province_id,province_name, city_id, city_name, account_no, company_id, v_is_back_account_value,link_bank_no,remark,'0'  from  busi_bind_bank_card where id = p_bank_card_id;

            else

               if (p_is_back_account = '1') and v_is_back_account< 1 then
                    update busi_bind_bank_card set is_back_account='1',  update_by =p_create_by,update_date=sysdate  where id = v_bank_card_id;
               end if;
            end if;
         end if;
    end if;

    select count(1) into v_trade_count from busi_sheet t where t.credit_id=v_credit_id and t.pt_id=p_pt_id and t.business_type in('022','020')  and to_char(t.sheet_create_time,'yyyy-MM-dd') = p_apply_date  and t.is_delete='0';
      if v_trade_count>0 then
          v_flag := '1';
          v_msg := '֤�����룺'||v_credit_no||',������'||v_name||',��'||p_apply_date||'�Ѿ��Ϲ����깺���˲�Ʒ,�����ٴ�����;';
      end if;


    select pt.start_price,pt.plus_start_price, pt.is_limit_buy,product_no into v_start_price, v_plus_start_price, v_is_limit_buy,v_pt_no from busi_product pt where pt.id = p_pt_id;
     --���깺��������Ƶ�ʱ��
         if v_is_limit_buy=1 then

             --�Ϲ���ͽ��
             if p_sheet_busi_type='020' then       -- �Ϲ�
                  select count(1) into v_buy_count from busi_sheet t where t.credit_id=v_credit_id and t.pt_id=p_pt_id and t.business_type = p_sheet_busi_type and t.is_delete='0';

                  if v_start_price is null  then
                     v_start_price:='1000000';
                  end if;
                  if v_buy_count<1  then

                       select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
                       select to_number(v_start_price,'9999999999999999.9999') into v_limit_amount from dual;
                       if v_buy_amount < v_limit_amount then
                           v_flag := 1;
                           v_msg := '�Ϲ�����С�ڣ�'|| v_start_price ||'Ԫ';
                       end if;
                  else
                      v_flag := '1';
                      v_msg := '֤�����룺'||v_credit_no||',������'||v_name||',�Ѿ��Ϲ����˲�Ʒ,�������Ϲ�;';
                  end if;
             end if;

            --�깺��ͽ��
            if p_sheet_busi_type ='022' then

               if v_start_price is null  then
                     v_start_price:='1000000';
               end if;

                       select count(1) into v_buy_count from busi_sheet t where t.credit_id=v_credit_id and t.pt_id=p_pt_id  and  t.business_type in('020','022') and  t.is_delete='0';
                       --�깺���깺��׷���깺���ж�
                       if v_buy_count < 1 then
                          select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
                          select to_number(v_start_price,'9999999999999999.9999') into v_limit_amount from dual;
                          if v_buy_amount < v_limit_amount then
                            v_flag := 1;
                            v_msg := '�깺����С�ڣ�'|| v_start_price ||'Ԫ';
                          end if;
                       else
                           if v_plus_start_price is not null then
                                           select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
                                           select to_number(v_plus_start_price,'9999999999999999.9999') into v_limit_amount from dual;
                                           if v_buy_amount < v_limit_amount then
                                            v_flag := 1;
                                            v_msg := '֤�����룺'||v_credit_no||'������'||v_name||'׷���깺���ܵ���'||v_limit_amount||'Ԫ';
                                          end if;

                           end if;

                       end if;


            end if;
        end if;


    if v_flag <> 1 then
        select sys_guid()  into  v_sheet_id from dual;
        select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
        insert into busi_sheet(id,sheet_no, sheet_create_time,business_type, pt_id,pt_no, apply_amount,credit_id, BANK_CARD_ID,DT_ID,create_by,company_id,manager_contract_status,investor_contract_status,trustee_contract_status,fund_is_receive,status, manager_fund_confirm,create_date,INVESTOR_MESSAGE,is_delete)
              values (v_sheet_id,v_apply_no,v_current_date,p_sheet_busi_type,p_pt_id,v_pt_no,p_amount,v_credit_id,v_bank_card_id, v_detail_id, p_create_by,p_cp_id, '1','1', '1','1','1','1', sysdate,p_sheet_remark,'0');
    end if;

     if v_flag = 1 then
        rollback;
        open c_result for select 'faile' as res, v_msg as msg  from dual;
    else
        v_msg := '��Ӷ����ɹ�';
        open c_result for select 'success' as res, v_msg as msg,v_sheet_id as sheetid  from dual;
        commit;
    end if;
    return;

    exception
        when others then
        begin
            rollback;
            DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
            DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
            v_msg:= sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace() || v_start_price || p_pt_id;
            insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
            open c_result for select v_job_name as flag, 'faile' as res, v_msg as msg from dual;
            commit;
            return;
        end ;
end tgyw_unit_sheet_perfomance;
/


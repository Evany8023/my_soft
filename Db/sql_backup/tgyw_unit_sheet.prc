create or replace procedure smzj.tgyw_unit_sheet(p_apply_date in varchar2, --��������
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
 v_credit_no busi_investor_credit.credit_no%type; --֤������

 v_name busi_investor_credit.name%type; --Ͷ��������
 v_credit_count number; --�ж�֤���Ƿ����
 v_detail_count number; --�ж��Ƿ񿪻�
 v_apply_no busi_investor_detail.apply_no%type; --�������뵥��
 
 v_bank_card_count number; --�ͻ����п��������ж��Ƿ���ӹ����п�
 v_is_back_account number; --�ж��Ƿ���طֺ��˻�
 v_same_bank_count number; --�ж����п��Ƿ��ظ�
 
 v_start_price busi_product.start_price%type; --���깺���
 v_is_limit_buy busi_product.is_limit_buy%type; --���깺�Ƿ�������
 v_buy_count number; --�������
 
 v_buy_amount number; --����������
 v_limit_amount number; --���ƽ��
 v_pt_no  varchar2(16); -- ��Ʒ���
 v_flag integer :=0;--ҵ�����������Ϊ1���ع�����
 v_current_date date; --��ǰʱ��
 
begin
    select cp.is_sheet into v_is_sheet from busi_company cp where cp.id = p_cp_id;   
    if v_is_sheet = '1' then
      v_msg := '������ֹͣ¼�������Ժ��ύ����';
      open c_result for select 'faile' as res, v_msg as msg from dual;
      return;
    end if;  
   select to_date(p_apply_date||to_char(sysdate,'HH24:MI:SS'),'yyyy-mm-ddHH24:MI:SS') into v_current_date from dual;
 --�����ͻ�
    if p_is_new_credit = '1' then
        select count(1) into v_credit_count from busi_investor_credit cr where cr.credit_type = p_credit_type and cr.credit_no = p_credit_no;
         --�������֤���������ű�
        if v_credit_count = 0 then
             select sys_guid() into v_credit_id from dual;
             select sys_guid() into v_detail_id from dual;
             insert into busi_investor_credit(id,credit_type,credit_no,name,user_type,password, create_by,create_date,is_examine,is_active) values 
                    (v_credit_id,p_credit_type,p_credit_no,p_name,p_user_type,md5(substr(p_credit_no,length(p_credit_no)-6+1,6)),p_create_by,sysdate,'1','0');         
             --�������뵥��
             select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
             insert into busi_investor_detail(id,investor_type,HANDLE_PERSON,legal_person,link_man,name,create_by,busi_type,company_id,apply_no,create_date,credit_id,credit_type,credit_no,MANAGE_FEE_MARK,ACHIEVE_FEE_MARK,ZIP_CODE,ADDRESS,TELEPHONE,PHONE,EMAIL,REMARK,is_delete,pt_id)
                   values(v_detail_id,p_user_type,p_handel_person,p_legal_person,p_link_man, p_name,p_create_by,'001',p_cp_id,v_apply_no,v_current_date,v_credit_id,p_credit_type,p_credit_no,'��','��',p_zip_code,p_address,p_telephone,p_phone,p_email,p_dt_remark,'0',p_pt_id);
               --��������˾
             insert into BUSI_CREDIT_COMPANY (credit_id,company_id) values(v_credit_id,p_cp_id);           
        else
             --���֤���Ѿ����ڣ����֤��ID������
            select cr.id,cr.name into v_credit_id, v_name from busi_investor_credit cr where cr.credit_type = p_credit_type and cr.credit_no = p_credit_no;
             --֤������ʱ�ж������Ƿ���ͬ
            if p_name = v_name then
                select count(1) into v_detail_count from busi_investor_detail dt where dt.credit_id = v_credit_id and dt.company_id = p_cp_id  and dt.is_delete='0';
                --�ͻ����ƶԵ���ʱ���ж��Ƿ��Ѿ�������
                if v_detail_count = 0 then
                    select count(1) into v_detail_count from busi_investor_detail dt where dt.credit_id = v_credit_id  and dt.is_delete='0';
                    select sys_guid() into v_detail_id from dual;
                    --�жϿͻ��Ƿ��Ѿ���������˾����������������ҵ������Ϊ�������ͻ���008����û����Ϊ�������ͻ���001��
                    insert into busi_investor_detail(id,investor_type,HANDLE_PERSON,legal_person,link_man,name,create_by,busi_type,company_id,apply_no,create_date,credit_id,credit_type,credit_no,MANAGE_FEE_MARK,ACHIEVE_FEE_MARK,ZIP_CODE,ADDRESS,TELEPHONE,PHONE,EMAIL,REMARK,is_delete,pt_id)
                         values(v_detail_id,p_user_type,p_handel_person,p_legal_person,p_link_man,p_name,p_create_by,(case when v_detail_count=0 then '001' else '008' end),p_cp_id,v_apply_no,v_current_date,v_credit_id,p_credit_type,p_credit_no,'��','��',p_zip_code,p_address,p_telephone,p_phone,p_email,p_dt_remark,'0',p_pt_id);
                else
                    v_msg := '����ӵĿͻ��Ѿ����ڣ��벻Ҫ�ظ����';
                    open c_result for select 'faile' as res, v_msg as msg from dual;
                    return;
                end if;
            else
                v_msg := '�ͻ�������֤����ƥ��';
                open c_result for select 'faile' as res, v_msg as msg from dual;
                return;
            end if;
        end if;
      
    else --���˻�
        v_credit_id := p_credit_id;
        begin
            select dt.id into v_detail_id from busi_investor_detail dt where dt.credit_id = v_credit_id and dt.company_id = p_cp_id and is_delete='0'; 
        exception   when no_data_found then 
            v_msg := '�ͻ�������';
            open c_result for select 'faile' as res, v_msg as msg from dual;
            return;        
        end;
    end if;
         
    --���������˻�
    if p_is_new_bank_card = '1' then
        select count(1) into v_bank_card_count from busi_bind_bank_card bc where bc.credit_id = p_credit_id and bc.product_id = p_pt_id and is_delete='0';
        select count(1) into v_is_back_account from busi_bind_bank_card bc where bc.credit_id = p_credit_id and bc.product_id = p_pt_id and bc.is_back_account = '1'  and is_delete='0';
        select count(1) into v_same_bank_count from busi_bind_bank_card bc where bc.credit_id = p_credit_id and bc.product_id = p_pt_id and bc.account_no = p_account_no and bc.bank_no = p_bank_no and is_delete='0';
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
        begin
            select account_no,bank_no,1 into p_account_no, p_bank_no,v_bank_card_count from busi_bind_bank_card  where id = p_bank_card_id;
            exception   when no_data_found then
               v_bank_card_count := 0;    
        end;
       --��֤���п��Ƿ����
        if v_bank_card_count = 0 then 
            v_flag := 1;
            v_msg := '���ܻ�ȡ�����˺���Ϣ����ѡ���������п��µ�';
        else
            begin
                select ID,1 into v_bank_card_id,v_bank_card_count from busi_bind_bank_card bc  where bc.credit_id = p_credit_id and bc.product_id = p_pt_id
                  and bc.account_no = p_account_no and bc.bank_no = p_bank_no  and is_delete='0' and rownum=1;        
                exception   when no_data_found then
                v_bank_card_count := 0;  
            end;         
            --�ж����п��Ƿ�͵�ǰ�Ĳ�Ʒ����������о�������û�о�������һ��
            if v_bank_card_count = 0 then
                  select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
                  select sys_guid() into v_bank_card_id from dual;
                  insert into busi_bind_bank_card(id,product_id,apply_no, bind_date, create_date,create_by, credit_id,user_name, bank_no, bank_name,open_bank_name,
                     province_id,province_name, city_id, city_name, account_no,company_id, is_back_account,link_bank_no,remark,is_delete) 
                  select v_bank_card_id,p_pt_id, v_apply_no,v_current_date, sysdate,p_create_by,credit_id,user_name,bank_no,bank_name,open_bank_name,
                     province_id,province_name, city_id, city_name, account_no, company_id, '1',link_bank_no,remark,'0'  from  busi_bind_bank_card where id = p_bank_card_id;          
            --  else   v_bank_card_id := p_bank_card_id;
            else
               if (p_is_back_account = '1') then
                    update busi_bind_bank_card set is_back_account= p_is_back_account,update_by =p_create_by,update_date=sysdate  where id = v_bank_card_id;
               end if;               
            end if;       
         end if;
    end if;
    
    select count(1) into v_buy_count from busi_sheet t where t.credit_id=v_credit_id and t.pt_id=p_pt_id and t.business_type = p_sheet_busi_type  and to_char(t.sheet_create_time,'yyyy-MM-dd') = p_apply_date  and t.is_delete='0' ;
    if v_buy_count = 0 then
        select pt.start_price, pt.is_limit_buy,product_no into v_start_price, v_is_limit_buy,v_pt_no from busi_product pt where pt.id = p_pt_id;
        if v_is_limit_buy = '1' then
           if v_start_price is null  then
             v_start_price:='1000000';
            end if;  
        
            select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
            select to_number(v_start_price,'9999999999999999.9999') into v_limit_amount from dual;         
            if v_buy_amount < v_limit_amount then
                v_flag := 1;
                v_msg := '�������С�ڣ�'|| v_start_price ||'Ԫ';
            end if;
        end if;
    else
        v_flag := 1;
        if p_is_new_credit = '1' then
            v_credit_no := p_credit_no;
            v_name := p_name;
        else 
            select cr.credit_no, cr.name into v_credit_no, v_name from busi_investor_credit cr where cr.id = p_credit_id;
        end if;
        v_msg := '֤�����룺'||v_credit_no||',������'||v_name||',�Ѿ��ڡ�'||p_apply_date|| '�����깺���˲�Ʒ,����Ҫ����¼��;';
    end if;
    
    if v_flag <> 1 then
        select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
        insert into busi_sheet(id,sheet_no, sheet_create_time,business_type, pt_id,pt_no, apply_amount,credit_id, BANK_CARD_ID,DT_ID,create_by,company_id,manager_contract_status,investor_contract_status,trustee_contract_status,fund_is_receive,status, manager_fund_confirm,create_date,INVESTOR_MESSAGE,is_delete) 
              values (sys_guid(),v_apply_no,v_current_date,p_sheet_busi_type,p_pt_id,v_pt_no,p_amount,v_credit_id,v_bank_card_id, v_detail_id, p_create_by,p_cp_id, '1','1', '1','1','1','1', sysdate,p_sheet_remark,'0');
    end if;
    
    if v_flag = 1 then
        rollback;
        open c_result for select 'faile' as res, v_msg as msg  from dual;    
    else
        v_msg := '��Ӷ����ɹ�';
        open c_result for select 'success' as res, v_msg as msg  from dual;
        commit;
    end if;
    return;
    
    exception 
        when others then
        begin
            rollback;
            DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
            DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
            v_msg:= sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace()  || p_pt_id; 
            insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
            open c_result for select v_job_name as flag, 'faile' as res, v_msg as msg from dual;
            commit;      
            return;                
        end ;            
end tgyw_unit_sheet;
/


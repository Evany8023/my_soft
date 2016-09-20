create or replace procedure smzj.tgyw_rsg_sheet_new_simple(
                                                      p_batch_number_id in varchar2,
                                                      p_company_id in varchar2,
                                                      p_product_id in varchar2,
                                                      p_create_date   in varchar2,
                                                      p_create_by in varchar2,
                                                      p_is_mgr in varchar2,
                                                      p_mgr_id in varchar2,
                                                      c_result out sys_refcursor) is

---- *************************************************************************
-- SUBSYS:     �йܷ���
-- PROGRAM:      tgyw_rsg_sheet_new_simple
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       guxu
-- DESCRIPTION:  ����������/�깺����(ȥ�����˻���)
-- CREATE DATE:  2016-4-11
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

  v_job_name varchar2(100) :='tgyw_rsg_sheet_new_simple';
  v_count integer;--��¼�Ѿ�������������
  v_limit_count integer;--��¼��Ʒ�Ƿ�������
  v_trade_count integer;--��¼�Ѿ�������������
  v_tody_time  varchar2(10 char);

  v_kh_count integer; --�Ƿ���ڿͻ���t_fund_cust��
  v_khsq_count integer; --�Ƿ���ڿͻ���t_fund_khsq��
  v_fundcomp_count integer;--�Ƿ��������˾
  v_msg varchar2(6000 char);--������Ϣ
  v_flag integer :=0;--��־����֤�������Ӧ��������TA�������Ƿ�һ��

  v_legal_person busi_sale_data.legal_person %type;--���˴�������
  v_handel_person busi_sale_data.handel_person%type;--����������

  v_rgje busi_sale_data.amount%type;--�Ϲ����

  v_investor_type busi_sale_data.investor_type%type;--���˻���
  v_user_type CHAR(1);

  v_credit_no busi_sale_data.credit_no%type;--֤������

  v_investor_name busi_sale_data.investor_name%type;--Ͷ��������
  v_tab_id busi_sale_data.id%type;--��ʱ��id

  v_credit_id busi_investor_credit.id%type; --֤��ID
  v_khsqid busi_investor_detail.id%type;--���������ID
  v_table_id varchar2(32) ;--��ID
  v_publish_status busi_product.publish_status%type;--����״̬
  v_busi_type varchar2(50);--�Ϲ�����
  v_is_limit_buy  busi_product.is_limit_buy%type;
  v_product_no varchar2(50);--�������
  v_apply_no busi_sheet.sheet_no%type;--���뵥��
  v_busi_type_code varchar2(30);--ҵ������
  v_custom_no varchar2(50 char);--�ͻ����
  v_product_name  varchar2(80 char); -- ��Ʒ����
  v_hasimportdata integer :=1;--�ж��Ƿ��е�������
 -- v_ex_rgje varchar2(50 char)  ;--�������10000��
  v_investor_name_ta varchar2(50 char);--taͶ��������
  v_rg_je_ta  varchar2(50 char); --ta��ͽ�� �ַ���
  v_sh_je_ta varchar2(50 char); --ta��ͽ�� �ַ���
  v_rsh_je_ta varchar2(50 char); --ta��ͽ�� �ַ���
  v_rgje_ta number; --ta�Ϲ����
  v_sg_rgje_ta number; --ta�Ϲ����
  v_rgje_number number; --�Ϲ���� number��ʽ

  v_credit_type_code  varchar2(50);--֤�����ͱ���
  v_pt_status_count number; --�Ƿ��л��𿪷���
  v_start_price  VARCHAR2(128); --���깺���
  v_current_date date; --��ǰʱ��
  v_buy_count number; --�������
  v_son_buy_monther varchar2(50 char); --����ĸ����ֵ
  v_product_id varchar2(50);--��Ʒid
  v_apply_date varchar2(50);--����ʱ��
  v_sql_data   varchar2(2014);
  v_sql_check   varchar2(2014);
  type myrefcur is ref cursor;
  data_cur myrefcur;
  data_cur_check myrefcur;
  v_same_apply_date_count integer;--��¼ͬһ��������¼��
  v_same_apply_date_str varchar2(2014);--��¼��������
  v_credit_company_count integer;--�û��͹�˾��ϵ��¼��

begin
  v_flag:=0;
    select count(*) into v_count from busi_sale_data t  where t.status = 1  and t.company_id = p_company_id and to_char(t.create_date, 'yyyy-MM-dd') = p_create_date and bank_no is null;
    if v_count > 0 then
        v_msg := '����'||p_create_date||'���Զ����ɹ����ݣ������ٴ����ɡ�';
         open c_result for select v_job_name as flag,'faile' as res, v_msg as msg from dual;
        return;
    end if;
   
  if p_product_id is not null and p_product_id!='-1' then
   --��ѯ�������е����������Ƿ���ȷ������
   select count(*) into v_same_apply_date_count from busi_sale_data t1 where exists (select to_char(t2.apply_date,'yyyy-MM-dd') from busi_sale_data t2 where t2.product_id=p_product_id and t2.batch_number_id = p_batch_number_id and t1.status=1 and to_char(t1.apply_date,'yyyy-MM-dd') = to_char(t2.apply_date,'yyyy-MM-dd') and t1.product_id=t2.product_id and t1.bank_no is null group by to_char(t2.apply_date,'yyyy-MM-dd'));
   if v_same_apply_date_count >0 then
     select wmsys.wm_concat(tb.apply_date) into v_same_apply_date_str from (select distinct to_char(t1.apply_date,'yyyy-MM-dd') apply_date from busi_sale_data t1 where exists (select to_char(t2.apply_date,'yyyy-MM-dd') from busi_sale_data t2  where t2.product_id=p_product_id and t2.batch_number_id = p_batch_number_id and t1.status=1 and to_char(t1.apply_date,'yyyy-MM-dd') = to_char(t2.apply_date,'yyyy-MM-dd') and t1.product_id=t2.product_id and t1.bank_no is null group by to_char(t2.apply_date,'yyyy-MM-dd'))) tb;
     v_msg := '���������д�����������'||v_same_apply_date_str||'���Զ����ɹ����ݣ������ٴ����ɡ�';
     open c_result for select v_job_name as flag,'faile' as res, v_msg as msg from dual;
     return;
   end if;
  
    select count(*) into v_hasimportdata from busi_sale_data t  where t.status = 0  and t.company_id = p_company_id  and t.batch_number_id = p_batch_number_id and t.product_id = p_product_id and  to_char(t.create_date, 'yyyy-MM-dd') = p_create_date;
  else
   --��ѯ�������е����������Ƿ���ȷ������
   select count(*) into v_same_apply_date_count from busi_sale_data t1 where exists (select to_char(t2.apply_date,'yyyy-MM-dd') from busi_sale_data t2 where t2.batch_number_id = p_batch_number_id  and t1.status=1 and to_char(t1.apply_date,'yyyy-MM-dd') = to_char(t2.apply_date,'yyyy-MM-dd') and t1.product_id=t2.product_id and t1.bank_no is null group by to_char(t2.apply_date,'yyyy-MM-dd'));
   if v_same_apply_date_count >0 then
     select wmsys.wm_concat(tb.apply_date) into v_same_apply_date_str from (select distinct to_char(t1.apply_date,'yyyy-MM-dd') apply_date from busi_sale_data t1 where exists (select to_char(t2.apply_date,'yyyy-MM-dd') from busi_sale_data t2  where t2.batch_number_id = p_batch_number_id and t1.status=1 and to_char(t1.apply_date,'yyyy-MM-dd') = to_char(t2.apply_date,'yyyy-MM-dd') and t1.product_id=t2.product_id and t1.bank_no is null group by to_char(t2.apply_date,'yyyy-MM-dd'))) tb;
     v_msg := '�����������д�����������'||v_same_apply_date_str||'���Զ����ɹ����ݣ������ٴ����ɡ�';
     open c_result for select v_job_name as flag,'faile' as res, v_msg as msg from dual;
     return;
   end if;
    
    select count(*) into v_hasimportdata from busi_sale_data t  where t.status = 0  and t.company_id = p_company_id  and t.batch_number_id = p_batch_number_id and  to_char(t.create_date, 'yyyy-MM-dd') = p_create_date;
  end if;
    if v_hasimportdata <=0 then
        v_msg :='�޵������ݣ����ȵ���';
        open c_result for select v_job_name as flag,'faile' as res, v_msg as msg from dual;
        return;
    end if;

    --������ݺϷ���
   select to_char(trunc(sysdate),'yyyy-mm-dd' ) into v_tody_time from dual;

   if p_is_mgr is not null and p_is_mgr='0' then
      v_sql_data:='select t.investor_name,t.credit_no,t.credit_type_code,t.legal_person,t.handel_person,t.amount,t.investor_type,t.id,t.product_id,
        to_char(t.apply_date,'||'''yyyy-MM-dd'''||') from busi_sale_data t join busi_product p on t.product_id=p.id join busi_product_authorization pa on p.id = pa.product_id where t.status = 0 and pa.mgr_id =''' || p_mgr_id ||''' and t.batch_number_id=''' ||p_batch_number_id || ''' and t.company_id =''' ||p_company_id || ''' and to_char(t.create_date,'||'''yyyy-MM-dd'''||') = ''' ||p_create_date || '''';
      v_sql_check:='select t.investor_name,t.credit_no,t.credit_type_code from busi_sale_data t join busi_product p on t.product_id=p.id join busi_product_authorization pa on p.id = pa.product_id where t.status = 0 and pa.mgr_id = ''' || p_mgr_id ||''' and t.batch_number_id=''' ||p_batch_number_id || ''' and t.company_id = ''' ||p_company_id || ''' and to_char(t.create_date, '||'''yyyy-MM-dd'''||') = ''' ||p_create_date || '''';
   else
      v_sql_data:='select t.investor_name,t.credit_no,t.credit_type_code,t.legal_person,t.handel_person,t.amount,t.investor_type,t.id,t.product_id,
        to_char(t.apply_date,'||'''yyyy-MM-dd'''||') from busi_sale_data t where t.status = 0 and t.batch_number_id=''' ||p_batch_number_id || ''' and t.company_id =''' ||p_company_id || ''' and to_char(t.create_date,'||'''yyyy-MM-dd'''||') = ''' ||p_create_date || '''';
      v_sql_check:='select t.investor_name,t.credit_no,t.credit_type_code from busi_sale_data t  where t.status = 0 and t.batch_number_id=''' ||p_batch_number_id || ''' and t.company_id = ''' ||p_company_id || ''' and to_char(t.create_date, '||'''yyyy-MM-dd'''||') = ''' ||p_create_date || '''';
   end if;
   if p_product_id is not null and p_product_id!='-1' then
      v_sql_check:=v_sql_check|| ' and t.product_id =''' ||p_product_id || '''';
      v_sql_data:=v_sql_data|| ' and t.product_id =''' ||p_product_id || '''';
   end if;

 open data_cur_check for v_sql_check;
    loop
        fetch data_cur_check into v_investor_name ,v_credit_no,v_credit_type_code;
        if data_cur_check%notfound then
            exit;
        end if;

        begin
             select t.name into v_investor_name_ta  from busi_investor_credit t where  t.credit_type= v_credit_type_code and t.credit_no = v_credit_no and t.is_delete='0';
        exception
            when others then
            v_investor_name_ta :='';
        end;

        if v_investor_name_ta is not null and v_investor_name_ta <> v_investor_name then
             v_flag :=1;
             v_msg := v_msg||'֤������('|| v_credit_no||')��Ӧ��Ͷ��������('|| v_investor_name ||')��ƽ̨('||v_investor_name_ta||')��ƥ��,��ȷ�Ͽͻ�������֤������;<br>';
        end if ;
    end loop;
    close data_cur_check;

    if v_flag = 1 then
        open c_result for select v_job_name as flag,'faile' as res, v_msg as msg  from dual;
        return ;
    end if ;

    --��������start
    open data_cur for v_sql_data;
    loop
        fetch data_cur into v_investor_name,v_credit_no,v_credit_type_code,v_legal_person,v_handel_person,v_rgje,v_investor_type,v_tab_id,v_product_id,v_apply_date;
        if data_cur%notfound then
          exit;
        end if;

    v_rg_je_ta:=null;
    v_sh_je_ta:=null;
    v_rsh_je_ta:=null;
    
    select to_date(v_apply_date ||to_char(sysdate,'HH24:MI:SS' ),'yyyy-MM-ddHH24:MI:SS'  ) into v_current_date from dual;
    select count(1) into v_limit_count  from zsta.fundlimit@TA_dblink t, busi_product info where info.product_no=t.fundcode and info.id=v_product_id;
    if v_limit_count > 0 then
      select minsubsamountbyindi, minbidsamountbyindi,minappbidsamountbyindi into v_rg_je_ta,v_sh_je_ta,v_rsh_je_ta from zsta.fundlimit@TA_dblink t, busi_product info where info.product_no=t.fundcode and info.id=v_product_id;
    end if;

    if trim(v_rg_je_ta) is null then
       v_rg_je_ta:='1000000';
    end if;
    if trim(v_sh_je_ta) is null then
       v_sh_je_ta:='1000000';
    end if;

        select decode(v_investor_type,'����','2','����','1') into v_user_type from dual;
        select count(*) into v_kh_count from busi_investor_credit t where t.credit_type = v_credit_type_code and t.credit_no = v_credit_no and t.is_delete='0';
        --������¿������������ű�������
        if v_kh_count=0 then
              select sys_guid() into v_credit_id from dual;
              --�ͻ���
              insert into busi_investor_credit (id,user_type,credit_type,credit_no, create_date,create_by,password,name )  --�ͻ���ţ��������Զ����ɣ�����Ҫ�ֹ���ѯ
                     values (v_credit_id,v_user_type,v_credit_type_code,v_credit_no,sysdate,p_create_by,md5(substr(v_credit_no,length(v_credit_no)-6+1,6)),v_investor_name);
              --���������
              select sys_guid() into v_khsqid from dual;
              --�������뵥��
              select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
              insert into busi_investor_detail(id,investor_type,handle_person,legal_person,name,create_by,busi_type,company_id,apply_no,create_date,credit_type,credit_id,credit_no,manage_fee_mark,achieve_fee_mark,pt_id)
                 values(v_khsqid,v_user_type,v_handel_person,v_legal_person,v_investor_name,p_create_by,'001',p_company_id,v_apply_no,v_current_date,v_credit_type_code,v_credit_id,v_credit_no,'��','��',v_product_id);
                 --��������˾
              insert into BUSI_CREDIT_COMPANY (credit_id,company_id,Sqrq,ismustsetpass,is_active) values(v_credit_id,p_company_id,v_current_date,1,0);
        end if;

        --���ڿͻ�
        if v_kh_count >0 then
            select t.id,t.custom_no into v_credit_id,v_custom_no from busi_investor_credit t where  t.credit_type = v_credit_type_code and t.credit_no = v_credit_no;
            select count(*) into v_khsq_count from busi_investor_detail t where t.credit_id=v_credit_id and t.company_id=p_company_id and t.is_delete='0';
            --δ����
            if v_khsq_count =0 then
                -- ��һ���Ƿ���������˾����
                select count(*) into v_khsq_count from busi_investor_credit cr where cr.id = v_credit_id  and cr.is_delete='0' and cr.regist_account is not null;
                select sys_guid() into v_khsqid from dual;
                select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
                -- ���뿪����¼������ ҵ������  001  ����  008 ���ӽ����˻�
                insert into busi_investor_detail(id,investor_type,handle_person,legal_person,name,create_by,busi_type,company_id,apply_no,create_date,credit_type,credit_id,credit_no,manage_fee_mark,achieve_fee_mark,pt_id)
                   values(v_khsqid,v_user_type,v_handel_person,v_legal_person,v_investor_name,p_create_by,(case when v_khsq_count>0 then '008' else '001' end),p_company_id,v_apply_no,v_current_date,v_credit_type_code,v_credit_id,v_credit_no,'��','��',v_product_id);
                select count(*) into v_fundcomp_count from  busi_credit_company t where t.credit_id=v_credit_id  and t.company_id=p_company_id;
                --��������˾
                if v_fundcomp_count = 0 then
                       insert into busi_credit_company (credit_id,company_id,sqrq) values(v_credit_id,p_company_id,v_current_date);
                 end if;

                  UPDATE busi_investor_credit t SET t.SOURCETYPE='0',t.is_delete='0' WHERE  id=v_credit_id;
                  UPDATE BUSI_CREDIT_COMPANY c SET c.SOURCETYPE='0',c.insti_name='ֱ��,'||c.insti_name,c.sqrq=v_current_date WHERE c.credit_id=v_credit_id AND c.company_id=p_company_id;
            else--2016.6.27 ��ΰ ����û���˾��ϵ
                select count(*) into v_credit_company_count from busi_credit_company where credit_id=v_credit_id and company_id=p_company_id;
                if v_credit_company_count = 0 then
                     insert into busi_credit_company (credit_id,company_id,sqrq) values(v_credit_id,p_company_id,v_current_date);
                end if;
            end if;
        end if;

        select child_buy_or_sale_prarent(v_credit_id,v_product_id,'01',null) into v_son_buy_monther from dual;

       if v_son_buy_monther='true' then
             v_flag := '1';
             v_msg := v_msg||'Ͷ����(''' ||v_credit_no ||''')�깺�ӻ��𣬻��Զ������ӻ����깺ĸ���������ظ�¼��<br>';
       elsif v_son_buy_monther <> 'true' and  v_son_buy_monther <> 'false' then
          insert into t_fund_job_running_log (JOB_NAME,job_running_log) values ('����ĸ����',v_son_buy_monther || '    '||v_credit_id || '    '|| v_product_id || v_current_date );
       end  if;

        select count(1) into v_buy_count from busi_sheet t where t.credit_id=v_credit_id and t.pt_id=v_product_id and t.business_type in('020','022')  and to_char(t.sheet_create_time,'yyyy-MM-dd')  = v_apply_date  and t.is_delete='0' ;
            if v_buy_count> 0 then
               v_flag:=1;
               v_msg := v_msg||'֤�����룺'||v_credit_no||',������'||v_investor_name||',�Ѿ��ڡ�'||v_apply_date|| '���Ϲ����깺���˲�Ʒ,����Ҫ����¼��;'||'<br>';
            end if;

        --��ѯ����״̬
        select t.publish_status,t.is_limit_buy,start_price,t.product_no,name into  v_publish_status,v_is_limit_buy,v_start_price,v_product_no,v_product_name from busi_product t  where t.id=v_product_id;
        --�����Ƿ���״̬��������Ϊ�Ϲ������ز��Ƿ���״̬����ݲ�Ʒ����������ȥTA��ѯ����״̬���Ƿ�����ȫΪ�깺
        if (v_publish_status='1' or v_publish_status='2')  then
              v_busi_type :='�Ϲ�';
              v_busi_type_code :='020';
        elsif ( v_publish_status='0'  or v_publish_status='6')  then  -- 0 �������ף�6 ��ֹͣ��أ����깺
            v_busi_type :='�깺';
            v_busi_type_code :='022';
        else
           -- select t.jjzt into v_publish_status from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm =v_product_no and t.rq=to_date(v_apply_date,'yyyy-MM-dd');
            begin
                select t.jjzt,1 into v_publish_status,v_pt_status_count from t_rlb_jjzt t where t.jjdm =v_product_no and t.rq = to_char(to_date(v_apply_date,'yyyy-MM-dd'),'yyyyMMdd');
            exception   when no_data_found then
                v_pt_status_count:=0;
            end;

            if v_pt_status_count > 0 then
                if v_publish_status='1' or v_publish_status='2' then -- 1(����) 2�����гɹ���
                     v_busi_type :='�Ϲ�';
                     v_busi_type_code :='020';
                else
                     v_busi_type :='�깺';
                     v_busi_type_code :='022';
                end if;
            else
                v_flag := '1';
                v_msg := '��Ʒ:' || v_product_name || ' ������' || v_apply_date || '������ʱ�����գ����ܵ��붩��';
            end if;

        end if;

         --���깺��������Ƶ�ʱ��
        if v_is_limit_buy=1 then
             --�Ϲ���ͽ��
            if v_busi_type_code='020' then       -- �Ϲ�
                  select count(1) into  v_trade_count  from busi_sheet  t where  t.credit_id=v_credit_id and t.pt_id = v_product_id and  t.business_type = v_busi_type_code  and t.is_delete='0';
                  if v_trade_count  <1  then
                      select to_number(replace(v_rg_je_ta,',',''),'9999999999999999.999999') into v_rgje_ta from dual;
                      select to_number(replace(v_rgje,',',''),'9999999999999999.999999')  into v_rgje_number from dual; -- �Ϲ����
                      if(v_rgje_ta>(v_rgje_number)) then
                           v_flag := '1';
                           v_msg := v_msg||'֤�����룺'||v_credit_no||'������'||v_investor_name||'�Ϲ����С������Ϲ����;<br>';
                      end if;
                  else
                      v_flag := '1';
                      v_msg := v_msg||'֤�����룺'||v_credit_no||'������'||v_investor_name||'�Ѿ��Ϲ����˲�Ʒ;<br>';
                  end if;
            end if;

            --�깺��ͽ��
            if v_busi_type_code ='022' and v_limit_count >0 then

                select to_number(replace(v_sh_je_ta,',',''),'9999999999999999.999999') into v_rgje_ta from dual;
                select to_number(replace(v_rsh_je_ta,',',''),'9999999999999999.999999') into v_sg_rgje_ta from dual;
                select to_number(replace(v_rgje,',',''),'9999999999999999.999999') into v_rgje_number from dual;

                    select count(1) into  v_trade_count  from busi_sheet  t where  t.credit_id=v_credit_id and t.pt_id = v_product_id and  t.business_type in('020','022')  and t.is_delete='0';
                    -------------------�깺��׷���깺�ж�
                    if v_trade_count >0 then
                        if(v_sg_rgje_ta>(v_rgje_number)) then
                            v_flag := '1';
                            v_msg := v_msg||'֤�����룺'||v_credit_no||'������'||v_investor_name||'׷���깺���С�����׷���깺���;<br>';
                        end if;
                    else
                        if(v_rgje_ta>(v_rgje_number)) then
                            v_flag := '1';
                            v_msg := v_msg||'֤�����룺'||v_credit_no||'������'||v_investor_name||'�깺���С������깺���;<br>';
                        end if;
                    end if;

            end if;

        end if;

        if v_flag <> 1 then
            select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;--�������뵥��
            select sys_guid() into v_table_id from dual;
            --���뽻�������busi_sheet.����ʱ����ת�������ﲻ��Ҫ��ת��
            -- select round(v_rgje*10000,6) into v_ex_rgje from dual;--�Ϲ��������10000��������6λС��

            --��ȡͶ��������id
            if(v_khsqid is null) then
                select d.id into v_khsqid from busi_investor_detail d where d.credit_id=v_credit_id and  company_id = p_company_id and  is_delete='0' and rownum=1;
            end if;

            insert into busi_sheet(id,sheet_no,sheet_create_time,business_type,pt_id,pt_no,apply_amount,credit_id,create_by,company_id,
               manager_contract_status,investor_contract_status,trustee_contract_status,fund_is_receive,status,manager_fund_confirm,create_date,bank_card_id,dt_id,is_simple
            ) values (v_table_id,v_apply_no,v_current_date,v_busi_type_code,v_product_id,v_product_no,v_rgje,v_credit_id,p_create_by,
               p_company_id, '1','1', '1',  '1', '1', '1',sysdate,'',v_khsqid,'1');

            --�Ѳ�Ʒ����������ݸ���ID�ı�״̬
            update busi_sale_data set status=1 where id = v_tab_id;
        end if;
    end loop;
    close data_cur;

    if v_flag = 1 then
        rollback;
         v_msg:= substr(v_msg,0,999);
        open c_result for select v_job_name as flag,'faile' as res, v_msg as msg  from dual;
    else
      --����ɹ���Ϣ
        v_msg :='�������ݳɹ�';
        open c_result for select v_job_name as flag,'success' as res, v_msg as msg from dual;
    end if ;

    insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
    commit;
    return ;

    exception
        when others then
        begin
            rollback;
            DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
            DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
            v_msg:=v_credit_no||':'||sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace();
            v_msg:= substr(v_msg,0,999);
            insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
            open c_result for select v_job_name as flag,'faile', v_msg as msg from dual;
            commit;
            return;
        end ;
 end tgyw_rsg_sheet_new_simple;
/


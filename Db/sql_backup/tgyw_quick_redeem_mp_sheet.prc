create or replace procedure smzj.tgyw_quick_redeem_mp_sheet (p_company_id in varchar2, --��˾ID
                                                      p_product_id in varchar2, --��ƷID
                                                      p_create_by in varchar2,  --������
                                                      p_batchid      in varchar2,  --����id
                                                      p_confirm_type  in varchar2,   --����0�Ը��������в�Ʒ����ȷ��,1:�Ե�����Ʒ����ȷ��
                                                      p_mgrid     in  varchar2,   --������id
                                                      p_ismgr     in varchar2,   --�Ƿ�һ������Ա1:һ������Ա,0:����������
                                                      c_result out sys_refcursor) is  --���ؽ��

---- *************************************************************************
-- SUBSYS:     �йܷ���
-- PROGRAM:      tgyw_quick_redeem_mp_sheet
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       ������
-- DESCRIPTION:  ���Ʒ¼���������,������������ȷ��ȫ��������

-- CREATE DATE:   2016-06-06
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

  v_job_name varchar2(100) :='tgyw_quick_redeem_mp_sheet';
  v_count integer;--��¼�Ѿ�������������
  v_ptnos varchar2(4000);--��¼�Ѿ��������ݵĲ�Ʒ����
  v_kh_count integer; --�Ƿ���ڿͻ���t_fund_cust��
  v_shfh_count integer; --�Ƿ���ڿͻ���t_fund_cust��

  v_msg varchar2(4000 char);--������Ϣ
  v_tzrlx busi_batch_redeem_tmp.investor_type_no%type;--Ͷ�������ͱ��
  v_zjlb busi_batch_redeem_tmp.credit_type%type;--֤�����
  v_djzh busi_investor_credit.regist_account%type;--֤�����
  v_zjlbcode busi_batch_redeem_tmp.credit_type_no%type;--֤������
  v_tzrxm busi_batch_redeem_tmp.investor_name%type;--Ͷ��������
  v_zjhm busi_batch_redeem_tmp.credit_no%type;--֤������
  v_id busi_batch_redeem_tmp.id%type ;--��Ʒ������id
  v_credit_id busi_investor_credit.id%type; --�ͻ�֤��ID
  v_fundcode busi_batch_redeem_tmp.product_no%type;--��Ʒ����
  v_fundid busi_batch_redeem_tmp.product_id%type;--��Ʒid
  v_comcode busi_batch_redeem_tmp.company_no%type;--��˾����
  v_hasimportdata integer :=1;--�ж��Ƿ� �е�������
  v_shfe busi_batch_redeem_tmp.redeem_share%type; --��طݶ�
  v_shfy BUSI_BATCH_QUICK_REDEEM_TMP.PROCEDURE_FEE%type; --��ط���
  v_apply_date varchar2(10);   --��������
  v_tzrxm_ta varchar2(255 char);--taͶ��������
  v_flag integer;
  v_sqdh  varchar2(50 char);--���뵥��
  v_total_feye     number(16,4);      -- �ݶ����
  v_input_total_feye     number(16,4);      -- �ݶ����
  v_bank_card_id varchar2(32);             --���п�id
  v_tzrxq_id busi_investor_detail.id%type;   --Ͷ��������id
  v_current_time VARCHAR2(128); --��ǰʱ��
  v_current_date date; --��ǰʱ��
  v_son_buy_monther varchar2(50 char); --����ĸ����ֵ

  v_curdate_str varchar2(10); --��ǰ���ڣ���ʽyyyyMMdd
  v_sql_data                   varchar2(2014);                              --���ݼ�SQL
  v_sql_check                  varchar2(2014);                              --У��SQL
  v_sql_count                   varchar2(2014);
  v_sql_count2                  varchar2(2014);

  type myrefcur is ref cursor;
  data_cur_check myrefcur;
  data_cur myrefcur;
 cursor apply_cur is select to_char(t.apply_date,'yyyyMMdd'),t.product_id from busi_batch_quick_redeem_tmp t
                    where to_char(t.apply_date,'yyyyMMdd')>=to_char(sysdate,'yyyyMMdd')
                    and t.company_id=p_company_id and t.status='1'
                    group by to_char(t.apply_date,'yyyyMMdd'),t.product_id;
begin
    --��������У��
    select to_char(sysdate,'yyyyMMdd'),sysdate into v_curdate_str,v_current_date from dual;

    v_flag:=0;
      open apply_cur;
        loop
          fetch apply_cur into v_apply_date,v_fundid;
          if apply_cur%notfound then
            exit;
          end if;
          select count(1) into v_count from busi_batch_quick_redeem_tmp t
         where t.COMPANY_ID = p_company_id and to_char(t.APPLY_DATE, 'yyyyMMdd') = v_apply_date and t.product_id=v_fundid;
         select bp.product_no into v_ptnos from busi_product bp where bp.id=v_fundid;
          if v_count>0 then
            v_flag:=1;
            v_msg := 'ָ����Ʒ'||v_ptnos||'���Զ����ɹ����ݣ������ٴ�����<br>';
          end if;
      end loop;
      close apply_cur;
      if v_flag=1 then           --���������Ϣ
            open c_result for select v_job_name as flag, 'faile' as res, v_msg as msg from dual;
            return;
      end if;
    --У�鵼���¼
    v_sql_count:='select count(1) from  busi_batch_quick_redeem_tmp t where t.COMPANY_ID = '''||p_company_id ||''' and to_char(t.APPLY_DATE,''yyyyMMdd'') >= '''||v_curdate_str||''' and t.status = 0 and t.batch_number_id='''||p_batchid||'''';
    --�����Ĳ�Ʒ
    v_sql_count2:='select count(1) from (select t.product_no from busi_batch_quick_redeem_tmp t where t.COMPANY_ID='''||p_company_id ||''' and to_char(t.APPLY_DATE,''yyyyMMdd'') >= '''||v_curdate_str||''' and t.status=0 and t.batch_number_id='''||p_batchid||'''';
    --��Ϊ��������Ա��ʱ�� ��Ҫ����������Ա��Ʒ��busi_product_authorization
    if p_isMgr=0 and p_mgrId is not null then
      v_sql_count:=v_sql_count||' and exists (select 1 from busi_product_authorization a where  a.PRODUCT_ID=t.PRODUCT_ID and a.MGR_ID='''||p_mgrId||''')';
      v_sql_count2:=v_sql_count2||' and exists (select 1 from busi_product_authorization a where  a.PRODUCT_ID=t.PRODUCT_ID and a.MGR_ID='''||p_mgrId||''')';
    end if;
    --���û�û�д���ƷID
    if p_product_id is not null then
      v_sql_count:=v_sql_count||' and t.PRODUCT_ID='''||p_product_id||'''';
      v_sql_count2:=v_sql_count2||' and t.PRODUCT_ID='''||p_product_id||'''';
    end if;
    v_sql_count2:=v_sql_count2||' group by t.CREDIT_TYPE_NO,t.CREDIT_NO,t.product_no,to_char(t.APPLY_DATE,''yyyyMMdd''))';
    execute immediate v_sql_count into v_hasimportdata;

    if v_hasimportdata =0 then
        v_msg :='�޵������ݣ����ȵ���';
        open c_result for select v_job_name as flag,'faile' as res, v_msg as msg from dual;
        return;
    end if;

    execute immediate v_sql_count2 into v_count;
    if v_hasimportdata !=v_count then
        v_msg :='����(֤������+֤�����룩�����ظ�������ȷ�����ݲ��ظ������Զ��������ݡ�';
        open c_result for select v_job_name as flag, 'faile' as res, v_msg as msg from dual;
        return;
    end if;

--    --У���Ƿ������ݵ���
--    select count(1) into v_hasimportdata from  busi_batch_quick_redeem_tmp t
--           where t.COMPANY_ID = p_company_id and to_char(t.APPLY_DATE,'yyyyMMdd') >= v_curdate_str and t.status = '0' and t.batch_number_id=p_batchid ;
--    if v_hasimportdata =0 then
--        v_msg :='�޵������ݣ����ȵ���';
--        open c_result for select v_job_name as flag, 'faile' as res, v_msg as msg from dual;
--        return;
--    end if;
--
--    select count(1) into v_count  from (select t.product_no from busi_batch_quick_redeem_tmp t
--           where t.COMPANY_ID=p_company_id and to_char(t.APPLY_DATE,'yyyyMMdd') >= v_curdate_str and t.status='0' and t.batch_number_id=p_batchid
--           group by t.CREDIT_TYPE_NO,t.CREDIT_NO,t.product_no,to_char(t.APPLY_DATE,'yyyyMMdd'));
--
--    if v_hasimportdata !=v_count then
--        v_msg :='����(֤������+֤�����룩�����ظ�������ȷ�����ݲ��ظ������Զ���������';
--        open c_result for select v_job_name as flag, 'faile' as res, v_msg as msg from dual;
--        return;
--    end if;

    if p_ismgr=1 then
      v_sql_check:='select t.INVESTOR_NAME,t.CREDIT_NO,t.CREDIT_TYPE_NO from busi_batch_quick_redeem_tmp t
            where t.batch_number_id='''||p_batchid||''' and t.COMPANY_ID = '''||p_company_id||''' and to_char(t.APPLY_DATE, '||'''yyyyMMdd'''||') >= '''||v_curdate_str||''' and t.status = 0';
      v_sql_data:='select t.investor_name,t.credit_no,t.credit_type_no,t.credit_type,t.id,t.investor_type_no,t.product_no,t.PRODUCT_ID,to_char(t.APPLY_DATE, '||'''yyyy-MM-dd'''||'),t.company_no,t.redeem_share,t.PROCEDURE_FEE from busi_batch_quick_redeem_tmp t
            where t.batch_number_id='''||p_batchid||''' and t.COMPANY_ID = '''||p_company_id||''' and to_char(t.APPLY_DATE, '||'''yyyyMMdd'''||') >= '''||v_curdate_str||''' and t.STATUS = 0';
    else
      v_sql_check:='select t.INVESTOR_NAME,t.CREDIT_NO,t.CREDIT_TYPE_NO from busi_batch_quick_redeem_tmp t join busi_product_authorization pa on t.PRODUCT_ID = pa.product_id
            where t.batch_number_id='''||p_batchid||''' and pa.mgr_id ='''||p_mgrid||''' and t.COMPANY_ID = '''||p_company_id||''' and to_char(t.APPLY_DATE, '||'''yyyyMMdd'''||') >= '''||v_curdate_str||''' and t.status = 0';
      v_sql_data:='select t.investor_name,t.credit_no,t.credit_type_no,t.credit_type,t.id,t.investor_type_no,t.product_no,t.PRODUCT_ID,to_char(t.APPLY_DATE, '||'''yyyy-MM-dd'''||'),t.company_no,t.redeem_share,t.PROCEDURE_FEE from busi_batch_quick_redeem_tmp t join busi_product_authorization pa on t.PRODUCT_ID  = pa.product_id
            where t.batch_number_id='''||p_batchid||''' and pa.mgr_id ='''||p_mgrid||''' and t.COMPANY_ID = '''||p_company_id||''' and to_char(t.APPLY_DATE, '||'''yyyyMMdd'''||') >= '''||v_curdate_str||''' and t.STATUS = 0';
    end if;
    if p_confirm_type=1 and p_product_id is not null then
      --�Ե�����Ʒ����ȷ��
      v_sql_check:=v_sql_check|| ' and t.PRODUCT_ID =''' ||p_product_id || '''';
      v_sql_data:=v_sql_data|| ' and t.PRODUCT_ID =''' ||p_product_id || '''';
    end if;

    open data_cur_check for v_sql_check;
    loop
        fetch data_cur_check into v_tzrxm ,v_zjhm,v_zjlbcode;
        if data_cur_check%notfound then
            exit;
        end if;

        begin
            select t.name into v_tzrxm_ta from busi_investor_credit t where t.credit_no = v_zjhm and t.credit_type=v_zjlbcode group by t.name;
        exception  when others then
             v_tzrxm_ta :='';
        end;

        if trim(v_tzrxm_ta) <> trim(v_tzrxm) then
            v_flag :=1;
            v_msg := v_msg||'֤������('|| v_zjhm||')��Ӧ��Ͷ��������('|| v_tzrxm ||')��ƽ̨('||v_tzrxm_ta||')��ƥ��<br>';
        end if ;
    end loop;
     close data_cur_check;

    select to_char(sysdate,'HH24:MI:SS' ) into v_current_time from dual;


    --��������start
    open data_cur for v_sql_data ;
    loop
        fetch data_cur into v_tzrxm,v_zjhm,v_zjlbcode,v_zjlb,v_id,v_tzrlx,v_fundcode,v_fundid,v_apply_date,v_comcode,v_shfe,v_shfy;
        if data_cur%notfound then
          exit;
        end if;
        select to_date(v_apply_date ||v_current_time,'yyyy-MM-ddHH24:MI:SS') into v_current_date from dual;
        select count(1) into v_kh_count from busi_investor_credit t,busi_credit_company c
           where c.credit_id=t.id and t.credit_no = v_zjhm and t.credit_type = v_zjlbcode and c.company_id = p_company_id and t.is_delete = '0';

        --��������ڿͻ���
        if v_kh_count=0 then
            v_flag :=1;
            v_msg := v_msg||'�˿ͻ���֤������('|| v_zjhm||' û�п���������ȷ��<br>';
        end if;

        --���ڿͻ�
        if v_kh_count >0 then
            select t.id,t.regist_account  into v_credit_id,v_djzh from busi_investor_credit t
                 where  t.credit_type = v_zjlbcode  and  t.credit_no = v_zjhm  and t.is_delete= '0';
            if trim(v_djzh) is null then
                 v_flag :=1;
                 v_msg := v_msg||'�˿ͻ���֤������('|| v_zjhm||') û��Ta�������ɹ�����ȷ��<br>';
            end if;
         end if;

            --��ѯ�ݶ����  ��ʽ����ʹ�ã����Ի���ע��
            --select sum(fundvolbalance) into v_total_feye  from  zsta_tgpt.bal_fund@ta_dblink   where fundcode=v_fundcode and taaccountid=v_djzh ;
            --��ѯ�ݶ����  ���Ի���ʹ�ã���ʽ����ע��

            select sum(balance) into v_total_feye from BUSI_SHARE_BALANCE where PT_NO = v_fundcode  and  REGIST_ACCOUNT = v_djzh ;

            if v_total_feye is null then
                 v_flag :=1;
                 v_msg := v_msg||'�˿ͻ���֤������('|| v_zjhm||') û�зݶ��ȷ��<br>';
            end if;

           select child_buy_or_sale_prarent(v_credit_id,v_fundid,'03',null) into v_son_buy_monther from dual;
           if v_son_buy_monther='true' then
                 v_flag := '1';
                v_msg := v_msg||'Ͷ����(''' ||v_zjhm ||''')���ٻ��𣬻��Զ������ӻ������ĸ���������ظ�¼��<br>';
           elsif v_son_buy_monther <> 'true' and  v_son_buy_monther <> 'false' then
              insert into t_fund_job_running_log (JOB_NAME,job_running_log) values ('����ĸ����',v_son_buy_monther || '    '||v_credit_id || '    '|| v_fundid || v_apply_date );
           end  if;

             select count(id) into v_count from busi_quick_sheet where  credit_id= v_credit_id and  pt_id = v_fundid  and to_char(sheet_create_time,'yyyy-MM-dd')=v_apply_date  and BUSINESS_TYPE='024' and is_delete='0';
            if v_count> 0   then
                v_flag :=1;
                v_msg := v_msg||'�˿ͻ���֤������('|| v_zjhm||')  ������������:'||v_apply_date||' �ύ���û�����Ϲ����깺���������' ||'<br>';
           end if;


           --�жϸ��û���طݶ��Ƿ񳬹��ܷݶ�
           if v_shfe='all' then
                 v_input_total_feye:=v_total_feye;
            elsif v_shfe is not null then
                 v_input_total_feye:= to_number(replace(v_shfe,',',''),'9999999999999999.9999');
            end if;

           if  v_input_total_feye > v_total_feye then
                 v_flag :=1;
                 v_msg := v_msg||'�˿ͻ���֤������('|| v_zjhm||') ����ݶ���ܷݶ����ϵ����Ա!;ԭ���ܷݶ�:'||v_total_feye||'<br>';
           end if;

           select count(1) into v_shfh_count from busi_bind_bank_card b  where b.credit_id=v_credit_id and b.product_id=v_fundid and b.is_back_account = '1' and  is_delete='0'and rownum=1;
           if v_shfh_count < 1 then
                 v_flag :=1;
                 v_msg := v_msg||'�˿ͻ���֤������('|| v_zjhm||')û����طֺ������˺ţ�Ϊ˳���������������������˺�<br>';
           end if;

           if v_flag <> 1 then
                  --��ȡ�ֺ�������˻����п�id
                  select b.id into v_bank_card_id from busi_bind_bank_card b  where b.credit_id=v_credit_id and b.product_id=v_fundid and b.is_back_account = '1' and  is_delete='0'and rownum=1;
                  select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_sqdh from dual;
                  --��ȡͶ��������id
                  select d.id into v_tzrxq_id from busi_investor_detail d where d.credit_id=v_credit_id and  company_id = p_company_id and  is_delete='0' and rownum=1;
                   --���뵽����

                  insert into busi_quick_sheet(id,sheet_no,pt_id,pt_no,dt_id,sheet_create_time,company_id,credit_id,business_type,apply_share,create_by,
                                      create_date,is_delete,PROCEDURE_FEE)
                  values (sys_guid(),v_sqdh,v_fundid,v_fundcode,v_bank_card_id,v_current_date,p_company_id,v_credit_id,'024',v_input_total_feye,p_create_by,
                                      sysdate, '0',v_shfy);
                  update busi_batch_quick_redeem_tmp t set status='1' where t.company_id=p_company_id and t.product_id=v_fundid  and to_char(t.APPLY_DATE, 'yyyy-MM-dd') = v_apply_date;
           end if;

    end loop;
    close data_cur;

    if v_flag = 1 then
        rollback;
        open c_result for select v_job_name as flag,'faile' as res, v_msg as msg  from dual;
    else
        v_msg :='�������ݳɹ�';
        open c_result for select v_job_name as flag,'success' as res, v_msg as msg from dual;
    end if ;
    insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
    commit;
    return;

    exception
        when others then
        begin
            rollback;
--            DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
--            DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
            v_msg:= sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace();
            insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
            open c_result for select v_job_name as flag, 'faile' as res, v_msg as msg from dual;
            commit;
            IF data_cur%ISOPEN  THEN  CLOSE data_cur; END IF;
            return;
        end ;
end tgyw_quick_redeem_mp_sheet;
/


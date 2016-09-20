create or replace procedure smzj.tgyw_confirm_bank_account(
      p_compid    in  varchar2,   --��˾id
      p_batchid   in  varchar2,   --����excel�ļ�������
      p_ptcount   in  varchar2,   --�账���Ʒ����
      p_mgrname   in  varchar2,   --��������
      p_mgrid     in  varchar2,   --������id
      p_ismgr     in  varchar2,   --�Ƿ�һ������Ա
      p_ids       in  varchar2,   --BUSI_BANK_DATA_TEMP����id����
      c_result out sys_refcursor  --���صĽ�������׳����󽫴���ŵ��α���
)
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      tgyw_confirm_bank_account
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  �����˺������༭��������ȷ�������˺�
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       ������
-- CREATE DATE:  2016-05-05
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
as
      v_msg                        varchar2(1000);
      v_job_name                   varchar2(100) :='tgyw_confirm_bank_account';
      ve_exception                 exception;
      v_hascount                   integer;                                     --�Ƿ������ȷ�ϵ�����

      v_temp_id                    varchar(32);                                 --�����˺���ʱ����id
      v_investor_name              busi_bank_data_temp.investor_name%type;      --Ͷ��������
      v_credit_type                busi_bank_data_temp.credit_type_code%type;   --Ͷ����֤������
      v_credit_no                  busi_bank_data_temp.credit_no%type;          --Ͷ����֤������
      v_account_no                 busi_bank_data_temp.bank_accunt_no%type;     --Ͷ���������˺�
      v_account_name               busi_bank_data_temp.bank_account_name%type;  --Ͷ�������л���
      v_open_bank_name             busi_bank_data_temp.open_bank_name%type;     --Ͷ���˿�������
      v_province_name              busi_bank_data_temp.province_name%type;      --ʡ����
      v_city_name                  busi_bank_data_temp.city_name%type;          --������
      v_product_no                 busi_bank_data_temp.product_no%type;         --��Ʒ����
      v_apply_date                 busi_bank_data_temp.apply_date%type;         --��������
      v_bank_no                    busi_bank_data_temp.bank_no%type;            --���б��
      v_bank_name                  busi_bank_data_temp.bank_name%type;          --��������
      v_is_back_account            busi_bank_data_temp.is_back_account%type;    --�Ƿ���طֺ��˺�
      v_ptid                       varchar2(32);                                --��Ʒid
      v_credit_id                  varchar2(32);                                --busi_investor_credit����id
      v_table_id                   varchar2(32);                                --busi_bind_bank_card����id
      v_city_code                  varchar2(16);                                --���д���
      v_province_code              varchar2(16);                                --ʡ�ݴ���
      v_apply_no                   varchar2(32);                                 --���뵥��
      v_bind_date                  date;                                        --��ʱ��

      v_check_investor_name        busi_bank_data_temp.investor_name%type;      --Ͷ��������
      v_check_credit_type          busi_bank_data_temp.credit_type_code%type;   --Ͷ����֤������
      v_check_credit_no            busi_bank_data_temp.credit_no%type;          --Ͷ����֤������
      v_check_ptno                 varchar(32);                                 --��Ʒid
      v_investor_name_ta           busi_bank_data_temp.investor_name%type;      --Ͷ��������
      v_flag                       integer :=0;                                 --��־����֤�������Ӧ��������TA�������Ƿ�һ��
      v_kh_count                   integer;                                     --�Ƿ���ڿͻ���busi_investor_credit��
      v_count                      integer;                                     --��ϵͳ��ĳ�û��Ƿ���ڵ���������˺�
      v_count_bak                  integer;                                     --��طֺ��˺�
      v_product_count              integer;                                     --�Ƿ��Ǹù����˹���Ĳ�Ʒ
      v_row_count                  integer;                                     --��Ʒ���ˣ������˺ţ���Ϊһ��ά�ȵļ�¼��
      v_sql                        varchar2(2014);                              --��¼SQL���
      v_sql_data                   varchar2(2014);                              --���ݼ�SQL
      v_sql_check                  varchar2(2014);                              --У��SQL
      v_sql_batch_check            varchar2(2014);                              --У���Ʒ�Ƿ��ڸ�������

      type myrefcur  is  ref  cursor;
      data_cur_check myrefcur;
      data_cur myrefcur;
--      cursor data_cur  is select t.id,t.investor_name,t.credit_type_code,t.credit_no,t.bank_accunt_no,t.bank_account_name,t.open_bank_name,t.province_name,
--                                 t.city_name,t.product_no,t.apply_date,t.bank_no,t.bank_name,t.is_back_account,p.id ptId
--                          from busi_bank_data_temp t inner join busi_product p on t.product_no=p.product_no and t.company_id=p.CP_ID
--                          where t.id in (p_ids) and t.company_id=p_compid and t.batch_number_id=p_batchid and t.status=0 and t.is_delete=0 and p.is_delete=0;

--      cursor data_cur_check;
--     cursor data_cur_check  is select t.investor_name,t.credit_type_code,t.credit_no,t.product_no
--                          from busi_bank_data_temp t
--                          where t.id in (p_ids) and t.batch_number_id=p_batchid and t.status=0 and t.is_delete=0;
BEGIN
    -- ��������
    if p_compid is null  then
        v_msg  := '��Ҫָ����˾id';
        raise ve_exception;
    end if;
    if p_batchid is null  then
        v_msg  := '��Ҫָ������';
        raise ve_exception;
    end if;
    if p_ids is null  then
        v_msg  := '��Ҫ�������ݵ���ʱ���е�id';
        raise ve_exception;
    end if;
    if p_mgrname is null or p_mgrid is null or p_ismgr is null then
        v_msg  := '����Ա�����Ϣ����';
        raise ve_exception;
    end if;
    execute immediate 'select count(1) from busi_bank_data_temp t where t.company_id='''||p_compid||''' and t.batch_number_id='''||p_batchid||''' and t.id in ( '||p_ids||') and t.status=1' into v_hascount;
    if v_hascount>0 then
      v_flag :=1;
      v_msg :='������ȷ�ϵ����ݣ����������ȷ��';
      open c_result for select 'faile' as res, v_msg as msg  from dual;
      return;
    end if;
    --����Ʒ�Ƿ��ڸ�������
    execute immediate 'select count(1) from busi_bank_data_temp t where t.batch_number_id='''||p_batchid||''' and t.id in ( '||p_ids||') and t.status=0' into v_hascount;
    if p_ptcount>v_hascount then
      v_flag :=1;
      v_msg :='�ü�¼�����β���Ӧ���������ȷ��';
      open c_result for select 'faile' as res, v_msg as msg  from dual;
      return;
    end if;
    --��־����֤�������Ӧ��������TA�������Ƿ�һ��,���ò�Ʒ�Ƿ����ڸù�����������Ĳ�Ʒ
    v_sql_check:='select t.investor_name,t.credit_type_code,t.credit_no,t.product_no
                          from busi_bank_data_temp t
                          where t.batch_number_id='''||p_batchid||''' and t.id in ( '||p_ids||') and t.status=0 and t.is_delete=0';
    open data_cur_check for v_sql_check;
    loop
        fetch data_cur_check into v_check_investor_name ,v_check_credit_type,v_check_credit_no,v_check_ptno;
        if data_cur_check%notfound then
            exit;
        end if;
--        dbms_output.put_line('ids��¼�� : '||v_check_credit_no);
        begin
             select t.name into v_investor_name_ta  from busi_investor_credit t where  t.credit_type= v_check_credit_type and t.credit_no = v_check_credit_no and t.is_delete='0';
        exception
            when others then
            v_investor_name_ta :='';
        end;

        if v_investor_name_ta is not null and v_investor_name_ta <> v_check_investor_name then
             v_flag :=1;
             v_msg := v_msg||'֤������('|| v_check_credit_no||')��Ӧ��Ͷ��������('|| v_check_investor_name ||')��ƽ̨('||v_investor_name_ta||')��ƥ��,��ȷ�Ͽͻ�������֤������;<br>';
        end if ;

        --���ò�Ʒ�Ƿ��Ǹù�����������Ĳ�Ʒ
        if p_ismgr=0 then
          select count(1) into v_product_count from busi_product s inner join busi_product_authorization pa on s.id = pa.product_id
          where pa.mgr_id=p_mgrid and s.product_no=v_check_ptno and s.CP_ID=p_compid and s.is_delete='0';
          if v_product_count=0 then
             v_flag :=1;
             v_msg := v_msg||'Ͷ����('|| v_check_investor_name ||')���Ʒ����('|| v_check_ptno||')��ƥ��,��ȷ�ϲ�Ʒ����;<br>';
          end if;
        else
          select count(1) into v_product_count from busi_product s where s.product_no=v_check_ptno and s.CP_ID=p_compid and s.is_delete='0';
          if v_product_count=0 then
             v_flag :=1;
             v_msg := v_msg||'Ͷ����('|| v_check_investor_name ||')���Ʒ����('|| v_check_ptno||')��ƥ��,��ȷ�ϲ�Ʒ����;<br>';
          end if;
        end if;
    end loop;
    close data_cur_check;
    if v_flag = 1 then
        open c_result for select v_job_name as flag,'faile' as res, v_msg as msg  from dual;
        return ;
    end if ;
    --����ids���뿪ʼ--------------------------------------------------------------------
--    select count(1) into v_count from busi_bank_data_temp t where t.id in (p_ids);
--    EXECUTE IMMEDIATE 'select count(1) from busi_bank_data_temp t where t.id  in ( '||p_ids||')' INTO v_count;
--    dbms_output.put_line('ids��¼�� : '||v_count);
    --����ids�������--------------------------------------------------------------------
    --1.��ȡ��Ҫȷ�ϵ�����
    v_sql_data:='select t.id,t.investor_name,t.credit_type_code,t.credit_no,t.bank_accunt_no,t.bank_account_name,t.open_bank_name,t.province_name,
               t.city_name,t.product_no,t.apply_date,t.bank_no,t.bank_name,t.is_back_account,p.id ptId
        from busi_bank_data_temp t inner join busi_product p on t.product_no=p.product_no and t.company_id=p.CP_ID
        where t.id in ( '||p_ids||') and t.company_id='''||p_compid||''' and t.batch_number_id='''||p_batchid||''' and t.status=0 and t.is_delete=0 and p.is_delete=0';
    open data_cur  for v_sql_data;
    loop
        fetch data_cur into v_temp_id,v_investor_name,v_credit_type,v_credit_no,v_account_no,v_account_name,v_open_bank_name,v_province_name,v_city_name,v_product_no,
                            v_apply_date,v_bank_no,v_bank_name,v_is_back_account,v_ptid;
        if data_cur%notfound then
          exit;
        end if;
        --�жϸÿͻ��Ƿ񿪹���
        select count(1) into v_kh_count from busi_investor_credit t where t.credit_type = v_credit_type and t.credit_no = v_credit_no and t.is_delete='0';
        --��������ڿͻ���
        if v_kh_count=0 then
           v_flag :=1;
           v_msg := v_msg||'�ͻ�('||v_investor_name||')֤������('|| v_credit_no||')û�п���������ȷ��;<br>';
        --���ڿͻ�
        else
       --��ȡͶ����busi_investor_credit����id
           select t.id into v_credit_id from busi_investor_credit t
                where t.is_delete = '0' and t.credit_type = v_credit_type and t.credit_no = v_credit_no;
           select count(1) into v_count from busi_credit_company c where  c.company_id = p_compid and c.credit_id=v_CREDIT_ID;
           if v_count=0 then
                v_flag:='1';
                v_msg := v_msg||'�ͻ�('||v_INVESTOR_NAME||')�����ڸù�����;<br>';
           end if;
           --У�鵼��������˺��Ƿ��뱾ϵͳ���Ѿ����ڵ������˺��ظ�
--           select count(1) into v_count from busi_bind_bank_card t inner join busi_investor_credit c on t.credit_id=c.id
--           inner join busi_product p on t.product_id=p.id AND p.product_no=v_product_no
--                where t.bank_no=v_bank_no and t.account_no=v_account_no and c.credit_no=v_credit_no and c.credit_type=v_credit_type and t.is_delete='0' and c.is_delete='0';
           --��Ʒ���ˣ������˺ţ���Ϊһ��ά��
           select count(1) into v_row_count from busi_bind_bank_card t inner join busi_investor_credit c on t.credit_id=c.id inner join busi_product p on t.product_id=p.id
                where t.bank_no=v_bank_no and t.account_no=v_account_no and c.credit_no=v_credit_no and c.credit_type=v_credit_type and p.product_no=v_product_no
                and t.is_delete='0' and c.is_delete='0' and p.is_delete='0';

           if v_row_count>0 then
              --��طֺ��˺ſ��Դ�0���1�����ܴ�1���0
              select count(1) into v_count_bak from busi_bind_bank_card t inner join busi_investor_credit c on t.credit_id=c.id
                    where t.bank_no=v_bank_no and t.account_no=v_account_no and c.credit_no=v_credit_no and c.credit_type=v_credit_type and t.is_back_account=v_is_back_account
                    and t.is_delete='0' and c.is_delete='0' and t.product_id=v_ptid;
              if v_count_bak>0 then
--                v_flag :=1;
--                v_msg := v_msg||'�ͻ�('||v_investor_name||')���Ѿ������������˺ţ�����Ҫ�ٴε���ȷ��;<br>';
                  --�޸�20160516��ֱ��ȷ�ϲ���ʾ�ͻ��������������else����һ��
                  update busi_bank_data_temp t set t.status='1' where t.id=v_temp_id;
              --ͬһ�������˺ţ�ͬһ����Ʒ��ͬһ���ˣ�ԭ���Ƿ���طֺ��˺ţ�������ļ�������طֺ��˺ţ������û�����ص���طֺ��˻�
              elsif v_count_bak=0 and v_is_back_account=1 then
                 --�ȸ���ԭ������طֺ��˺�Ϊ����طֺ��˻�
                  update busi_bind_bank_card b set b.is_delete='1' where b.is_back_account='1' and b.is_delete='0' and b.product_id=v_ptid and exists(
                      select  1 from busi_investor_credit c where c.credit_no=v_credit_no and c.credit_type=v_credit_type and c.is_delete = '0');
                 --�������ڵ��˻�Ϊ��طֺ��˻�
                 update busi_bind_bank_card t set t.is_back_account=1,t.investor_identify_flag='1' where t.bank_no=v_bank_no and t.is_delete='0' and t.account_no=v_account_no and exists(
                 select 1 from busi_investor_credit c where c.credit_no=v_credit_no and c.credit_type=v_credit_type);
                 update busi_bank_data_temp t set t.status='1' where t.id=v_temp_id;
              else
                 update busi_bank_data_temp t set t.status='1' where t.id=v_temp_id;
              end if;
           else


             --�������طֺ��˺�,��֮ǰ�ò�Ʒ����طֺ��˺����óɷ���طֺ��˺�
             if v_is_back_account=1 then
                update busi_bind_bank_card b set b.is_delete='1' where b.is_back_account='1' and b.product_id=v_ptid and b.credit_id=v_credit_id and b.is_delete='0';
             end if;

             if (v_province_name is not null) then
                  select id,name into v_province_code,v_province_name from busi_region where name = v_province_name and parent_id is null and rownum=1; --��ȡʡ��ID
             end if;
             if (v_city_name is not null) then
                  select id,name into v_city_code,v_city_name from busi_region where NAME = v_city_name and parent_id is not null and rownum=1;     --��ȡ����id
             end if;
             --�������뵥�źͱ�id��������
             select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)),sys_guid(),
                  to_date(v_apply_date ||to_char(sysdate,'HH24:MI:SS' ),'yyyy-MM-ddHH24:MI:SS') into v_apply_no,v_table_id,v_bind_date from dual;
             --�������˺Ų��뵽busi_bind_bank_card����
             insert into busi_bind_bank_card(id,credit_id,user_name,bank_no,bank_name,open_bank_name,province_id,province_name,city_id,city_name,
                                   account_no,product_id,company_id,apply_no,bind_date,create_date, create_by,is_back_account,Investor_Identify_Flag)
                            values (v_table_id,v_credit_id,v_investor_name,v_bank_no,v_bank_name,v_open_bank_name,v_province_code,v_province_name,v_city_code,v_city_name,
                            v_account_no,v_ptid,p_compid,v_apply_no,v_bind_date,sysdate,p_mgrname,v_is_back_account,'1');
             --����״̬Ϊ��ȷ��
             update busi_bank_data_temp t set t.status='1' where t.id=v_temp_id;
           end if;

        end if;
    end loop;
    close data_cur;

    if v_flag = 1 then
      rollback;
      open c_result for select 'faile' as res, v_msg as msg  from dual;
      return ;
    end if ;

    v_msg :='ȷ�������˺ųɹ�';
    open c_result for select 'success' as res, v_msg as msg from dual;
    commit;

    EXCEPTION
    WHEN ve_exception then
        rollback;
        DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
        DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
        v_msg:=sqlcode||':'||sqlerrm;
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg||dbms_utility.format_error_backtrace());
        commit;
        open c_result for select 'faile' as res, v_msg as msg from dual;
        return;
    WHEN OTHERS THEN
        rollback;
        DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
        DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
        v_msg:=sqlcode||':'||sqlerrm;
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg||dbms_utility.format_error_backtrace());
        commit;
        open c_result for select 'faile' as res, v_msg as msg from dual;
        return;

END TGYW_CONFIRM_BANK_ACCOUNT;
/


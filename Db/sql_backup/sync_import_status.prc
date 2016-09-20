create or replace procedure smzj.SYNC_IMPORT_STATUS
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      SYNC_APPLY_DATA
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  ͬ�� ta״̬�� ����δ����ta�� �ѵ���Ta�� TA©�� 
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       xiaxiaonan
-- CREATE DATE:  2016-02-17
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
is
-- �����ֶδ�TA�ı��л�ȡ
v_zh_sqdh       varchar2(100 char);                   --�ʻ����룬���뵥��
v_zh_khbh       varchar2(100 char);                   --�˻����룬�ͻ����
v_zh_ywlx       varchar2(100 char);                    --�˻����룬ҵ������
v_zh_jggr       varchar2(100 char);                    --�˻����룬��������
v_zh_zjlx       varchar2(100 char);                    --�˻����룬֤������
v_zh_zjhm       varchar2(100 char);                    --�˻����룬֤������
v_zh_khmc       varchar2(100 char);                    --�˻����룬�ͻ�����
v_zh_djzh       varchar2(100 char);                    --�˻����룬�Ǽ��˺�
v_zh_count      varchar2(100 char);                    --�˻���������
v_count2        integer;                              --����ĳ�����뵥�ŵ��˻��������� 
v_zh_sqrq       varchar2(100 char);                     --�˻����룬��������
     
v_jy_sqdh       varchar2(100 char);                   --�������룬���뵥��
v_jy_cpdm       varchar2(100 char);                    --�������룬��Ʒ����
v_jy_ywlx       varchar2(100 char);                    --�������룬ҵ������
v_jy_sqje       varchar2(100 char);                    --�������룬������
v_jy_sqfe       varchar2(100 char);                    --�������룬����ݶ�
v_jy_count      integer;                              --������������
v_count1        integer;                              --����ĳ�����뵥�ŵĽ�����������      
                                          
--�����ֶδ�˽ļ֮�ұ��л�ȡ
v_BUSI_TYPE     varchar2(100 char);                    --�˻����룬ҵ������
v_USER_TYPE       varchar2(100 char);                  --�˻����룬��������
v_CREDIT_TYPE     varchar2(100 char);                  --�˻����룬֤������
v_CREDIT_TYPE_CODE    varchar2(100 char);             --�˻����룬֤�����ʹ���
v_CREDIT_NO        varchar2(100 char);                --�˻����룬֤������
v_NAME           varchar2(100 char);                  --�˻����룬����
v_REGIST_ACCOUNT  varchar2(100 char);                 --�˻����룬�Ǽ��˺�

v_PT_NO         varchar2(100 char);                    --�������룬��Ʒ����
v_BUSINESS_TYPE varchar2(100 char);                    --�������룬ҵ������
v_APPLY_AMOUNT  varchar2(100 char);                    --�������룬������
v_APPLY_SHARE   varchar2(100 char);                    --�������룬����ݶ�
--��¼״̬��Ϣ
v_msg1           varchar2(100 char);                   --��¼TA״̬��Ϣ
v_msg1_info      varchar2(1000 char);                   --��¼TA״̬��ϸ��Ϣ
v_msg           varchar2(1000 char);                   --��¼��־��Ϣ
v_flag  varchar2(1 char);
v_job_name varchar2(100):= 'SYNC_IMPORT_STATUS';
v_currdate       varchar2(100 char);                     --��ǰ������
v_predate        varchar2(100 char);                    --�ϸ�������

--��ȡut_sm_jysq������������Ϊ���������
cursor trade_cur is
select jy.SQDH,jy.CPDM,case jy.YWLX when '�깺' then '022' when '�Ϲ�' then '020' when '���' then '024' else '029' end,
       to_char(jy.SQJE,'fm9999999990.00'),to_char(jy.SQFE,'fm9999999990.00')
from zsta.ut_sm_jysq@ta_dblink jy
where SQRQ = v_predate;

--������������,��ȡTA�˻�������д���ǰһ�������յ����� modify 20160331
cursor count_cur is
select zh.SQDH,zh.KHBH,case zh.YWLX when '����' then '001' when '�����˻�' then '008' when '�޸�����' then '003' end ,
       case zh.JGGR when '����' then '1' when '����' then '2' end,
       zh.ZJLX,zh.ZJHM,zh.KHMC,zh.DJZH,zh.SQRQ
from zsta.ut_sm_zhsq@ta_dblink zh
where SQRQ >= v_predate;

begin
  --v_predate:='20160128';
  select to_char(sysdate,'yyyyMMdd') into v_currdate from dual;
  select getpreworkday(v_currdate)into v_predate from dual;     
  
  
  --���ж�T+1��,TA����û����ص�����
  select count(*) into v_jy_count from  zsta.ut_sm_jysq@ta_dblink jy where SQRQ = v_predate;
  if v_jy_count = 0 then  
     return;
  end if;
  
  --�˻�������ܴ�����������>=�������ڵĶ���,modify 20160330
  select count(*) into v_zh_count from  zsta.ut_sm_zhsq@ta_dblink zh where SQRQ >= v_predate;
  if v_zh_count = 0 then
    return;
  end if;
  

  --�Ȱ�˽ļ֮��T������ȫ������Ϊ©��
  update busi_sheet set ta_status = '����©��' where to_char(SHEET_CREATE_TIME,'yyyyMMdd')=v_predate;
  update busi_investor_detail set ta_status = '����©��' where to_char(CREATE_DATE,'yyyyMMdd')>=v_predate; 
  

  open trade_cur;
  loop
       fetch trade_cur into v_jy_sqdh,v_jy_cpdm,v_jy_ywlx,v_jy_sqje,v_jy_sqfe;
       if trade_cur%notfound then
           exit;
        end if;
        
        --��cursor�е�TA����������״̬,���˽ļ֮���в����ڸõ��ţ�˵��Ϊ��������
        select count(*) into v_count1 from busi_sheet where sheet_no = v_jy_sqdh and is_delete = '0';
        if v_count1 > 0 then                          --count1>0��ʾ��˽ļ֮���д��ڸ����뵥��
           select PT_NO,BUSINESS_TYPE,to_char(APPLY_AMOUNT,'fm9999999990.00'),to_char(APPLY_SHARE,'fm9999999990.00') into v_PT_NO,v_BUSINESS_TYPE,v_APPLY_AMOUNT,v_APPLY_SHARE from busi_sheet 
                  where sheet_no = v_jy_sqdh;
                  
             v_flag:='0';
             v_msg1_info:='';
             --��Ʒ���벻��
             --if v_jy_cpdm <> v_PT_NO then
             if compare(v_jy_cpdm,v_PT_NO)=0 then 
                v_msg1_info := v_msg1_info||'��Ʒ���벻��';
                v_flag:='1';
             end if;
             --ҵ�����Ͳ���
             --if v_jy_ywlx <> v_BUSINESS_TYPE then
             if compare(v_jy_ywlx,v_BUSINESS_TYPE)=0 then
                v_msg1_info :=v_msg1_info|| 'ҵ�����Ͳ���';
                v_flag:='1';
             end if;
             --����ݶ��
             --if v_jy_sqje <> v_APPLY_AMOUNT then
             if compare(v_jy_sqje,v_APPLY_AMOUNT)=0 then 
               v_msg1_info := v_msg1_info||'����ݶ��';
               v_flag:='1';
              end if;
              --�������
              --if v_jy_sqfe<>v_APPLY_SHARE  then
              if compare(v_jy_sqfe,v_APPLY_SHARE)=0 then   
                v_msg1_info := v_msg1_info||'�������';
                v_flag:='1';
              end if;
               if v_flag='0' then
                 v_msg1 := '����ɹ�';
               else
                 v_msg1 := '���ݲ���';   
               end if;
             update busi_sheet set ta_status = v_msg1,ta_status_info=v_msg1_info where sheet_no = v_jy_sqdh;
         else                                --˽ļ֮����û�и����ݣ�����뵽˽ļ֮���У������Ϊ��������
               select count(*) into v_count1 from busi_sheet where sheet_no = v_jy_sqdh;   --˽ļ֮����ɾ��״̬Ϊ1����TA���и���������
               if v_count1=0 then 
                  insert into busi_sheet (ID,SHEET_NO,PT_ID,PT_NO,BUSINESS_TYPE,APPLY_AMOUNT,APPLY_SHARE,is_delete,ta_status,SHEET_CREATE_TIME)
                         values (id_seq.nextval,v_jy_sqdh,id_seq.nextval,v_jy_cpdm,v_jy_ywlx,v_jy_sqje,v_jy_sqfe,'1','��������',to_date(v_predate,'yyyyMMdd'));
               else
                  update busi_sheet set ta_status = '��������' where sheet_no = v_jy_sqdh;
               end if;
        end if;  
     end loop;
     close trade_cur;
     
     
     open count_cur;
     loop
       fetch count_cur into v_zh_sqdh,v_zh_khbh,v_zh_ywlx,v_zh_jggr,v_zh_zjlx,v_zh_zjhm,v_zh_khmc,v_zh_djzh,v_zh_sqrq;
       if count_cur%notfound then
           exit;
        end if;
        
        --��cursor�е�TA����������״̬,���˽ļ֮���в����ڸõ��ţ�˵��Ϊ�������ݡ��������ڱ���Ҫ���ڵ�����һ�������գ�modify 20160330
        select count(*) into v_count2 from busi_investor_detail where apply_no = v_zh_sqdh  
               and to_char(create_date,'yyyyMMdd') >= v_predate  and is_delete='0';
        if v_count2 > 0 then
           select BUSI_TYPE,INVESTOR_TYPE,CREDIT_TYPE,CREDIT_NO,NAME,REGIST_ACCOUNT
                  into v_BUSI_TYPE,v_USER_TYPE,v_CREDIT_TYPE_CODE,v_CREDIT_NO,v_NAME,v_REGIST_ACCOUNT
           from busi_investor_detail 
           where apply_no = v_zh_sqdh; 
           --˽ļ֮����֤���������Դ������ʽ�洢
           select label into v_CREDIT_TYPE from sys_dict where type = 'credit_type' and value = v_CREDIT_TYPE_CODE;
          
           --�Աȿͻ����
            v_flag:='0';
            v_msg1_info:='';
            /*
            --if v_CUSTOM_NO<>v_zh_khbh  then
            if compare(v_CUSTOM_NO,v_zh_khbh)=0 THEN
              v_msg1_info :=v_msg1_info||'�ͻ���Ų���';
              v_flag:='1';
            end if;
            */
            --�Ա�ҵ������
            --if v_BUSI_TYPE<>v_zh_ywlx  then
            if compare(v_BUSI_TYPE,v_zh_ywlx)=0 THEN
              v_msg1_info :=v_msg1_info||'ҵ�����Ͳ���';
              v_flag:='1';
            end if;
            --�ԱȻ�����������
            --if v_USER_TYPE<>v_zh_jggr  then
            if compare(v_USER_TYPE,v_zh_jggr)=0 THEN
              v_msg1_info :=v_msg1_info||'�����������Ͳ���';
              v_flag:='1';
            end if;
            --�Ա�֤������
            --if v_CREDIT_TYPE<>v_zh_zjlx  then
            if compare(v_CREDIT_TYPE,v_zh_zjlx)=0 THEN
              v_msg1_info :=v_msg1_info||'֤�����Ͳ���';
              v_flag:='1';
            end if;
            --�Ա�֤������
            --if v_CREDIT_NO<>v_zh_zjhm  then
            if compare(v_CREDIT_NO,v_zh_zjhm)=0 THEN
              v_msg1_info :=v_msg1_info||'֤�����벻��';
              v_flag:='1';
            end if;
            --�Աȿͻ�����
            --if v_NAME<>v_zh_khmc  then
            if compare(v_NAME,v_zh_khmc)=0 THEN
              v_msg1_info :=v_msg1_info||'�ͻ����Ʋ���';
              v_flag:='1';
            end if;
            --�ԱȵǼ��˺�
            --if v_REGIST_ACCOUNT<>v_zh_djzh  then
            --���˽ļ֮����ĵȼ��˺�Ϊ�գ��򲻶Աȵȼ��˺�
            if compare(v_REGIST_ACCOUNT,null) = 0 then           
                if compare(v_REGIST_ACCOUNT,v_zh_djzh)=0 THEN
                  v_msg1_info :=v_msg1_info||'�Ǽ��˺Ų���';
                  v_flag:='1';
                end if;
            end if;
     
            if v_flag='0' then
               v_msg1 := '����ɹ�';
            else
              v_msg1:= '���ݲ���';
            end if;
            update busi_investor_detail set ta_status = v_msg1,ta_status_info=v_msg1_info where apply_no = v_zh_sqdh;
      
          else                                --˽ļ֮����û�и����ݣ�����뵽˽ļ֮���У������Ϊ��������
             select count(*) into v_count1 from busi_investor_detail where apply_no = v_zh_sqdh;   --˽ļ֮����ɾ��״̬Ϊ1����TA���и���������
             if v_count1=0 then 
                insert into busi_investor_detail (ID,apply_no,ta_status,busi_type,is_delete,company_id,credit_id,create_date)
                       values (id_seq.nextval,v_zh_sqdh,'��������',v_zh_ywlx,'1',id_seq.nextval,id_seq.nextval,to_date(v_zh_sqrq,'yyyy-MM-dd,HH24:mi:ss'));
             else
                update busi_investor_detail set ta_status = '��������' where apply_no = v_zh_sqdh;
             end if;
       end if;  
     end loop;
     close count_cur;
     
     insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,'���³ɹ�');
     commit;
     
EXCEPTION
    when others then
        if trade_cur%isopen then
            close trade_cur;
        end if;
        if count_cur%isopen then
            close count_cur;
        end if;
        
        rollback;
        v_msg :='����ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm ||' '|| SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_IMPORT_STATUS;
/


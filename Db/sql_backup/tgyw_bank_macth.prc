create or replace procedure smzj."TGYW_BANK_MACTH" (v_batch_number in varchar2,v_create_date in varchar2,c_result out sys_refcursor) is

---- *************************************************************************
-- SUBSYS:       �йܷ���
-- PROGRAM:      TGYW_BANK_MACTH
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       ����
-- DESCRIPTION:  �����˺�ƥ��

-- CREATE DATE:  2016-04-15
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
v_msg                         varchar2(255);--������Ϣ
--v_custom_name               busi_sheet.credi %type;--�ͻ�����
v_apply_no                    busi_bank_match.apply_no %type;--������
v_customer_name               busi_bank_match.customer_name %type;--�ͻ�����
v_pt_id                       busi_bank_match.pt_id %type;--��ƷID
v_apply_amount                busi_bank_match.apply_amount %type;--���
v_match_id                    busi_bank_match.id %type;--ƥ���¼ID
v_bank_card_id                busi_bind_bank_card.id %type;--���п�ID
v_bank_apply_no               busi_bind_bank_card.apply_no %type;--�����
v_cust_count                  integer;
v_bank_card_count             integer;
v_exist_bank_card_count       integer;
v_exist_unmatch_count         integer;
v_exist_match_count       integer;
cursor sheet_cur  is select t.apply_no,t.customer_name,t.pt_id,t.apply_amount,t.id  from busi_bank_match t where  t.flag='1' and t.batch_number=v_batch_number;


begin
    select count(*) into v_cust_count from busi_bank_flow f where f.flag in('2') and f.batch_number=v_batch_number;
    if v_cust_count = 0 then
      v_msg :='û���ҵ�������ˮ����';
      open c_result for select 'failure' as res, v_msg as msg from dual;
      delete from busi_bank_match t where t.flag in('1')   and t.batch_number=v_batch_number;
      return;
    end if;

    open sheet_cur;
      loop
       fetch sheet_cur into v_apply_no ,v_customer_name,v_pt_id,v_apply_amount,v_match_id;
       if sheet_cur%notfound then
        exit;
      end if;

      if trim(v_customer_name) is null then
             update busi_bank_match bank set bank.is_matched='0',bank.match_result='0', bank.flag='3',bank.remark='�����¼��û�пͻ�����' where bank.id=v_match_id;
       else
                --��Ͷ����ϵͳ���������п��������
                select count(*) into v_bank_card_count from busi_bind_bank_card t where t.user_name=trim(v_customer_name) and t.product_id=v_pt_id and t.is_delete='0';

                if v_bank_card_count=0 then
                   --������ˮ��¼�������ͽ�����ƥ��
                   select count(*) into v_cust_count from busi_bank_flow fw where fw.account_name = trim(v_customer_name) and to_number(fw.apply_amount,'9999999999999999.9999')=to_number(v_apply_amount,'9999999999999999.9999') and fw.flag='2' and fw.batch_number=v_batch_number;

                   --δƥ�䵽������Ϣ,���¼δƥ��
                   if v_cust_count=0 then
                       update busi_bank_match bank set bank.is_matched='1',bank.match_result='0', bank.flag='3',bank.remark='δƥ�䵽���м�¼' where bank.id=v_match_id;
                       --��δƥ�䵽�����ݷŵ���ʱ����
                         --����Ѿ�����δƥ���¼�����ظ�����
                       select count(*) into v_exist_unmatch_count from busi_bind_bank_card_match um where um.apply_no=v_apply_no and um.user_name=v_customer_name and um.product_id=v_pt_id and um.match_status='0';
                       if v_exist_unmatch_count = 0 then
                       insert into busi_bind_bank_card_match(id,credit_id,user_name, bank_no, bank_name,open_bank_name, province_id,province_name, city_id, city_name, account_no,product_id, company_id, apply_no,
                       bind_date, create_date,create_by, is_back_account,link_bank_no,remark,match_status,confirm_status,apply_date)
                         select sys_guid(),s.credit_id,m.customer_name,m.big_amount_bank,null,m.open_bank_name,m.province_id,m.province_name,m.city_id,m.city_name,m.bank_account_no,m.pt_id,
                             s.company_id,m.apply_no,sysdate,sysdate,null,null,null,'δƥ�䵽���м�¼,�����','0','0',s.sheet_create_time
                         from busi_sheet s inner join busi_bank_match  m on s.sheet_no=m.apply_no
                         where s.sheet_no=v_apply_no and rownum=1;
                       end if;
                   --ƥ�䵽Ψһ������Ϣ���򽫸�������Ϣ�������ͻ�
                   elsif v_cust_count=1 then
                       select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_bank_apply_no from dual;
                       select sys_guid() into v_bank_card_id from dual;
                       --��Ψһ������Ϣ���ݲ��뵽ƥ������ʱ����
                         update busi_bank_flow fw set fw.apply_no=v_apply_no,fw.match_result='1',fw.flag='3' where fw.account_name = trim(v_customer_name) and to_number(fw.apply_amount,'9999999999999999.9999')=to_number(v_apply_amount,'9999999999999999.9999') and fw.flag='2' and fw.batch_number=v_batch_number;
                         insert into busi_bind_bank_card_match(id,credit_id,user_name, bank_no, bank_name,open_bank_name, province_id,province_name, city_id, city_name, account_no,product_id, company_id, apply_no, bind_date, create_date,create_by, is_back_account,
                         link_bank_no,remark,MATCH_STATUS,CONFIRM_STATUS,apply_date)
                          select v_bank_card_id,s.credit_id,m.account_name,m.bank_no,m.bank_name,m.open_bank_name,m.province_id,m.province_name,m.city_id,m.city_name,m.bank_account_no,s.pt_id,
                              s.company_id,m.apply_no,sysdate,sysdate,'system','1','','ƥ�䵽һ�������м�¼,��ȷ�ϻ��޸�','1','0',s.sheet_create_time
                          from busi_sheet s inner join busi_bank_flow  m on s.sheet_no=m.apply_no
                          where s.sheet_no=v_apply_no and m.batch_number=v_batch_number and m.flag='3' and rownum=1;

                         --Ψһƥ��ֱ�ӽ����ݲ��뵽busi_bind_bank_card�����ʽ����
                         --insert into busi_bind_bank_card(id,credit_id,user_name, bank_no, bank_name,open_bank_name, province_id,province_name, city_id, city_name, account_no,product_id, company_id, apply_no, bind_date, create_date,create_by, is_back_account,link_bank_no,remark)
                         --select v_bank_card_id,s.credit_id,m.account_name,m.bank_no,m.bank_name,m.open_bank_name,m.province_id,m.province_name,m.city_id,m.city_name,m.bank_account_no,s.pt_id,
                              --s.company_id,m.apply_no,m.create_date,m.create_date,'system','1','','Ψһƥ���¼'
                          --from busi_sheet s inner join busi_bank_flow  m on s.sheet_no=m.apply_no
                          --where s.sheet_no=v_apply_no and m.flag='3' and rownum=1;
                       --Ψһƥ�� ������������bank_card_id����ʱ���������
                       update busi_sheet sh set sh.bank_card_id='1' where sh.sheet_no=trim(v_apply_no);
                       update busi_bank_match bank set bank.is_matched='1',bank.match_result='1', bank.flag='3',bank.remark='ƥ�䵽һ�������м�¼' where bank.id=v_match_id;
                       delete from busi_bind_bank_card_match bbm where bbm.apply_no=trim(v_apply_no) and bbm.user_name=trim(v_customer_name) and bbm.product_id=v_pt_id and bbm.match_status='0';
                   --ƥ�䵽���������Ϣ,�򽫶��������Ϣչʾ���ͻ�ȥȷ��
                   else
                     --��������
                      update busi_bank_flow fw set fw.apply_no=v_apply_no,fw.match_result='N',fw.flag='3' where fw.account_name = trim(v_customer_name) and to_number(fw.apply_amount,'9999999999999999.9999')=to_number(v_apply_amount,'9999999999999999.9999') and fw.flag='2' and fw.batch_number=v_batch_number;

                      insert into busi_bind_bank_card_match(id,credit_id,user_name, bank_no, bank_name,open_bank_name, province_id,province_name, city_id, city_name, account_no,product_id, company_id, apply_no, bind_date, create_date,create_by, is_back_account,
                         link_bank_no,remark,MATCH_STATUS,CONFIRM_STATUS,apply_date)
                          select sys_guid(),s.credit_id,m.account_name,m.bank_no,m.bank_name,m.open_bank_name,m.province_id,m.province_name,m.city_id,m.city_name,m.bank_account_no,s.pt_id,
                              s.company_id,m.apply_no,sysdate,sysdate,'system','1','','ƥ�䵽���������м�¼,��ȷ�ϻ��޸�','N','0',s.sheet_create_time
                          from busi_sheet s inner join busi_bank_flow  m on s.sheet_no=m.apply_no
                          where s.sheet_no=v_apply_no and m.batch_number=v_batch_number and m.flag='3';

                     update busi_sheet sh set sh.bank_card_id='N' where sh.sheet_no=trim(v_apply_no);
                     update busi_bank_match bank set bank.is_matched='1',bank.match_result='N', bank.flag='3',bank.remark='ƥ�䵽���������м�¼' where bank.id=v_match_id;
                     delete from busi_bind_bank_card_match bbm where bbm.apply_no=trim(v_apply_no) and bbm.user_name=trim(v_customer_name) and bbm.product_id=v_pt_id and bbm.match_status='0';
                   end if;

               else
               --��Ͷ����ϵͳ���Ѿ��������п��������
                --select count(*) into v_exist_bank_card_count from   busi_bind_bank_card b where b.user_name=trim(v_customer_name) and b.product_id=v_pt_id and b.is_delete='0'��
               select count(*) into v_exist_bank_card_count from busi_bank_flow f where  f.flag='2' and f.batch_number=v_batch_number and f.account_name=trim(v_customer_name) and to_number(f.apply_amount,'9999999999999999.9999')=to_number(v_apply_amount,'9999999999999999.9999') and f.bank_account_no in
               (select b.account_no from busi_bind_bank_card b where b.user_name=trim(v_customer_name) and b.product_id=v_pt_id and b.is_delete='0');
                  --����ˮ�ļ��в�����ƥ��������˺�
                  if v_exist_bank_card_count=0 then
                  select count(*) into v_exist_match_count from busi_bank_flow f where f.flag='2' and f.batch_number=v_batch_number and f.account_name=trim(v_customer_name) and  to_number(f.apply_amount,'9999999999999999.9999')=to_number(v_apply_amount,'9999999999999999.9999');
                  --�������ƺͽ��δ�ҵ�ƥ������
                  if v_exist_match_count=0 then
                   update busi_bank_match bank set bank.is_matched='1',bank.match_result='0', bank.flag='3',bank.remark='δƥ�䵽���м�¼' where bank.id=v_match_id;
                   --��δƥ�䵽�����ݷŵ���ʱ����
                   --����Ѿ�����δƥ���¼�����ظ�����
                   select count(*) into v_exist_unmatch_count from busi_bind_bank_card_match um where um.apply_no=v_apply_no and um.user_name=v_customer_name and um.product_id=v_pt_id and um.match_status='0';
                   if v_exist_unmatch_count = 0 then
                   insert into busi_bind_bank_card_match(id,credit_id,user_name, bank_no, bank_name,open_bank_name, province_id,province_name, city_id, city_name, account_no,product_id, company_id, apply_no,
                       bind_date, create_date,create_by, is_back_account,link_bank_no,remark,match_status,confirm_status,apply_date)
                         select sys_guid(),s.credit_id,m.customer_name,m.big_amount_bank,null,m.open_bank_name,m.province_id,m.province_name,m.city_id,m.city_name,m.bank_account_no,m.pt_id,
                             s.company_id,m.apply_no,sysdate,sysdate,null,null,null,'δƥ�䵽���м�¼,�����','0','0',s.sheet_create_time
                         from busi_sheet s inner join busi_bank_match  m on s.sheet_no=m.apply_no
                         where s.sheet_no=v_apply_no and m.batch_number=v_batch_number and  rownum=1;
                   end if;
                  --�������ƺͽ���ҵ���һ��ƥ������
                  elsif  v_exist_match_count=1 then
                  update busi_bank_flow fw set fw.apply_no=v_apply_no,fw.match_result='1',fw.flag='3' where fw.account_name = trim(v_customer_name) and to_number(fw.apply_amount,'9999999999999999.9999')=to_number(v_apply_amount,'9999999999999999.9999') and fw.flag='2' and fw.batch_number=v_batch_number;
                   insert into busi_bind_bank_card_match(id,credit_id,user_name, bank_no, bank_name,open_bank_name, province_id,province_name, city_id, city_name, account_no,product_id, company_id, apply_no, bind_date, create_date,create_by, is_back_account,
                         link_bank_no,remark,MATCH_STATUS,CONFIRM_STATUS,apply_date)
                          select sys_guid(),s.credit_id,m.account_name,m.bank_no,m.bank_name,m.open_bank_name,m.province_id,m.province_name,m.city_id,m.city_name,m.bank_account_no,s.pt_id,
                              s.company_id,m.apply_no,sysdate,sysdate,'system','1','','ƥ�䵽һ�������м�¼,��ȷ�ϻ��޸�','1','0',s.sheet_create_time
                          from busi_sheet s inner join busi_bank_flow  m on s.sheet_no=m.apply_no
                          where s.sheet_no=v_apply_no and m.batch_number=v_batch_number and m.flag='3';

                   update busi_sheet sh set sh.bank_card_id='1' where sh.sheet_no=trim(v_apply_no);
                   update busi_bank_match bank set bank.is_matched='1',bank.match_result='1', bank.flag='3',bank.remark='ƥ�䵽һ�������м�¼' where bank.id=v_match_id;
                   delete from busi_bind_bank_card_match bbm where bbm.apply_no=trim(v_apply_no) and bbm.user_name=trim(v_customer_name) and bbm.product_id=v_pt_id and bbm.match_status='0';
                  --�������ƺͽ���ҵ��˶���ƥ������
                  else
                  update busi_bank_flow fw set fw.apply_no=v_apply_no,fw.match_result='N',fw.flag='3' where fw.account_name = trim(v_customer_name) and to_number(fw.apply_amount,'9999999999999999.9999')=to_number(v_apply_amount,'9999999999999999.9999') and fw.flag='2' and fw.batch_number=v_batch_number;
                   insert into busi_bind_bank_card_match(id,credit_id,user_name, bank_no, bank_name,open_bank_name, province_id,province_name, city_id, city_name, account_no,product_id, company_id, apply_no, bind_date, create_date,create_by, is_back_account,
                         link_bank_no,remark,MATCH_STATUS,CONFIRM_STATUS,apply_date)
                          select sys_guid(),s.credit_id,m.account_name,m.bank_no,m.bank_name,m.open_bank_name,m.province_id,m.province_name,m.city_id,m.city_name,m.bank_account_no,s.pt_id,
                              s.company_id,m.apply_no,sysdate,sysdate,'system','1','','ƥ�䵽���������м�¼,��ȷ�ϻ��޸�','N','0',s.sheet_create_time
                          from busi_sheet s inner join busi_bank_flow  m on s.sheet_no=m.apply_no
                          where s.sheet_no=v_apply_no and m.batch_number=v_batch_number and m.flag='3';

                   update busi_sheet sh set sh.bank_card_id='N' where sh.sheet_no=trim(v_apply_no);
                   update busi_bank_match bank set bank.is_matched='1',bank.match_result='N', bank.flag='3',bank.remark='ƥ�䵽���������м�¼' where bank.id=v_match_id;
                   delete from busi_bind_bank_card_match bbm where bbm.apply_no=trim(v_apply_no) and bbm.user_name=trim(v_customer_name) and bbm.product_id=v_pt_id and bbm.match_status='0';
                  end if;
                  --��ֻ��һ�������������˺ż�¼,�򽫸������˺Ź���������
                  elsif v_exist_bank_card_count=1 then
                  update busi_bank_flow fw set fw.apply_no=v_apply_no,fw.match_result='1',fw.flag='3' where fw.flag='2' and fw.batch_number=v_batch_number and fw.account_name=trim(v_customer_name) and to_number(fw.apply_amount,'9999999999999999.9999')=to_number(v_apply_amount,'9999999999999999.9999') and fw.bank_account_no in
               (select b.account_no from busi_bind_bank_card b where b.user_name=trim(v_customer_name) and b.product_id=v_pt_id and b.is_delete='0');
                  v_bank_card_id:=null;
                  select t.id into v_bank_card_id from busi_bind_bank_card t where t.user_name=trim(v_customer_name) and t.product_id=v_pt_id and t.is_delete='0' and t.account_no in
                  (select f.bank_account_no from busi_bank_flow f where f.apply_no=v_apply_no and f.flag='3')  and rownum=1;


                  update busi_bank_match bank set bank.is_matched='1',bank.match_result='1', bank.flag='3',bank.remark='ƥ�䵽һ���������м�¼' where bank.id=v_match_id;
                  update busi_sheet sh set sh.bank_card_id='1' where sh.sheet_no=trim(v_apply_no);
                  insert into busi_bind_bank_card_match(id,credit_id,user_name, bank_no, bank_name,open_bank_name, province_id,province_name, city_id, city_name, account_no,product_id, company_id, apply_no, bind_date, create_date,create_by, is_back_account,
                         link_bank_no,remark,MATCH_STATUS,CONFIRM_STATUS,apply_date)
                          select sys_guid(),s.credit_id,s.user_name,s.bank_no,s.bank_name,s.open_bank_name,s.province_id,s.province_name,s.city_id,s.city_name,s.account_no,s.product_id,
                              s.company_id,v_apply_no,sysdate,sysdate,s.create_by,s.is_back_account,s.link_bank_no,'ƥ�䵽һ���������м�¼,��ȷ�ϻ��޸�','1','0',(select  s.sheet_create_time from busi_sheet s where s.sheet_no=trim(v_apply_no) and rownum=1)
                          from busi_bind_bank_card s where s.id=v_bank_card_id;
                  delete from busi_bind_bank_card_match bbm where bbm.apply_no=trim(v_apply_no) and bbm.user_name=trim(v_customer_name) and bbm.product_id=v_pt_id and bbm.match_status='0';
                  --���ж��������������˺ż�¼,�򽫶��������˺�չʾ���ͻ�ȷ��
                  elsif v_exist_bank_card_count>1 then
                  update busi_bank_flow fw set fw.apply_no=v_apply_no,fw.match_result='N',fw.flag='3' where fw.flag='2' and fw.batch_number=v_batch_number and fw.account_name=trim(v_customer_name) and to_number(fw.apply_amount,'9999999999999999.9999')=to_number(v_apply_amount,'9999999999999999.9999') and fw.bank_account_no in
                  (select b.account_no from busi_bind_bank_card b where b.user_name=trim(v_customer_name) and b.product_id=v_pt_id and b.is_delete='0');

                  update busi_sheet sh set sh.bank_card_id='N' where sh.sheet_no=trim(v_apply_no);
                  insert into busi_bind_bank_card_match(id,credit_id,user_name, bank_no, bank_name,open_bank_name, province_id,province_name, city_id, city_name, account_no,product_id, company_id, apply_no, bind_date, create_date,create_by, is_back_account,
                       link_bank_no,remark,match_status,confirm_status,apply_date)
                       select sys_guid(),s.credit_id,s.user_name,s.bank_no,s.bank_name,s.open_bank_name,s.province_id,s.province_name,s.city_id,s.city_name,s.account_no,s.product_id,
                              s.company_id,v_apply_no,sysdate,sysdate,s.create_by,s.is_back_account,s.link_bank_no,'ƥ�䵽�����������м�¼,��ȷ�ϻ��޸�','N','0', (select  s.sheet_create_time from busi_sheet s where s.sheet_no=trim(v_apply_no) and rownum=1)
                          from busi_bind_bank_card s where s.user_name=trim(v_customer_name) and s.product_id=v_pt_id and s.is_delete='0' and exists
                     (select 1 from busi_bank_flow m where  m.flag='3' and m.batch_number=v_batch_number and m.account_name=trim(v_customer_name) and m.bank_account_no=s.account_no);
                     update busi_bank_match bank set bank.is_matched='1',bank.match_result='N', bank.flag='3',bank.remark='ƥ�䵽�����������м�¼' where bank.id=v_match_id;
                     delete from busi_bind_bank_card_match bbm where bbm.apply_no=trim(v_apply_no) and bbm.user_name=trim(v_customer_name) and bbm.product_id=v_pt_id and bbm.match_status='0';

                  end if;
               end if;
      end if;

      end loop;
    close sheet_cur;
        commit;

    delete from busi_bank_match t where t.flag in('1')   and t.batch_number=v_batch_number;
    commit;
    v_msg :='ƥ��ɹ�';
    open c_result for select 'success' as res, v_msg as msg from dual;

    exception
         when others then
     DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
     DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
     rollback;
     v_msg:=sqlcode||':'||sqlerrm;
     open c_result for select 'failure', v_msg as msg from dual;
     return;

end TGYW_BANK_MACTH;
/


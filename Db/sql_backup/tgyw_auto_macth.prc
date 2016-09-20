create or replace procedure smzj.tgyw_auto_macth(v_batch_number in varchar2,v_create_date in varchar2,c_result out sys_refcursor) is
v_msg varchar2(255);--������Ϣ
v_custom_name busi_auto_match.custom_name %type;--�ͻ�����
v_credit_no busi_auto_match.credit_no %type;
v_amount busi_auto_match.amount %type;
v_cust_count integer;
v_cust_count_result integer;
v_table_id busi_auto_match.id %type;
v_online_bank_amount number(19,4); --�����ܽ��
v_feerate number(19,4); --����
v_borrow  number(19,4);   --�跽���
v_load number(19,4);    --�������
v_row_no varchar2(255);     --�к�
v_bank_no varchar2(100);     --���п���
v_total_borrow_amount number(19,4);
v_total_load_amount number(19,4);
v_f0103id busi_auto_match.id %type;
v_sheet_no busi_auto_match.sheet_no %type;
v_trade_date busi_auto_match.trading_date %type;
v_identify_flag busi_auto_match.identify_flag %type;
/*type MyRefCurA IS  REF CURSOR RETURN busi_auto_match%RowType;
vRefCurA  MyRefCurA;
vTempA  vRefCurA%RowType;*/

v_max_date busi_auto_match.TRADING_DATE %type;



cursor f0103_cur  is select distinct(t.custom_name),t.credit_no ,t.id,t.sheet_no,t.identify_flag,t.trading_date,t.bank_no  from busi_auto_match t where t.import_flag='1' and t.batch_number=v_batch_number and to_char(t.create_date,'yyyy-MM-dd')=v_create_date;
cursor wyls_cur  is select t.custom_name,t.borrow,t.load,t.row_no,t.id,t.bank_no from busi_auto_match t where t.import_flag='2' and t.batch_number=v_batch_number and to_char(t.create_date,'yyyy-MM-dd')=v_create_date;

begin

    select count(*) into v_cust_count from busi_auto_match t where t.import_flag in('1','2') and t.batch_number=v_batch_number and to_char(t.create_date,'yyyy-MM-dd')=v_create_date;
    if v_cust_count = 0 then
      v_msg :='��δ����ƥ������';
      open c_result for select 'failure' as res, v_msg as msg from dual;
      return;
    end if;

    open f0103_cur;
      loop
       fetch f0103_cur into v_custom_name ,v_credit_no,v_f0103id,v_sheet_no,v_identify_flag,v_trade_date,v_bank_no;
       if f0103_cur%notfound then
        exit;
      end if;
      if trim(v_bank_no) is null then
        update busi_auto_match auto set auto.import_flag='3' , auto.remark='013�ļ��������˺�Ϊ��,�޷�����ƥ��' , auto.state=3 where auto.id=v_f0103id;
      elsif trim(v_custom_name) is null then
           update busi_auto_match auto set auto.import_flag='3' , auto.remark='013�ļ���û�пͻ�����' , auto.state=3 where auto.id=v_f0103id;
       else
                select count(*) into v_cust_count from busi_auto_match t where t.custom_name = trim(v_custom_name) and t.import_flag='2' and t.batch_number=v_batch_number and to_char(t.create_date,'yyyy-MM-dd')=v_create_date;
                select sys_guid() into v_table_id from dual;
                if v_cust_count=0 then
                    insert into busi_auto_match(id,credit_no,custom_name,amount,remark,import_flag,load,borrow,feerate,online_bank_amount,state,batch_number,create_date,sheet_no,identify_flag,trading_date)values(v_table_id,v_credit_no,v_custom_name,0,'0103�ļ���������ˮ�ļ���ƥ�䲻���ͻ���Ϣ','3',0,0,0,0,'3',v_batch_number,to_date(v_create_date,'yyyy-MM-dd'),v_sheet_no,'7',v_trade_date);
                    update busi_sheet s set s.investor_identify_flag='7' where s.sheet_no=v_sheet_no;
                else
                      --����ƥ��ͻ���Ϣʱ�����ܿͻ��ܽ������ʽ����ӣ��跽�ʽ��������з���ʱ���ȳ��Է��ʣ�����0103�ļ���Ա�
                      select sum(t.borrow), sum(t.load),(sum(t.load)-sum(t.borrow)) into v_total_borrow_amount,v_total_load_amount, v_online_bank_amount from busi_auto_match t where t.custom_name = v_custom_name and t.import_flag='2'  and t.batch_number=v_batch_number and to_char(t.create_date,'yyyy-MM-dd')=v_create_date and t.bank_no=v_bank_no;
                      select t.feerate  into v_feerate from busi_auto_match t where t.custom_name = v_custom_name and t.import_flag='2' and rownum=1 and t.batch_number=v_batch_number and to_char(t.create_date,'yyyy-MM-dd')=v_create_date;
                      v_msg:='���ܽ跽��'||to_char(v_total_borrow_amount)||'�����ܴ�����'||to_char(v_total_load_amount);
                      if v_feerate >0 then
                       v_online_bank_amount:=round(v_online_bank_amount/(1+v_feerate));
                      end if;
                        --0103�ļ��пͻ��ж�����ʱ���Ƚ��л���
                      select sum(t.borrow) into v_amount from busi_auto_match t where t.credit_no = v_credit_no and t.import_flag='1' and t.bank_no=v_bank_no  and t.batch_number=v_batch_number and to_char(t.create_date,'yyyy-MM-dd')=v_create_date and t.bank_no=v_bank_no;
                       if (v_amount - v_online_bank_amount)=0 then
                          --��ȡ������ˮ�е������ʱ��
                          select max(m.trading_date) into v_trade_date from busi_auto_match m where m.import_flag='2' and  m.batch_number=v_batch_number and to_char(m.create_date,'yyyy-MM-dd')=v_create_date and m.custom_name=v_custom_name group by m.custom_name,m.create_date;
                          insert into busi_auto_match(id,credit_no,custom_name,amount,online_bank_amount,compare_result,import_flag,remark,feerate,load,borrow,state,batch_number,create_date,sheet_no,identify_flag,trading_date)values(v_table_id,v_credit_no,v_custom_name,v_amount,v_online_bank_amount,'һ��','3',v_msg,v_feerate,0,0,'1',v_batch_number,to_date(v_create_date,'yyyy-MM-dd'),v_sheet_no,'4',v_trade_date);
                          update busi_sheet s set s.investor_identify_flag='4' where s.sheet_no=v_sheet_no;
                       else
                          insert into busi_auto_match(id,credit_no,custom_name,amount,online_bank_amount,compare_result,import_flag,remark,feerate,load,borrow,state,batch_number,create_date,sheet_no,identify_flag,trading_date)values(v_table_id,v_credit_no,v_custom_name,v_amount,v_online_bank_amount,'��һ��','3',v_msg,v_feerate,0,0,'2',v_batch_number,to_date(v_create_date,'yyyy-MM-dd'),v_sheet_no,'7',v_trade_date);
                          declare
                          v_isbank_match varchar2(10); --�����˺�(��ˮ�붩���е������˺��Ƿ�ƥ��)
                          v_isname_match varchar2(10); --����(��ˮ�붩���е������Ƿ�ƥ��)
                          begin
                          select m.custom_name into v_isname_match from busi_auto_match m where m.batch_number=v_batch_number and to_char(m.create_date,'yyyy-MM-dd')=v_create_date and m.bank_no=v_bank_no and m.import_flag='2' and m.custom_name=v_custom_name;
                          select m.bank_no into v_isbank_match from busi_auto_match m where m.batch_number=v_batch_number and to_char(m.create_date,'yyyy-MM-dd')=v_create_date and m.bank_no=v_bank_no and m.import_flag='2' and m.bank_no=v_bank_no;
                          --�ͻ�������ƥ��
                          if v_isbank_match is null then
                           update busi_auto_match m set m.remark='��ˮ��013�ļ��ͻ�������ƥ��' where m.id=v_table_id;
                          --�����˺Ų�ƥ��
                          elsif v_isbank_match is null then
                           update busi_auto_match m set m.remark='��ˮ��013�ļ������˺Ų�ƥ��' where m.id=v_table_id;
                          else --������ˮ�Ľ���붩���еĽ�ƥ��
                           update busi_auto_match m set m.remark='��ˮ��013�ļ���ƥ��' where m.id=v_table_id;
                          end if;
                          end;
                          update busi_sheet s set s.investor_identify_flag='7' where s.sheet_no=v_sheet_no;
                       end if;
                  end if;
      end if;


      end loop;
    close f0103_cur;
        commit;
    open wyls_cur;
     loop
       fetch wyls_cur into v_custom_name ,v_borrow,v_load,v_row_no,v_f0103id,v_bank_no;
        if wyls_cur%notfound then
        exit;
      end if;

       if trim(v_custom_name) is null then
           update busi_auto_match auto set auto.import_flag='3' , auto.remark='������ˮ�ļ���û�пͻ�����' , auto.state=3 where auto.id=v_f0103id;
       elsif trim(v_bank_no) is null then
           update busi_auto_match auto set auto.import_flag='3' , auto.remark='������ˮ�ļ���û�������˺�' , auto.state=3 where auto.id=v_f0103id;
       else
         v_cust_count_result:=0;
            select count(*) into v_cust_count from busi_auto_match t where t.custom_name=v_custom_name and t.import_flag='3' and t.batch_number=v_batch_number and to_char(t.create_date,'yyyy-MM-dd')=v_create_date;
            select count(*) into v_cust_count_result from busi_auto_match m where    m.batch_number=v_batch_number and m.create_date=create_date and m.custom_name=v_custom_name and m.import_flag='3' ;

           if v_cust_count =0 and v_cust_count_result = 0 then
              select sys_guid() into v_table_id from dual;
              select sum(t.borrow), sum(t.load) ,(sum(t.load)-sum(t.borrow)) into v_total_borrow_amount,v_total_load_amount, v_online_bank_amount from busi_auto_match t where t.custom_name=v_custom_name and t.import_flag='2' and t.batch_number=v_batch_number and to_char(t.create_date,'yyyy-MM-dd')=v_create_date;
             v_msg:='���ܽ跽��'||to_char(v_total_borrow_amount)||'�����ܴ�����'||to_char(v_total_load_amount);
            insert into busi_auto_match(id,custom_name,amount,remark,import_flag,borrow,load,feerate,online_bank_amount,state,row_no,batch_number,create_date)values(v_table_id,v_custom_name,0,v_msg||' ������ˮ��0103ˮ�ļ���ƥ�䲻���ͻ���Ϣ','3',0,0,0,nvl(v_online_bank_amount,'0'),'3',v_row_no,v_batch_number,to_date(v_create_date,'yyyy-MM-dd'));
           end if;
       end if;
     end loop;
    close wyls_cur;

     -- ��ȡ����ƥ��ɹ������ʱ�� v_max_date begin
 /* open vRefCurA for  select p1.*
        from busi_auto_match p1 where p1.compare_result = 'һ��' and to_char(p1.create_date,'yyyy-MM-dd')=v_create_date ;
  loop
      fetch vRefCurA into vTempA;
       if vRefCurA%notfound then
            exit;
        end if;
        if vTempA.TRADING_DATE is not null  then
            if v_max_date is not null and (trunc(v_max_date)-trunc(vTempA.TRADING_DATE) < 0)  then
             v_max_date :=vTempA.TRADING_DATE;
           else
              if v_max_date is null  then
               v_max_date :=vTempA.TRADING_DATE;
              end if;
           end if;
    end if;

  end loop;
  close vRefCurA;*/
  select max(p1.trading_date) into v_max_date from busi_auto_match p1 where p1.compare_result = 'һ��' and to_char(p1.create_date,'yyyy-MM-dd')=v_create_date and p1.sheet_no is not null;
   -- ��ȡ����ƥ��ɹ������ʱ�� v_max_date end

    if v_max_date is not null  then
      update busi_sheet t set LAST_CACEL_TIME = v_max_date
      where exists(select 1 from busi_auto_match h where t.sheet_no=h.SHEET_NO and to_char(h.create_date,'yyyy-MM-dd')=v_create_date and h.compare_result='һ��');
/*      where sheet_no is not null and to_char(create_date,'yyyy-MM-dd')=v_create_date;*/
    end if;


    delete from busi_auto_match t where t.import_flag in('1','2')   and t.batch_number=v_batch_number and to_char(t.create_date,'yyyy-MM-dd')=v_create_date;
    commit;
    v_msg :='�Աȳɹ�';
    open c_result for select 'success' as res, v_msg as msg from dual;

    exception
         when others then
     DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
     DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
     rollback;
     v_msg:=sqlcode||':'||sqlerrm;
     open c_result for select 'failure', v_msg as msg from dual;
     return;




end tgyw_auto_macth;
/


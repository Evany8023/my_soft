create or replace procedure smzj.money_match(v_pt_id in varchar2) is

---- *************************************************************************
-- SUBSYS:     �йܷ���
-- PROGRAM:      money_match
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       liujian
-- DESCRIPTION:  �ͷ���̨�����Զ�ƥ��
-- CREATE DATE:  2015-10-23
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

v_credit_no busi_investor_credit.credit_no %type; --֤������
v_custom_name busi_investor.name %type;  --�ͻ�����
v_bank_card_no busi_bind_bank_card.account_no %type; --�����˺�
v_amount busi_sheet.amount %type; --�������

v_buy_fee_rate busi_product.cost_rate %type; --���깺����

v_total_borrow number(19,4); --�跽�ܽ��
v_total_load number(19,4); --�����ܽ��
v_total_money number(19,4); --���ܽ��

v_id varchar2(32); --ƥ����id
v_compares varchar2(8); --ƥ����

cursor sheet_cur is select ct.credit_no, dt.name, cr.account_no, sh.amount  from busi_sheet sh inner join busi_investor_credit ct on ct.id = sh.credit_id inner join busi_investor_detail dt on sh.dt_id = dt.id inner join busi_bind_bank_card cr on cr.id = sh.bank_card_id where sh.pt_id = v_pt_id;

begin
  delete from busi_match_result where pt_id = v_pt_id;
  select pt.cost_rate into v_buy_fee_rate from busi_product pt where id = v_pt_id;
  open sheet_cur;
   loop
     fetch sheet_cur into v_credit_no,v_custom_name,v_bank_card_no,v_amount;
     if sheet_cur%notfound then
       exit;
     end if;
         --���ݿͻ����ơ����š���Ʒid��ѯ������ϸ
     select sum(tr.borrow),sum(tr.loan),(sum(tr.loan)-sum(tr.borrow)) into v_total_borrow,v_total_load,v_total_money  from busi_trading_record tr where tr.name = v_custom_name and tr.account = v_bank_card_no and tr.pt_id = v_pt_id;
     if v_buy_fee_rate > 0 then
        v_total_money:=round(v_total_money/(1+v_buy_fee_rate/100));
     end if;
     select sys_guid() into v_id from dual;
     if v_total_money - v_amount = 0 then
         v_compares := 'һ��';
       else
         v_compares := '��һ��';
     end if;
     insert into busi_match_result(id,credit_no,custom_name,sheet_amount,total_amount,borrow,load,result,pt_id) values (v_id,v_credit_no,v_custom_name,v_amount,v_total_money,v_total_borrow,v_total_load,v_compares,v_pt_id);
   end loop;
   close sheet_cur;
   commit;
end money_match;
/


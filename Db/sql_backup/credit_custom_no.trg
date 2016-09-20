create or replace trigger SMZJ.credit_custom_no
  before insert on busi_investor_credit
  for each row
declare
  -- local variables here
begin
  if :new.custom_no is null then
      select INVESTOR_CUSTOM_NO_SEQUENCE.nextval into:new.custom_no from dual;
  end if;
 
end credit_custom_no;
/


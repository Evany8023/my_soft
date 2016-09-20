create or replace view smzj.vm_company_info as
select c.cp_name comname,c.insti_code comcode,c.create_date,
  (select count(1) from busi_product p where p.cp_id=c.id and p.is_delete='0') as productcode
    from  busi_company c where c.is_delete='0';


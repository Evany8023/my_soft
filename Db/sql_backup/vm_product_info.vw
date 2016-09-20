create or replace view smzj.vm_product_info as
select p.product_no,p.name,c.insti_code as comcode,c.cp_name comname,p.create_date,p.is_grade,p.is_master_code
    from  Busi_Product p inner join busi_company c on c.id=p.cp_id where p.is_delete='0';


create or replace view smzj.v_zx_dx as
select p.product_no fundcode  from  busi_product p where p.is_import_sales='1' and p.is_delete='0';


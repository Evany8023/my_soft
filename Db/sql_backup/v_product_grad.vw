create or replace view smzj.v_product_grad as
select c.id as productid , c.name, c.product_no,c.id,c.cp_id,c.is_show_invetstor from  Busi_Product c where c.parent_id is not  null and c.is_delete='0'
  union all
  select pa.id  as productid,  pa.name, pa.product_no,c.id,pa.cp_id,pa.is_show_invetstor from  Busi_Product c  inner join Busi_Product pa on c.parent_id = pa.id
  where c.is_delete='0' and pa.is_delete='0'
   union all
  select c.id as productid , c.name, c.product_no,c.id,c.cp_id,c.is_show_invetstor from  Busi_Product c where c.parent_id is  null and c.is_delete='0';


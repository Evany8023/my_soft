create or replace view smzj.v_product_q_info as
select p.name,p.product_no,c.cp_name as comname,c.insti_code comcode,
  (select count(1) from busi_quarterly_data d where d.pt_id=p.id ) as iszqup,
  (select count(1) from busi_quarterly_gu_data d where d.pt_id=p.id ) as isgqup,
  (select 1 from busi_quarterly_gu_data d where d.pt_id=p.id ) as isgu,
   (select 1 from busi_quarterly_data d where d.pt_id=p.id ) as iszq
    from  busi_product p inner join busi_company c on p.cp_id=c.id;


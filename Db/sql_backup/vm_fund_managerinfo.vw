create or replace view smzj.vm_fund_managerinfo as
select m.product_no,m.name,m.phone,m.email,m.fax,m.regist_address,m.office_address,m.postcode,m.legal_person,
         m.product_name,c.insti_code as comcode,c.cp_name comname
    from  busi_product_mgr_info m inner join busi_company c on c.id=m.cp_id;


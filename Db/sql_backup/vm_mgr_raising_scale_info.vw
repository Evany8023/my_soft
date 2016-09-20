create or replace view smzj.vm_mgr_raising_scale_info as
select t.pt_name,
       t.pt_no,
       c.cp_name,
       c.insti_code,
       '募集规模证明' as report_type,
       t.report_period,
       '已上传' SCLX,
       t.file_name,
       t.work_day  as WORKDAY,
       t.create_date as UPLOAD_TIME
  from busi_info_download t
 inner join busi_company c
    on c.id = t.mgr_id
 where t.is_delete = '0' and t.report_type='1'

union all
select p.name,
       p.product_no,
       bc.cp_name,
       bc.insti_code,
       '募集规模证明' as report_type,
       '' as report_period,
       '未上传' SCLX,
       '' as file_name,
       '' as WORKDAY,
       NULL as UPLOAD_TIME
  from busi_product p
 inner join busi_company bc
    on bc.id = p.cp_id
 where p.is_delete = '0'
   and not exists
 (select 1 from busi_info_download d where d.pt_id = p.id and d.is_delete='0' and d.report_type='1')
 order by cp_name;


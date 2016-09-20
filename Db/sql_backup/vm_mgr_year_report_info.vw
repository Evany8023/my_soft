create or replace view smzj.vm_mgr_year_report_info as
select t.pt_name,
       t.pt_no,
       c.cp_name,
       c.insti_code,
       '年报' as report_type,
       t.report_period,
       '已上传' SCLX,
       t.file_name,
       (case
         when t.is_send = 1 then
          '是'
         else
          '否'
       end) as FBLX,
       t.create_date as UPLOAD_TIME
  from busi_mgr_report t
 inner join busi_company c
    on c.id = t.mgr_id
 where t.is_delete = '0' and t.report_type='3'

union all
select p.name,
       p.product_no,
       bc.cp_name,
       bc.insti_code,
       '年报' as report_type,
       '' as report_period,
       '未上传' SCLX,
       '' as file_name,
       '' as FBLX,
       null as UPLOAD_TIME
  from busi_product p
 inner join busi_company bc
    on bc.id = p.cp_id
 where p.is_delete = '0'
   and not exists
 (select 1 from busi_mgr_report r where r.pt_id = p.id and r.is_delete='0' and r.report_type='3')
 order by cp_name;


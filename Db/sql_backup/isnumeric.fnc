CREATE OR REPLACE FUNCTION SMZJ.isnumeric(str IN VARCHAR2) return number is
begin
  if str is null then
    RETURN 0;
  ELSE
    --dbms_output.put_line(str);
    IF regexp_like --(str, '^(-{0,1}+{0,1})[0-9]+(.{0,1}[0-9]+)$') --数值
       (str, '^[0-9]*[1-9][0-9]*.[0-9]*$') --正整数
     THEN
      RETURN 1;
    ELSE
      RETURN 0;
    END IF;
  END IF;
END isnumeric;
/


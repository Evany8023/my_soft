CREATE OR REPLACE FUNCTION SMZJ.compare(str1 IN VARCHAR2,str2 IN VARCHAR2) return number is
begin
  IF str1 is null and str2 is null then
    RETURN 1;
  ELSIF str1 is null and str2 is not null THEN
    RETURN 0;
  ELSIF str1 is not null and str2 is null THEN
    RETURN 0;
  ELSE --两个字符串都不为null
    IF str1=str2 THEN
      RETURN 1;
    ELSE
      RETURN 0;
    END IF;
   END IF;


END compare;
/


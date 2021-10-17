-- 실무에 필요한 SQL
### 자주쓰이는 SQL 문법
-- 연산자
-- 단일 행 함수
-- 복수행 함수
-- 윈도우 함수
-- 집합연산자


## 연산자
-- 연산자 종류 : 비교 논리 특수 산술

#1
DESC smember ; 
SELECT *
FROM smember
WHERE addr <> 'seoul';  # 비교연산자 <>
#2
SELECT *
FROM smember
WHERE gender = 'man' AND ageband = '20';  # 비교 연산자 =, 논리 연산자 AND
SELECT *
FROM smember
WHERE (gender = 'man' and ageband = '20') or addr = 'seoul'; # 비교 연산자 =, 논리 연산자 AND ,OR
#3
SELECT *
FROM smember
WHERE ageband BETWEEN 20 AND 40 ; 
SELECT *
FROM smember
WHERE  addr LIKE '%ae%'; 
#4
SELECT *, sales_amt *0.1 AS fees
FROM sorder;
SELECT *, sales_amt *0.1 AS fees, (sales_amt - sales_amt *0.1) AS Excluding_fees
FROM sorder;


## 단일행 함수와 복수행 함수
### 단일행 함수 : 단일 행 대상. - 숫자형,문자, 날짜, 형 변환, 일반
### 복수행 함수 : 복수 행 대상. - 집계, 그룹

-- 단일행 함수
### 매우 많은 케이스가 있다.
SELECT ABS(-123);
SELECT ROUND(1.56,1);
SELECT INSERT('ABCD',2,2,'xx'); #mssql의 STUFF
SELECT INSTR('abaaaabcdef','bc'); # 위치기반 찾기
## 시간함수
SELECT NOW();
SELECT DAYOFWEEK('2021-09-28');
SELECT WEEKDAY('2021-09-28');
SELECT DAYOFYEAR('2021-09-28');
SELECT YEAR('2021-09-28');
SELECT MONTH(now());
SELECT DAYNAME(now());
SELECT QUARTER(now());
SELECT PERIOD_DIFF(201110, 201009);
SELECT CONCAT(YEAR('2021-09-28'), MONTH(now()), DAYOFMONTH(now()));

USE sql_p;
SELECT *, CASE WHEN ageband BETWEEN 20 AND 30 THEN '2030'
				WHEN ageband BETWEEN 340 AND 50 THEN '4050'
                ELSE 'OTHER'
                END AS ageband_seg
FROM smember;
##### CH.5에서 단일행 함수 많이 사용됨.

-- 복수행 함수
DESC smember;
SELECT COUNT(mem_no)
FROM smember;
SELECT gender, COUNT(mem_no)
FROM smember
GROUP BY gender;
DESC sorder;

# GROUP BY & WITH ROLL UP 사용 CASE
SELECT YEAR(order_date) AS 연도,
	channel_code AS 채널코드,
    SUM(sales_amt) AS 주문금액
FROM sorder
GROUP BY YEAR(order_date), channel_code
WITH ROLLUP
ORDER BY 1 DESC, 2 ASC;

## 윈도우 함수
-- 윈도우 함수는 행과 행간의 관계를 정의
USE sql_p;
DESC sorder;
## order_no가 중간에 JUMP되는 현상이 발견됨
SELECT order_no,
	ROW_NUMBER() OVER (ORDER BY order_date ASC) AS ROWNUMBER ,
    order_no - ROW_NUMBER() OVER (ORDER BY order_date ASC) AS GAP
FROM sorder;
# 순위함수 window
SELECT order_date,
	ROW_NUMBER() OVER (ORDER BY order_date ASC) AS ROWNUMBER,
    RANK() OVER (ORDER BY order_date ASC) AS RANKa,
    DENSE_RANK() OVER (ORDER BY order_date ASC) AS DENSE_RANKa
FROM sorder;
SELECT mem_no, order_date,
	ROW_NUMBER() OVER (PARTITION BY mem_no ORDER BY order_date ASC) AS ROWNUMBER,
    RANK() OVER (PARTITION BY mem_no ORDER BY order_date ASC) AS RANKa,
    DENSE_RANK() OVER (PARTITION BY mem_no ORDER BY order_date ASC) AS DENSE_RANKa
FROM sorder;

# 집계함수 window
## 특정기간동안 한 유저의 구매 행태를 보고싶다면...
SELECT mem_no, order_date, sales_amt,
	COUNT(sales_amt) OVER (PARTITION BY mem_no ORDER BY order_date ASC) AS 누적_구매횟수,
    SUM(sales_amt) OVER (PARTITION BY mem_no ORDER BY order_date ASC) AS 누적_구매금액,
    AVG(sales_amt) OVER (PARTITION BY mem_no ORDER BY order_date ASC) AS 누적_평균구매금액,
    MAX(sales_amt) OVER (PARTITION BY mem_no ORDER BY order_date ASC) AS 누적_최대구매액,
    MIN(sales_amt) OVER (PARTITION BY mem_no ORDER BY order_date ASC) AS 누적_최소구매액
FROM sorder;

## 집합연산자
-- 두개이상의 SELECT절을 하나로 결합.
SELECT *,
	COUNT(mem_no) over (ORDER BY mem_no) AS total
FROM member_2;
SELECT * FROM member_1
UNION
SELECT * FROM member_2;
SELECT * FROM member_1
UNION ALL
SELECT * FROM member_2;

# 교집합 INTERSECT ->이거 mysql에서는 안댐.
SELECT * FROM member_1
INTERSECT
SELECT * FROM member_2;
##### 대신 inner join을 이용하자
SELECT * FROM member_2;
SELECT * 
FROM member_1
INNER JOIN member_2 ON  member_1.mem_no = member_2.mem_no;

# 차집합 EXCEPT -> mysql에서 X
SELECT * FROM member_1
EXCEPT
SELECT * FROM member_2;
#### 그렇다면 ANTI JOIN으로 사용
		-- ANTI JOIN : NOT IN 방식
SELECT * FROM member_1
WHERE  member_1.mem_no NOT IN
(SELECT mem_no FROM member_2);

-- ANTI JOIN : LEFT JOIN / IS NULL방식
SELECT * FROM member_1
LEFT JOIN member_2 ON  member_1.mem_no = member_2.mem_no
WHERE member_2.mem_no IS NULL;
##### NULL 값이 있을 경우에는 NOT IN 방식 혹은 not exist 방식을 사용하는게 좋다.


# 효율화 자동화에 쓰이는 SQL 문법
## 1.VIEW 
### 가상 테이블 or 저장된 SQL 명령어
USE sql_p;
DESC smember;
CREATE VIEW order_member
AS 
SELECT A.*,
	B.gender, B.ageband, B.join_date
FROM sorder AS A
LEFT JOIN smember AS B ON A.mem_no = B.mem_no;
# B.mem_no는 중복되는 열 이름으로서 제외했다. VIEW도 가상테이블 임으로  중복열은 용납되지않는다.
SELECT *
FROM order_member;
DROP VIEW order_member;


USE sql_p;
SELECT * FROM order_member;
##PROCEDURE -> 10.1 모닝 수행과제
#### PROCEDURE는 VIEW와 같이 쿼리를 저장하지만 매개변수라는 기능 추가. 자동함수실행기능
SELECT * FROM sorder;
CREATE PROCEDURE order_m
(
 @channal_code AS INT 
 ) 
AS 
	SELECT *
	FROM sorder A
	LEFT JOIN smember B
	ON A.mem_no = B.mem_no
	WHERE A.channel_code = B.channel_code;


## 데이터 마트

#1
USE sql_p;
DESC sorder;
SELECT mem_no, SUM(sales_amt) '총구매액', COUNT(order_no) '구매횟수'
FROM sorder
WHERE YEAR(order_date) =2020
GROUP BY mem_no;
SELECT * FROM sorder;

#2 
SELECT A.*, B.총구매액, B.구매횟수
FROM smember A
LEFT JOIN( SELECT mem_no, SUM(sales_amt) 총구매액, COUNT(order_no) 구매횟수
			FROM sorder
			WHERE YEAR(order_date) =2020
			GROUP BY mem_no ) B
ON A.mem_no = B.mem_no; 

#3 구매여부
SELECT A.*, B.총구매액, B.구매횟수,
		CASE WHEN B.총구매액 IS NULL THEN '미구매'
        ELSE '구매자' END AS 구매여부
FROM smember A
LEFT JOIN( SELECT mem_no, SUM(sales_amt) 총구매액, COUNT(order_no) 구매횟수
			FROM sorder
			WHERE YEAR(order_date) =2020
			GROUP BY mem_no ) B
ON A.mem_no = B.mem_no; 
SELECT * FROM mart_2020;

## 데이터 정합성
#1 2020 데이터 마트에 회원 수 중복여부
SELECT COUNT(mem_no) AS 회원수, COUNT(DISTINCT mem_no) AS 회원수_중복제거
FROM mart_2020;
#2 smember과 mart_2020간의 회원수 차이
SELECT COUNT(mem_no) AS 회원수, COUNT(DISTINCT mem_no) AS 회원수_중복제거
FROM smember;
#3 sorder 테이블과의 주문수 차이
SELECT SUM(order_counts)
FROM mart_2020;
SELECT COUNT(order_no), COUNT(DISTINCT order_no) FROM sorder
WHERE YEAR(order_date)=2020;

#4
SELECT * FROM sorder
WHERE mem_no IN ( SELECT mem_no FROM mart_2020 WHERE purchased = '미구매자' )
		and YEAR(order_date)=2020;

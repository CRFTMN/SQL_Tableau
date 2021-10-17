# mysql 연습
## SELCT절 연습
USE sql_p;
SELECT * FROM smember;
SELECT * FROM smember 
	WHERE gender = 'man' LIMIT 10;
SELECT addr, COUNT(mem_no) AS '남성회원수집계' FROM smember
	WHERE gender = 'man'
    GROUP BY addr;
SELECT addr, COUNT(mem_no) AS '회원수집계' FROM smember
	group by addr;
SELECT addr, COUNT(mem_no) AS '남성회원수 집계' FROM smember
	WHERE gender= 'man'
    GROUP BY addr
    HAVING COUNT(mem_no) >= 50
    ORDER BY COUNT(mem_no) DESC;
DESC smember;

## SQL 문법과 실행순서

### 문법 순서 : SELECT - FROM - WHERE - GROUP BY - ORDER BY
### 실행 순서 : FROM - WHERE - GROUP BY - SELECT - ORDER BY


## JOIN절 연습
### ERM ENtity Relational Modelling
#### 데이터를 구조화 하여 DB에 저장하기 위해 개체-관계 모델링.
#### 디비의 구조 : 회원(개체) - 주문(관계) - 상품(개체)
#### N:1, 1:N -> 1이 PK, N이 FK 관계설정시 나오는 개념.

#### JOIN절 : 여러 테이블 간의 공통값활용 
DESC sorder;

-- INNER JOIN
SELECT * FROM smember AS A
	INNER JOIN sorder AS B
    ON A.mem_no = B.mem_no;
    
-- LEFT JOIN
SELECT * FROM smember AS A
	LEFT JOIN sorder AS B
    ON A.mem_no = B.mem_no
    WHERE order_date is NUll;

-- CROSS JOIN
SELECT * FROM smember AS A
	CROSS JOIN sorder AS B
    ON A.mem_no = 1000001;

-- SELF JOIN
SELECT * FROM smember AS A, smember AS B
WHERE A.mem_no = 1000001;

## 서브쿼리 연습
### 하나의 SQL명령어는 '메인쿼리'라 하며 SELECT, FROM, WHERE절 뒤의 명령어는 '서브쿼리'다. 
-- SELECT절
SELECT *, 
	(SELECT gender FROM smember AS B
		WHERE A.mem_no = B.mem_no) AS gender
	FROM sorder AS A;
-- FROM 절
SELECT * 
FROM (SELECT mem_no, SUM(sales_amt) AS tot_amt
		FROM sorder
        GROUP BY mem_no) B;

SELECT * 
FROM ( SELECT mem_no, SUM(sales_amt) AS tot_amt
	FROM sorder
	GROUP BY mem_no) A
LEFT JOIN smember AS B
ON A.mem_no = B.mem_no;

-- WHERE절 서브쿼리 ( 일반 서브쿼리 ) 
#### 단일행 서브쿼리에서는 비교연산자 사용
SELECT * FROM sorder
WHERE mem_no = (SELECT mem_no FROM smember where mem_no = '1000005');

SELECT mem_no FROM smember WHERE mem_no = '1000005';

#### 다중행 서브쿼리
SELECT * FROM sorder 
WHERE mem_no IN ( SELECT mem_no From smember WHERE gender = 'man');

SELECT mem_no From smember WHERE gender = 'man';

## 3장을 마치며... 연습!!!
### SELECT절 연습
#1
SELECT * FROM sorder;
#2
SELECT * FROM sorder
WHERE shop_code >= 30;
#3
SELECT mem_no, SUM(sales_amt) AS tot_amt FROM sorder
GROUP BY mem_no;
#4
SELECT mem_no, SUM(sales_amt) AS tot_amt FROM sorder
WHERE shop_code >= 30
GROUP BY mem_no
HAVING SUM(sales_amt) >= 100000 ;
#5
SELECT mem_no, SUM(sales_amt) AS tot_amt FROM sorder
WHERE shop_code >= 30
GROUP BY mem_no
HAVING SUM(sales_amt) >= 100000 
ORDER BY SUM(sales_amt) DESC;

### SELECT + JOIN + Sub-Query절 연습
## JOIN 활용
#1
SELECT * FROM sorder AS A
LEFT JOIN smember AS B
ON A.mem_no = B.mem_no;
#2                                이거좀 까다롭네...
SELECT A.gender, SUM(B.sales_amt) AS tot_sum FROM smember as A
LEFT JOIN sorder AS B
ON A.mem_no = B.mem_no
GROUP BY A.gender;
#3
SELECT B.gender, B.addr, SUM(A.sales_amt) AS tot_amt 
FROM sorder AS A LEFT JOIN smember AS B
	ON A.mem_no = B.mem_no 
GROUP BY B.gender, B.addr;

## JOIN + SUB_QUERY
#1
SELECT mem_no, SUM(sales_amt) as tot_amt 
FROM sorder
GROUP BY mem_no;
#2
SELECT *
FROM ( SELECT mem_no, SUM(sales_amt) as tot_amt 
	FROM sorder
    GROUP by mem_no) AS A
LEFT JOIN smember AS B
ON A.mem_no = B.mem_no;
#3
SELECT B.gender, B.addr, SUM(A.tot_amt) AS '합계'
FROM (SELECT mem_no, SUM(sales_amt) AS tot_amt
	FROM sorder
	GROUP BY mem_no) AS A
LEFT JOIN smember AS B
ON A.mem_no = B.mem_no
GROUP BY B.gender, B.addr;



DESC smember;

### 기억하고 있나 TEST ###
--  90점 정도... 잘했다 이정도면 9/28
#1
SELECT mem_no, SUM(sales_amt) AS tot_amt
FROM sorder
GROUP BY mem_no;
#2
SELECT *
FROM (SELECT mem_no, SUM(sales_amt) AS tot_amt
	FROM sorder
	GROUP BY mem_no) A
LEFT JOIN smember AS B
ON A.mem_no = B.mem_no;

#3
SELECT B.gender, B.addr, SUM(tot_amt) AS '합계'
FROM (SELECT mem_no, SUM(sales_amt) AS tot_amt
	FROM sorder
	GROUP BY mem_no) A
LEFT JOIN smember AS B
ON A.mem_no = B.mem_no
GROUP BY B.gender, B.addr;

DESC smember;
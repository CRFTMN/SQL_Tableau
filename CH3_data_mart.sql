# 마치며 - 데이터 마트
##분석 목적에 맞게 데이터를 가공한 분석용 세트
-- 분석목적 : 2020년 주문금액 및 건수를 회원 프로파일
USE sql_p;
SELECT * FROM sorder;
#1
SELECT mem_no, SUM(sales_amt) AS tot_amt, COUNT(order_no) AS order_counts
FROM sorder
WHERE YEAR(order_date) = 2020
GROUP BY mem_no;

#2
SELECT *
FROM smember A
LEFT JOIN (SELECT mem_no, SUM(sales_amt) AS tot_amt, COUNT(order_no) AS order_counts
	FROM sorder
	WHERE YEAR(order_date) = 2020
	GROUP BY mem_no) B
ON A.mem_no = B.mem_no;

#3
SELECT A.*, B.tot_amt, B.order_counts,
		CASE WHEN B.tot_amt IS NULL THEN '미구매자'
			ELSE '구매자' END AS purchased    
FROM smember A
LEFT JOIN (SELECT mem_no, SUM(sales_amt) AS tot_amt, COUNT(order_no) AS order_counts
	FROM sorder
	WHERE YEAR(order_date) = 2020
	GROUP BY mem_no) B
ON A.mem_no = B.mem_no;

#4
CREATE TABLE mart_2020  
	AS (SELECT A.*, B.tot_amt, B.order_counts,
	CASE WHEN B.tot_amt IS NULL THEN '미구매자'
		ELSE '구매자' END AS purchased    
	FROM smember A
	LEFT JOIN (SELECT mem_no, SUM(sales_amt) AS tot_amt, COUNT(order_no) AS order_counts
		FROM sorder
		WHERE YEAR(order_date) = 2020
		GROUP BY mem_no) B
	ON A.mem_no = B.mem_no);
    
## 데이터 정합성
### 데이터 정합성 :  분석값들이 일관되게 일치함.
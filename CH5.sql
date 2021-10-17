USE car_data_p;

-- 1.1분석용 테이블 작성
CREATE TABLE car_mart 
	AS (SELECT A.order_no
				, A.mem_no
				, A.order_date
				, A.store_cd
				, D.store_addr
				, B.gender
				, B.age
				, B.addr
				, B.join_date
				, C.prod_cd
				, C.quantity
				, E.brand
				, E.type
				, E.model
				, E.price
				, (E.price * C.quantity) AS sales_amt

		FROM car_order A
			LEFT JOIN car_member B ON A.mem_no = B.mem_no 
			LEFT JOIN car_orderdetail C ON A.order_no = C.order_no
			LEFT JOIN car_store D ON A.store_cd = D.store_cd
			LEFT JOIN car_product E ON C.prod_cd = E.prod_cd );

SELECT * FROM car_mart;

-- 1.2 구매고객 프로파일 분석
# 인구학적 구매자 파악
## 분석을 위한 임시테이블 생성
CREATE TEMPORARY TABLE profile_base
	AS(SELECT * 
		,CASE WHEN age <20 THEN '20대 미만'
			  WHEN age BETWEEN 20 AND 29 THEN '20대'
              WHEN age BETWEEN 30 AND 39 THEN '30대'
              WHEN age BETWEEN 40 AND 49 THEN '40대'
              WHEN age BETWEEN 50 AND 59 THEN '50대'
              ELSE '60대 이상' END AS ageband
	   FROM car_mart);
#### 참고 WHEN 20<= age <30 THEN '20대'와 같은 이중 비교연산자는 허용되지 않는다. 이 경우 between이나 and를 사용해서 구간을 만들어야한다.
SELECT * FROM profile_base; 

## 임시 테이블을 이용한 연령대별 구매자 분포
### 성별 구매자 문포
SELECT gender
		, COUNT( DISTINCT mem_no ) AS tot_mem
FROM profile_base
GROUP BY gender;

### 연령대별 구매자 문포
SELECT ageband
		, COUNT( DISTINCT mem_no ) AS tot_mem
FROM profile_base
GROUP BY ageband;

###  성별, 연령대별 구매자 문포
SELECT  gender, ageband
		, COUNT( DISTINCT mem_no ) AS tot_mem
FROM profile_base
GROUP BY  gender, ageband;

### 성별, 연령대별 구매자 문포 연도간 비교
SELECT  gender, ageband
		, COUNT(DISTINCT CASE WHEN YEAR(order_date)=2020 THEN mem_no END) AS orders_2020
        , COUNT(DISTINCT CASE WHEN YEAR(order_date)=2021 THEN mem_no END) AS orders_2021
FROM profile_base
GROUP BY  gender, ageband
WITH ROLLUP
ORDER BY gender;

#임시 테이블 삭제
DROP TABLE RFM_base_seg;

-- 1.2 RFM 고객세분화 분석
# 구매지표 활용 세분화 RFM : Recency 최근성, Frecuency 구매빈도, Monetary 구매금액
SELECT * FROM car_mart;
## 분석을 위한 임시테이블 생성
CREATE TEMPORARY TABLE RFM_base
	AS(SELECT mem_no
			, SUM(sales_amt) AS tot_amt
            , COUNT(order_no) AS tot_fr
		FROM car_mart
        WHERE YEAR(order_date) BETWEEN 2020 AND 2021
        GROUP BY mem_no);

SELECT * FROM RFM_base;
SELECT * FROM car_member;

## RFM기준 고객 등급 부여
CREATE TEMPORARY TABLE RFM_base_seg
	AS (SELECT A.*
				, B.tot_amt
                , B.tot_fr
                , CASE WHEN B.tot_amt >= 1000000000 AND B.tot_fr >= 3 THEN '1_VVIP'
					   WHEN B.tot_amt >= 500000000 AND B.tot_fr >= 2 THEN '2_VIP'
                       WHEN B.tot_amt >= 300000000  THEN '3_GOLD'
                       WHEN B.tot_amt >= 100000000  THEN '4_SILVER'
                       WHEN B.tot_fr >= 1 THEN '5_BRONZE'
                       ELSE '6_POTENTIAL' END AS segmentation
		FROM car_member A
        LEFT JOIN RFM_base B
        ON A.mem_no = B.mem_no);
        

SELECT * FROM RFM_base_seg;
### 고객수 및 매출비중 파악
SELECT segmentation
		, COUNT(mem_no) AS tot_mem
        , SUM(tot_amt) AS tot_amt
FROM RFM_base_seg
GROUP BY segmentation
ORDER BY 1;

#### 추가 부분 : 그룹별 비중
SELECT segmentation, tot_mem, tot_amt
 FROM (SELECT segmentation
		, COUNT(mem_no) AS tot_mem
        , SUM(tot_amt) AS tot_amt
FROM RFM_base_seg
GROUP BY segmentation
ORDER BY 1) A
UNION
SELECT SUM(tot_amt) FROM RFM_base_seg;

-- 1.3 구매 전환율 구매주기 분석
# 고객의 구매패턴 파악. (2020구매자중 2021 구매여부 파악)
SELECT * FROM car_mart;
CREATE TEMPORARY TABLE retention_base
	AS (SELECT A.mem_no AS mem2020
		, B.mem_no AS mem2021
        , CASE WHEN B.mem_no IS NOT NULL THEN 'Y' ELSE 'N' END AS retention_yn
		FROM (SELECT DISTINCT mem_no FROM car_mart WHERE YEAR(order_date) =2020) A
        LEFT JOIN (SELECT DISTINCT mem_no FROM car_mart WHERE YEAR(order_date) =2021) B
        ON A.mem_no = B.mem_no);
SELECT * fROM retention_base;

SELECT COUNT(mem2020) AS tot_mem
		,COUNT(CASE WHEN retention_yn = 'Y' THEN mem2020 END) AS retention_mem
FROM retention_base;

### 구매주기 분석
USE car_data_p;
SELECT * FROM car_mart;
SELECT store_addr, order_no, order_date
FROM car_mart
GROUP BY store_addr, order_no
ORDER BY store_addr;


CREATE TEMPORARY TABLE cycle_base
	AS (SELECT store_cd
				,MIN(order_date) AS min_order_date
                ,MAX(order_date) AS max_order_date
                ,COUNT(DISTINCT order_no) -1 AS tot_tr_1
		FROM car_mart
        GROUP BY store_cd
        HAVING COUNT(DISTINCT order_no) >2);

SELECT * FROM cycle_base;

### cycle_base 를 활용한 구매주기 파악
#### 매장별 구매주기
SELECT *
	, DATEDIFF(max_order_date, min_order_date) AS diff_day
	, DATEDIFF(max_order_date, min_order_date)/tot_tr_1 AS cycle	
FROM cycle_base
ORDER BY cycle ASC;

-- 1.4 제품 및 성장률 분석
# 상품들의 경쟁력을 파악
SELECT brand, model, SUM(quantity) AS tot_quan, SUM(sales_amt) AS tot_sales
FROM car_mart
GROUP BY brand, model;

CREATE TEMPORARY TABLE product_growth_base
	AS( SELECT brand
		, model
        , SUM(CASE WHEN YEAR(order_date)=2020 THEN sales_amt END) AS tot_amt_2020
        , SUM(CASE WHEN YEAR(order_date)=2021 THEN sales_amt END) AS tot_amt_2021
		FROM car_mart
		GROUP BY brand, model);

SELECT * FROM product_growth_base;

### product_growth_base 테이블을 이용한 브랜드 성장률
SELECT brand
		, (SUM(tot_amt_2021)/SUM(tot_amt_2020)) -1 AS growth
FROM product_growth_base
GROUP BY brand;

### product_growth_base 테이블을 이용한 모델별 성장률 
#1
SELECT brand, model
		, (SUM(tot_amt_2021)/SUM(tot_amt_2020)) -1 AS growth
FROM product_growth_base
GROUP BY brand, model;

#2
SELECT *
		,ROW_NUMBER() OVER(PARTITION BY brand ORDER BY growth DESC) AS rnk
FROM(SELECT brand, model
		, (SUM(tot_amt_2021)/SUM(tot_amt_2020)) -1 AS growth
FROM product_growth_base
GROUP BY brand, model) A;

#3 주요모델(상위2개) 만 필터링
SELECT *
FROM (SELECT *
				,ROW_NUMBER() OVER(PARTITION BY brand ORDER BY growth DESC) AS rnk
		FROM(SELECT brand, model
				, (SUM(tot_amt_2021)/SUM(tot_amt_2020)) -1 AS growth
		FROM product_growth_base
		GROUP BY brand, model) A) B
WHERE rnk <=2;

/* Проект Анализ рынка недвижимости Санкт-Петербурга и Ленинградской области
 * Цель проекта: Проведение комплексного анализа рынка жилой недвижимости Санкт-Петербурга и Ленинградской области
 *  для определения наиболее перспективных сегментов и разработки эффективной бизнес-стратегии.
 
 * Автор:КРАСАВЦЕВА ВИКТОРИЯ ИГОРЕВНА  
 * Дата: 27.12.2024
*/



WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
-- Выведем объявления без выбросов:
select region,activity,number_of_ads,one_square_meter,avg_square,median_room,median_balcony,median_floor
from (select case 
	when city='Санкт-Петербург' 
	then 'Санкт-Петербург' 
	else 'Ленинградская область'
end as region ,--категория по городу
CASE
        WHEN days_exposition<=30
        THEN 'До месяца'
        WHEN days_exposition>30 and days_exposition<=90
        THEN 'До трех месяцев'
        WHEN days_exposition>90 and days_exposition<=180
        THEN 'До полугода'
        else 'Более полугода'
        END AS activity ,--категория по активности 
round(avg(last_price/total_area)) as one_square_meter,--цена за 1 кв м
round(avg(total_area)) as avg_square,--средняя площадь
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY rooms) as median_room,--медиана комнаты 
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY balcony) as median_balcony,--медиана балконы
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY floor) as median_floor,--медиана этаж 
count(first_day_exposition) as number_of_ads
FROM real_estate.flats f
join real_estate.city c using(city_id)
join real_estate.advertisement a using(id)
join real_estate."type" t using(type_id)
WHERE id IN (SELECT * FROM filtered_id) and type='город' and days_exposition is not null -- фильтр по городу и значений без нулл
group by region,activity
order by region desc) as tab1;--первая задача
 

WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ) ,
tab1 as (
select extract(month from a.first_day_exposition::date) AS month,
count(first_day_exposition) as number_of_ads,--кол-во объявлений
rank() over (order by count(*) desc) AS rank_ads
from real_estate.advertisement a 
join real_estate.flats f using(id)
join real_estate."type" t using(type_id)
where type='город' and extract(year from a.first_day_exposition) between 2015 and 2018 and id in(select* from filtered_id)
group by extract(month from a.first_day_exposition::date)
) , tab2 as
(select extract(month from first_day_exposition + days_exposition * INTERVAL '1 day') AS month, 
count(first_day_exposition) as number_withdrawals,
round(AVG(last_price/total_area)) as one_square_meter,
round(avg(total_area)) as avg_square,
RANK() OVER (ORDER BY COUNT(*) DESC) as rank_with
from real_estate.advertisement a 
join real_estate.flats f using(id)
join real_estate."type" t using(type_id)
where type='город' and days_exposition is not null and extract(year from a.first_day_exposition) between 2015 and 2018 and id in(select* from filtered_id)
group by extract(month from first_day_exposition + days_exposition * INTERVAL '1 day'))
select t1.month as month,number_of_ads,number_withdrawals,one_square_meter,avg_square,rank_ads,rank_with
from tab1 as t1
full join tab2 as t2 on t1.month=t2.month
order by month;-- задача 2

WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
select city,count(first_day_exposition) as total ,count(days_exposition) as number_withdrawals, round(avg(last_price/total_area)) as one_square_meter,--цена за 1 кв м
round(avg(total_area)) as avg_square,--средняя площадь
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY rooms) as median_room,--медиана комнаты 
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY floor) as media_page,--медиана этаж  
round(avg(days_exposition)) as length_of_public, --продолжительность_публикаций
count(days_exposition)/count(first_day_exposition)::numeric as percentage_removed--доля снятых объявлений--number_withdrawals/total
FROM real_estate.advertisement a 
join real_estate.flats f using(id)
join real_estate.city c  using(city_id)
join real_estate."type" t  using(type_id)
where city<>'Санкт-Петербург' and id in(select* from filtered_id)
group by city
order by number_withdrawals desc
limit 15;--третья задача 

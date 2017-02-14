use movedb;

/* Step 1:
Create 2 table that contains the information we needed from different dates
*/

CREATE TABLE position_old AS (SELECT `As of Date`,
    `Account Number`,
    `Security ID`,
    `Shares`,
    `Asset Description`,
    `MV - Local` FROM
    position
WHERE
    `As of Date` = '2014-12-12 00:00:00.000'
        AND LENGTH(`Account Number`) > 1
        AND `Security ID` IS NOT NULL
        AND `Security ID` <> '');

CREATE TABLE position_new AS (SELECT `As of Date` AS `New Date`,
    `Account Number` AS `New Account Number`,
    `Security ID` AS `New Security ID`,
    `Shares` AS `New Shares`,
    `Asset Description` AS `New Asset Description`,
    `MV - Local` AS `New MV - Local` FROM
    position
WHERE
    `As of Date` = '2014-12-15 00:00:00.000'
        AND LENGTH(`Account Number`) > 1
        AND `Security ID` IS NOT NULL
        AND `Security ID` <> '');

/* Step 2:
Merge table data by accout number. One should notice that there is no full join statement in Mysql, thus one has to union left join and right join.
At last, only select rows which shares had changed, and create a new table
*/

CREATE TABLE position_compare 
	SELECT * FROM
		position_new
	LEFT JOIN
		position_old 
	ON position_new.`New Account Number` = position_old.`Account Number`
		AND position_new.`New Security ID` = position_old.`Security ID`
	WHERE
		`New Shares` <> `Shares` OR `Account Number` IS NULL 
		
	UNION 
    
	SELECT *
	FROM
		position_new
	RIGHT JOIN
		position_old 
	ON position_new.`New Account Number` = position_old.`Account Number`
		AND position_new.`New Security ID` = position_old.`Security ID`
	WHERE
		`New Shares` <> `Shares`
		OR `New Account Number` IS NULL
            
	ORDER BY `Account Number` , `New Account Number` , `Security ID`;
 
/* Step 3:
Add two otther column at the end of our new table which is the change of shares and market value. By simply using function coalesce, 
it can automatically return the first not null value. In our case, if both new and used shares has value, then function return the 
substraction. else if new shares is null, which means manager had sold all of that stock, function would return negative original shares. 
else function return new shares, indicates that this is a fresh position made by manager.
*/

ALTER TABLE position_compare 
	ADD COLUMN `Share Change` DOUBLE,
    ADD COLUMN `MV Change` DOUBLE;


UPDATE position_compare 
SET 
    `Share Change` = COALESCE(`New Shares` - `Shares`,
            `New Shares`,
            - `Shares`),
    `MV Change` = COALESCE(`New MV - Local` - `MV - Local`,
            `New MV - Local`,
            - `MV - Local`);


/* Step 4:
Now fill all the null value such as account number, shares, etc. as the new value. If there is a null share in new position,
means share should be zero
*/



UPDATE position_compare 
SET 
    `New Date` = '2014-12-15 00:00:00.000',
    `Account Number` = `New Account Number`,
    `Security ID` = `New Security ID`,
    `Shares` = 0,
    `Asset Description` = `New Asset Description`,
    `MV - Local` = 0
WHERE
    `MV - Local` IS NULL;


UPDATE position_compare 
SET 
    `New Shares` = 0,
    `New MV - Local` = 0,
    `As of Date` = '2014-12-12 00:00:00.000'
WHERE
    `New MV - Local` IS NULL;


/* Step 5:
Select a nice format which we want
*/
SELECT 
    `Account Number`,
    `Security ID`,
    `Shares`,
    `New Shares`,
    `MV - Local`,
    `New MV - Local`,
    `Asset Description`,
    `Share Change`,
    `MV Change`
FROM
    position_compare
ORDER BY `Account Number`;
    
    
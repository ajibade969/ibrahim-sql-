-- Q1: Identify the top 5 long-term clients based on total transaction frequency rather than monetary volume.
SELECT 
    c.CustomerID,
    p.FirstName,
    p.LastName,
    COUNT(soh.SalesOrderID) AS OrderFrequencyCount
FROM sales_customer c
INNER JOIN sales_salesorderheader soh ON c.CustomerID = soh.CustomerID
INNER JOIN person_person p ON c.PersonID = p.BusinessEntityID
GROUP BY c.CustomerID, p.FirstName, p.LastName
ORDER BY OrderFrequencyCount DESC
LIMIT 5;

-- Q2: Determine the total physical unit volumes sold and average discount rate applied within each product category.
SELECT 
    pc.Name AS ProductCategory,
    SUM(sod.OrderQty) AS AggregateUnitsSold,
    AVG(sod.UnitPriceDiscount) AS AverageDiscountPercentage
FROM Production_ProductCategory pc
INNER JOIN Production_ProductSubcategory psc ON pc.ProductCategoryID = psc.ProductCategoryID
INNER JOIN Production_Product prod ON psc.ProductSubcategoryID = prod.ProductSubcategoryID
INNER JOIN Sales_SalesOrderDetail sod ON prod.ProductID = sod.ProductID
GROUP BY pc.Name
ORDER BY AggregateUnitsSold DESC;


-- Q3: Calculate the monthly average order value (AOV) over time to track macro purchasing inflation trends.
SELECT
    YEAR(soh.OrderDate) AS CalendarYear,
    MONTH(soh.OrderDate) AS CalendarMonth,
    SUM(sod.LineTotal) / COUNT(DISTINCT soh.SalesOrderID) AS AverageOrderValue
FROM Sales_SalesOrderHeader soh
INNER JOIN Sales_SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY
    YEAR(soh.OrderDate),
    MONTH(soh.OrderDate)
ORDER BY
    CalendarYear,
    CalendarMonth;

-- Q4: Isolate monthly fulfillment volume stability across years by tracking pure transaction counts.
SELECT 
    YEAR(soh.OrderDate) AS OperationsYear,
    MONTH(soh.OrderDate) AS OperationsMonth,
    COUNT(soh.SalesOrderID) AS TotalFulfillmentLoad
FROM Sales_SalesOrderHeader soh
INNER JOIN Sales_SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY YEAR(soh.OrderDate), MONTH(soh.OrderDate)
ORDER BY TotalFulfillmentLoad DESC;

-- Q5: Isolate global territories requiring the highest geographic market diversity based on unique cities served.
SELECT 
    cr.Name AS CountryRegion,
    sp.Name AS StateProvince,
    COUNT(DISTINCT a.City) AS UniqueCitiesServed
FROM Person_Address a
INNER JOIN Person_StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
INNER JOIN Person_CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
INNER JOIN Sales_SalesOrderHeader soh ON a.AddressID = soh.ShipToAddressID
GROUP BY cr.Name, sp.Name
ORDER BY UniqueCitiesServed DESC
LIMIT 10;

-- Q6: Analyze sales force logistics performance by auditing average processing speeds from order to ship date.
SELECT
    p.FirstName,
    p.LastName,
    AVG(DATEDIFF(soh.ShipDate, soh.OrderDate)) AS AvgTurnaroundDays,
    COUNT(soh.SalesOrderID) AS ManagedTransactions
FROM Sales_SalesPerson sp
INNER JOIN Person_Person p
    ON sp.BusinessEntityID = p.BusinessEntityID
INNER JOIN Sales_SalesOrderHeader soh
    ON sp.BusinessEntityID = soh.SalesPersonID
GROUP BY p.FirstName, p.LastName
ORDER BY AvgTurnaroundDays ASC;

-- Q7: Benchmark carrier operational risks by measuring maximum and minimum logistics shipment delay caps.
SELECT 
    sm.Name AS LogisticsCarrier,
    MAX(DATEDIFF(soh.ShipDate, soh.OrderDate)) AS PeakDelayDays,
    MIN(DATEDIFF(soh.ShipDate, soh.OrderDate)) AS FloorDelayDays
FROM Purchasing_ShipMethod sm
INNER JOIN Sales_SalesOrderHeader soh ON sm.ShipMethodID = soh.ShipMethodID
GROUP BY sm.Name
ORDER BY PeakDelayDays DESC;

-- Q8: Assess customer credit card payment risk profile by tracking average ticket sizes across networks.
SELECT 
    cc.CardType,
    AVG(soh.TotalDue) AS MeanTransactionValue,
    COUNT(soh.SalesOrderID) AS NetworkVolume
FROM Sales_CreditCard cc
INNER JOIN Sales_SalesOrderHeader soh ON cc.CreditCardID = soh.CreditCardID
GROUP BY cc.CardType
ORDER BY MeanTransactionValue DESC;

-- Q9: Surface inventory control alerts for safety stock items that are completely out of warehouse stock.
SELECT 
    p.ProductID,
    p.Name AS DepletedItemName,
    p.SafetyStockLevel AS TargetedBuffer,
    SUM(pi.Quantity) AS ActualWarehouseCount
FROM Production_Product p
INNER JOIN Production_ProductInventory pi ON p.ProductID = pi.ProductID
GROUP BY p.ProductID, p.Name, p.SafetyStockLevel
HAVING SUM(pi.Quantity) = 0
ORDER BY TargetedBuffer DESC;


-- Q10: Profile procurement catalog depth and pricing variance thresholds across external vendor partners.
SELECT 
    v.Name AS VendorPartner,
    COUNT(p.ProductID) AS UniqueItemsSupplied,
    MAX(pv.StandardPrice) AS PeakContractPrice,
    MIN(pv.StandardPrice) AS MinimumContractPrice
FROM Purchasing_Vendor v
INNER JOIN Purchasing_ProductVendor pv ON v.BusinessEntityID = pv.BusinessEntityID
INNER JOIN Production_Product p ON pv.ProductID = p.ProductID
WHERE v.ActiveFlag = 1
GROUP BY v.Name
ORDER BY UniqueItemsSupplied DESC;

-- Q11: Identify severe vendor manufacturing bottlenecks where total rejected item counts exceed 100 units.
SELECT 
    p.Name AS ProcuredProduct,
    SUM(pod.RejectedQty) AS TotalUnitsRejected,
    SUM(pod.ReceivedQty) AS TotalUnitsAccepted
FROM Production_Product p
INNER JOIN Purchasing_PurchaseOrderDetail pod ON p.ProductID = pod.ProductID
GROUP BY p.Name
HAVING SUM(pod.RejectedQty) > 100
ORDER BY TotalUnitsRejected DESC;

-- Q12: Highlight economy product offerings whose list price falls completely below the average of their subcategory peer groups.
SELECT 
    p.Name AS EconomyProduct,
    p.ListPrice AS BudgetPrice,
    ps.Name AS SubcategorySegment
FROM Production_Product p
INNER JOIN Production_ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
WHERE p.ListPrice < (
    SELECT AVG(sub_p.ListPrice) 
    FROM Production_Product sub_p 
    WHERE sub_p.ProductSubcategoryID = p.ProductSubcategoryID
)
ORDER BY SubcategorySegment, BudgetPrice ASC;

-- Q13: Flag commercial orders driven by extreme bulk volume demands (single line-item quantities exceeding 50 units).
SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    CONCAT(p.FirstName, ' ', p.LastName) AS AccountManager,
    soh.TotalDue AS InvoiceGrandTotal
FROM Sales_SalesOrderHeader soh
INNER JOIN Sales_SalesPerson sp ON soh.SalesPersonID = sp.BusinessEntityID
INNER JOIN Person_Person p ON sp.BusinessEntityID = p.BusinessEntityID
WHERE soh.SalesOrderID IN (
    SELECT SalesOrderID 
    FROM Sales_SalesOrderDetail 
 WHERE OrderQty > 50
);

-- Q14: Isolate lower-tier consumer segments who fall below the global average engagement count threshold.
SELECT 
    c.CustomerID,
    p.FirstName,
    p.LastName,
    COUNT(soh.SalesOrderID) AS CustomerLifetimeOrders
FROM Sales_Customer c
INNER JOIN Sales_SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
INNER JOIN Person_Person p ON c.PersonID = p.BusinessEntityID
GROUP BY c.CustomerID, p.FirstName, p.LastName
HAVING COUNT(soh.SalesOrderID) < (
    -- Subquery to calculate global system-wide mean order count per account
    SELECT AVG(CustomerTotals.OrderCount)
    FROM (
        SELECT COUNT(SalesOrderID) AS OrderCount
        FROM Sales_SalesOrderHeader
        GROUP BY CustomerID
    ) AS CustomerTotals
)
ORDER BY CustomerLifetimeOrders ASC;


-- Q15: Track corporate workforce compensation milestones by auditing sales professionals earning premium bonuses.
SELECT 
    p.FirstName,
    p.LastName,
    e.JobTitle,
    sp.SalesYTD AS RevenueGeneratedYTD,
    sp.Bonus AS DisbursedBonusCommissions
FROM HumanResources_Employee e
INNER JOIN Person_Person p ON e.BusinessEntityID = p.BusinessEntityID
INNER JOIN Sales_SalesPerson sp ON e.BusinessEntityID = sp.BusinessEntityID
WHERE sp.Bonus > 5000
ORDER BY DisbursedBonusCommissions DESC;
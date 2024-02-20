-- phpMyAdmin SQL Dump
-- version 5.0.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 17, 2023 at 09:22 AM
-- Server version: 10.4.10-MariaDB
-- PHP Version: 7.2.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `restaurant`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteCustomersByDomain` (IN `Domain` VARCHAR(255))  BEGIN
    DELETE FROM customer
    WHERE Email LIKE CONCAT('%@', Domain);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteExpiredPromotions` ()  BEGIN
    DELETE FROM promotion
    WHERE EndDate < CURDATE();
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DisplayAllCustomers` ()  BEGIN
    SELECT * FROM customer;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DisplayRestaurantMenuInformation` ()  BEGIN
    -- Declare variables for cursor
    DECLARE done INT DEFAULT FALSE;
    DECLARE restaurantName VARCHAR(255);
    DECLARE menuName VARCHAR(255);
    
    -- Declare cursor for the Restaurant table
    DECLARE curRestaurant CURSOR FOR
        SELECT Name FROM Restaurant;
    
    -- Declare cursor for the Menu table
    DECLARE curMenu CURSOR FOR
        SELECT ItemName FROM Menu;
    
    -- Declare variables for dynamic SQL
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    SET SESSION group_concat_max_len = 1000000;
    SET @sql = '';
    
    -- Loop through Restaurant table and build SQL
    OPEN curRestaurant;
    read_restaurant_loop:LOOP
        FETCH curRestaurant INTO restaurantName;
        IF done THEN
            LEAVE read_restaurant_loop;
        END IF;
        
        -- Build SQL for Restaurant data
        SET @sql = CONCAT(@sql, 'SELECT * FROM Restaurant WHERE Name = "', restaurantName, '"; ');
    END LOOP;
    CLOSE curRestaurant;
    
    -- Loop through Menu table and build SQL
    OPEN curMenu;
    read_menu_loop: LOOP
        FETCH curMenu INTO menuName;
        IF done THEN
            LEAVE read_menu_loop;
        END IF;
        
        -- Build SQL for Menu data
        SET @sql = CONCAT(@sql, 'SELECT * FROM Menu WHERE ItemName = "', menuName, '"; ');
    END LOOP;
    CLOSE curMenu;
    
    -- Execute the generated SQL to display data
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetHighestOrderAmountForCustomer` (IN `CustomerID` INT)  BEGIN
    SELECT MAX(TotalAmount) AS HighestOrderAmount
    FROM foodorder
    WHERE CustomerID = CustomerID;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertCustomer` (IN `FirstName` VARCHAR(255), IN `LastName` VARCHAR(255), IN `Email` VARCHAR(255), IN `PhoneNumber` VARCHAR(20), IN `DeliveryAddress` VARCHAR(255), IN `PaymentInfo` VARCHAR(255))  BEGIN
    INSERT INTO customer (FirstName, LastName, Email, PhoneNumber, DeliveryAddress, PaymentInfo)
    VALUES (FirstName, LastName, Email, PhoneNumber, DeliveryAddress, PaymentInfo);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateCustomerEmailById` (IN `CustomerId` INT, IN `NewEmail` VARCHAR(255))  BEGIN
    UPDATE customer
    SET Email = NewEmail
    WHERE CustomerID = CustomerId;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `combinedinformation`
-- (See below for the actual view)
--
CREATE TABLE `combinedinformation` (
`CustomerID` int(11)
,`FirstName` varchar(255)
,`LastName` varchar(255)
,`CustomerEmail` varchar(255)
,`CustomerPhoneNumber` varchar(20)
,`CustomerDeliveryAddress` varchar(255)
,`CustomerPaymentInfo` varchar(255)
,`OrderID` int(11)
,`OrderCustomerID` int(11)
,`OrderRestaurantID` int(11)
,`OrderDateTime` datetime
,`OrderStatus` varchar(50)
,`OrderTotalAmount` decimal(10,2)
,`RestaurantID_R` int(11)
,`RestaurantName` varchar(255)
,`RestaurantAddress` varchar(255)
,`RestaurantPhone` varchar(20)
,`RestaurantEmail` varchar(255)
,`RestaurantCuisineType` varchar(100)
,`RestaurantAverageRating` decimal(3,2)
,`MenuID_M` int(11)
,`MenuItemName` varchar(255)
,`MenuItemDescription` text
,`MenuItemPrice` decimal(8,2)
,`MenuItemCategory` varchar(100)
,`MenuItemAvailability` tinyint(1)
,`MenuItemIngredients` text
);

-- --------------------------------------------------------

--
-- Table structure for table `customer`
--

CREATE TABLE `customer` (
  `CustomerID` int(11) NOT NULL,
  `FirstName` varchar(255) DEFAULT NULL,
  `LastName` varchar(255) DEFAULT NULL,
  `Email` varchar(255) DEFAULT NULL,
  `PhoneNumber` varchar(20) DEFAULT NULL,
  `DeliveryAddress` varchar(255) DEFAULT NULL,
  `PaymentInfo` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `customer`
--

INSERT INTO `customer` (`CustomerID`, `FirstName`, `LastName`, `Email`, `PhoneNumber`, `DeliveryAddress`, `PaymentInfo`) VALUES
(0, NULL, NULL, 'junior@gmail.com', NULL, NULL, NULL),
(1, 'John', 'Doe', 'junior@gmail.com', '555-987-6543', '456 Elm St', 'Credit Card: ****-****-****-1234'),
(2, 'MUHIRE', 'jac', 'junior@gmail.com', '07185423', 'huye', 'mtn');

--
-- Triggers `customer`
--
DELIMITER $$
CREATE TRIGGER `AfterDeleteCustomer` AFTER DELETE ON `customer` FOR EACH ROW BEGIN
    INSERT INTO customer_deletion_log (DeletedCustomerID, DeletionDateTime)
    VALUES (OLD.CustomerID, NOW());
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `AfterInsertCustomer` AFTER INSERT ON `customer` FOR EACH ROW BEGIN
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `customerorderview`
-- (See below for the actual view)
--
CREATE TABLE `customerorderview` (
`CustomerID` int(11)
,`FirstName` varchar(255)
,`LastName` varchar(255)
,`Email` varchar(255)
,`OrderID` int(11)
,`OrderDateTime` datetime
,`TotalAmount` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Table structure for table `foodorder`
--

CREATE TABLE `foodorder` (
  `OrderID` int(11) NOT NULL,
  `CustomerID` int(11) DEFAULT NULL,
  `RestaurantID` int(11) DEFAULT NULL,
  `OrderDateTime` datetime DEFAULT NULL,
  `Status` varchar(50) DEFAULT NULL,
  `TotalAmount` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `foodorder`
--

INSERT INTO `foodorder` (`OrderID`, `CustomerID`, `RestaurantID`, `OrderDateTime`, `Status`, `TotalAmount`) VALUES
(1, 1, 1, '2023-09-16 12:30:00', 'Pending', '12.99');

--
-- Triggers `foodorder`
--
DELIMITER $$
CREATE TRIGGER `AfterInsertFoodOrder` AFTER INSERT ON `foodorder` FOR EACH ROW BEGIN
    INSERT INTO paymenttransaction (OrderID, CustomerID, PaymentDateTime, PaymentMethod, Amount)
    VALUES (NEW.OrderID, NEW.CustomerID, NOW(), 'Credit Card', NEW.TotalAmount);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `insertdataview`
-- (See below for the actual view)
--
CREATE TABLE `insertdataview` (
`FirstName` varchar(6)
,`LastName` varchar(7)
,`Email` varchar(23)
,`PhoneNumber` varchar(10)
);

-- --------------------------------------------------------

--
-- Table structure for table `inventory`
--

CREATE TABLE `inventory` (
  `InventoryID` int(11) NOT NULL,
  `RestaurantID` int(11) DEFAULT NULL,
  `ItemName` varchar(255) DEFAULT NULL,
  `QuantityInStock` int(11) DEFAULT NULL,
  `ReorderPoint` int(11) DEFAULT NULL,
  `SupplierInfo` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `inventory`
--

INSERT INTO `inventory` (`InventoryID`, `RestaurantID`, `ItemName`, `QuantityInStock`, `ReorderPoint`, `SupplierInfo`) VALUES
(1, 1, 'Pasta', 100, 20, 'Supplier ABC');

-- --------------------------------------------------------

--
-- Table structure for table `menu`
--

CREATE TABLE `menu` (
  `MenuID` int(11) NOT NULL,
  `RestaurantID` int(11) DEFAULT NULL,
  `ItemName` varchar(255) DEFAULT NULL,
  `Description` text DEFAULT NULL,
  `Price` decimal(8,2) DEFAULT NULL,
  `Category` varchar(100) DEFAULT NULL,
  `Availability` tinyint(1) DEFAULT NULL,
  `Ingredients` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `menu`
--

INSERT INTO `menu` (`MenuID`, `RestaurantID`, `ItemName`, `Description`, `Price`, `Category`, `Availability`, `Ingredients`) VALUES
(1, 1, 'Spaghetti Carbonara', 'Classic Italian pasta dish with bacon and eggs.', '12.99', 'Main Course', 1, 'Pasta, Bacon, Eggs, Parmesan Cheese'),
(5, 5, 'Spaghetti', ' dish with bacon and eggs.', '12.99', 'Main Course', 1, 'Pasta, Bacon, Eggs, Parmesan Cheese');

-- --------------------------------------------------------

--
-- Table structure for table `paymenttransaction`
--

CREATE TABLE `paymenttransaction` (
  `TransactionID` int(11) NOT NULL,
  `OrderID` int(11) DEFAULT NULL,
  `CustomerID` int(11) DEFAULT NULL,
  `PaymentDateTime` datetime DEFAULT NULL,
  `PaymentMethod` varchar(100) DEFAULT NULL,
  `Amount` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `paymenttransaction`
--

INSERT INTO `paymenttransaction` (`TransactionID`, `OrderID`, `CustomerID`, `PaymentDateTime`, `PaymentMethod`, `Amount`) VALUES
(1, 1, 1, '2023-09-16 13:00:00', 'Credit Card', '12.99');

-- --------------------------------------------------------

--
-- Table structure for table `promotion`
--

CREATE TABLE `promotion` (
  `PromotionID` int(11) NOT NULL,
  `RestaurantID` int(11) DEFAULT NULL,
  `PromotionName` varchar(255) DEFAULT NULL,
  `Description` text DEFAULT NULL,
  `StartDate` date DEFAULT NULL,
  `EndDate` date DEFAULT NULL,
  `DiscountPercentage` decimal(5,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `promotion`
--

INSERT INTO `promotion` (`PromotionID`, `RestaurantID`, `PromotionName`, `Description`, `StartDate`, `EndDate`, `DiscountPercentage`) VALUES
(1, 1, 'Weekend Special', '20% off on all main courses', '2023-09-23', '2023-09-25', '20.00');

-- --------------------------------------------------------

--
-- Table structure for table `restaurant`
--

CREATE TABLE `restaurant` (
  `RestaurantID` int(11) NOT NULL,
  `Name` varchar(255) DEFAULT NULL,
  `Address` varchar(255) DEFAULT NULL,
  `Phone` varchar(20) DEFAULT NULL,
  `Email` varchar(255) DEFAULT NULL,
  `CuisineType` varchar(100) DEFAULT NULL,
  `AverageRating` decimal(3,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `restaurant`
--

INSERT INTO `restaurant` (`RestaurantID`, `Name`, `Address`, `Phone`, `Email`, `CuisineType`, `AverageRating`) VALUES
(1, 'Sample Restaurant', 'kigali', '555-123-4567', 'sample@example.com', 'Italian', '4.50'),
(2, 'MUHIRE JUNIOR', 'HUYE', '078625178', 'muhire@example.com', 'rwanda', '4.50'),
(3, 'MUHIMA Restaurant', 'MUHIMA', '0782372725', 'muhima@res.com', 'Rwandan', '4.50'),
(5, 'MUHIMA Restaurant', 'MUHIMA', '0782372725', 'muhima@res.com', 'Rwandan', '4.50');

-- --------------------------------------------------------

--
-- Stand-in structure for view `restaurantmanagementview`
-- (See below for the actual view)
--
CREATE TABLE `restaurantmanagementview` (
`RestaurantID_R` int(11)
,`RestaurantName` varchar(255)
,`RestaurantAddress` varchar(255)
,`RestaurantPhone` varchar(20)
,`RestaurantEmail` varchar(255)
,`RestaurantCuisineType` varchar(100)
,`RestaurantAverageRating` decimal(3,2)
,`MenuID_M` int(11)
,`MenuItemName` varchar(255)
,`MenuItemDescription` text
,`MenuItemPrice` decimal(8,2)
,`MenuItemCategory` varchar(100)
,`MenuItemAvailability` tinyint(1)
,`MenuItemIngredients` text
,`CustomerID_C` int(11)
,`CustomerFirstName` varchar(255)
,`CustomerLastName` varchar(255)
,`CustomerEmail` varchar(255)
,`CustomerPhoneNumber` varchar(20)
,`CustomerDeliveryAddress` varchar(255)
,`CustomerPaymentInfo` varchar(255)
,`OrderID_O` int(11)
,`OrderCustomerID` int(11)
,`OrderRestaurantID` int(11)
,`OrderDateTime` datetime
,`OrderStatus` varchar(50)
,`OrderTotalAmount` decimal(10,2)
,`StaffID_S` int(11)
,`StaffRestaurantID` int(11)
,`StaffFirstName` varchar(255)
,`StaffLastName` varchar(255)
,`StaffRole` varchar(100)
,`StaffContactInfo` varchar(255)
,`StaffWorkSchedule` text
,`ReviewID_RV` int(11)
,`ReviewCustomerID` int(11)
,`ReviewRestaurantID` int(11)
,`ReviewRating` int(11)
,`ReviewText` text
,`ReviewDateTime` datetime
,`ReservationID_TR` int(11)
,`ReservationCustomerID` int(11)
,`ReservationRestaurantID` int(11)
,`ReservationDateTime` datetime
,`ReservationNumGuests` int(11)
,`ReservationSpecialRequests` text
,`PromotionID_P` int(11)
,`PromotionRestaurantID` int(11)
,`PromotionName` varchar(255)
,`PromotionDescription` text
,`PromotionStartDate` date
,`PromotionEndDate` date
,`PromotionDiscountPercentage` decimal(5,2)
,`InventoryID_I` int(11)
,`InventoryRestaurantID` int(11)
,`InventoryItemName` varchar(255)
,`InventoryQuantityInStock` int(11)
,`InventoryReorderPoint` int(11)
,`InventorySupplierInfo` varchar(255)
,`TransactionID_PT` int(11)
,`TransactionOrderID` int(11)
,`TransactionCustomerID` int(11)
,`TransactionPaymentDateTime` datetime
,`TransactionPaymentMethod` varchar(100)
,`TransactionAmount` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Table structure for table `review`
--

CREATE TABLE `review` (
  `ReviewID` int(11) NOT NULL,
  `CustomerID` int(11) DEFAULT NULL,
  `RestaurantID` int(11) DEFAULT NULL,
  `Rating` int(11) DEFAULT NULL,
  `ReviewText` text DEFAULT NULL,
  `DateTime` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `review`
--

INSERT INTO `review` (`ReviewID`, `CustomerID`, `RestaurantID`, `Rating`, `ReviewText`, `DateTime`) VALUES
(1, 1, 1, 5, 'Excellent food and service!', '2023-09-17 15:45:00');

-- --------------------------------------------------------

--
-- Table structure for table `staff`
--

CREATE TABLE `staff` (
  `StaffID` int(11) NOT NULL,
  `RestaurantID` int(11) DEFAULT NULL,
  `FirstName` varchar(255) DEFAULT NULL,
  `LastName` varchar(255) DEFAULT NULL,
  `Role` varchar(100) DEFAULT NULL,
  `ContactInfo` varchar(255) DEFAULT NULL,
  `WorkSchedule` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `staff`
--

INSERT INTO `staff` (`StaffID`, `RestaurantID`, `FirstName`, `LastName`, `Role`, `ContactInfo`, `WorkSchedule`) VALUES
(1, 1, 'Maria', 'Garcia', 'Chef', 'maria@example.com', 'Mon-Fri: 9 AM - 5 PM');

-- --------------------------------------------------------

--
-- Table structure for table `tablereservation`
--

CREATE TABLE `tablereservation` (
  `ReservationID` int(11) NOT NULL,
  `CustomerID` int(11) DEFAULT NULL,
  `RestaurantID` int(11) DEFAULT NULL,
  `ReservationDateTime` datetime DEFAULT NULL,
  `NumGuests` int(11) DEFAULT NULL,
  `SpecialRequests` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tablereservation`
--

INSERT INTO `tablereservation` (`ReservationID`, `CustomerID`, `RestaurantID`, `ReservationDateTime`, `NumGuests`, `SpecialRequests`) VALUES
(1, 1, 1, '2023-09-20 19:00:00', 4, 'Window seat preferred');

-- --------------------------------------------------------

--
-- Stand-in structure for view `topcustomersview`
-- (See below for the actual view)
--
CREATE TABLE `topcustomersview` (
`CustomerID` int(11)
,`FirstName` varchar(255)
,`LastName` varchar(255)
,`Email` varchar(255)
,`PhoneNumber` varchar(20)
,`HighestTotalOrderAmount` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `top_customers_view`
-- (See below for the actual view)
--
CREATE TABLE `top_customers_view` (
`CustomerID` int(11)
,`FirstName` varchar(255)
,`LastName` varchar(255)
,`Email` varchar(255)
,`PhoneNumber` varchar(20)
,`HighestTotalOrderAmount` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Structure for view `combinedinformation`
--
DROP TABLE IF EXISTS `combinedinformation`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `combinedinformation`  AS  select `c`.`CustomerID` AS `CustomerID`,`c`.`FirstName` AS `FirstName`,`c`.`LastName` AS `LastName`,`c`.`Email` AS `CustomerEmail`,`c`.`PhoneNumber` AS `CustomerPhoneNumber`,`c`.`DeliveryAddress` AS `CustomerDeliveryAddress`,`c`.`PaymentInfo` AS `CustomerPaymentInfo`,`o`.`OrderID` AS `OrderID`,`o`.`CustomerID` AS `OrderCustomerID`,`o`.`RestaurantID` AS `OrderRestaurantID`,`o`.`OrderDateTime` AS `OrderDateTime`,`o`.`Status` AS `OrderStatus`,`o`.`TotalAmount` AS `OrderTotalAmount`,`r`.`RestaurantID` AS `RestaurantID_R`,`r`.`Name` AS `RestaurantName`,`r`.`Address` AS `RestaurantAddress`,`r`.`Phone` AS `RestaurantPhone`,`r`.`Email` AS `RestaurantEmail`,`r`.`CuisineType` AS `RestaurantCuisineType`,`r`.`AverageRating` AS `RestaurantAverageRating`,`m`.`MenuID` AS `MenuID_M`,`m`.`ItemName` AS `MenuItemName`,`m`.`Description` AS `MenuItemDescription`,`m`.`Price` AS `MenuItemPrice`,`m`.`Category` AS `MenuItemCategory`,`m`.`Availability` AS `MenuItemAvailability`,`m`.`Ingredients` AS `MenuItemIngredients` from (((`customer` `c` left join `foodorder` `o` on(`c`.`CustomerID` = `o`.`CustomerID`)) left join `restaurant` `r` on(`o`.`RestaurantID` = `r`.`RestaurantID`)) left join `menu` `m` on(`r`.`RestaurantID` = `m`.`RestaurantID`)) ;

-- --------------------------------------------------------

--
-- Structure for view `customerorderview`
--
DROP TABLE IF EXISTS `customerorderview`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `customerorderview`  AS  select `c`.`CustomerID` AS `CustomerID`,`c`.`FirstName` AS `FirstName`,`c`.`LastName` AS `LastName`,`c`.`Email` AS `Email`,`o`.`OrderID` AS `OrderID`,`o`.`OrderDateTime` AS `OrderDateTime`,`o`.`TotalAmount` AS `TotalAmount` from (`customer` `c` join `foodorder` `o` on(`c`.`CustomerID` = `o`.`CustomerID`)) ;

-- --------------------------------------------------------

--
-- Structure for view `insertdataview`
--
DROP TABLE IF EXISTS `insertdataview`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `insertdataview`  AS  select 'Junior' AS `FirstName`,'RUKUNDO' AS `LastName`,'juniorrukundo@gmail.com' AS `Email`,'0782678789' AS `PhoneNumber` union all select 'Junior' AS `FirstName`,'RUKUNDO' AS `LastName`,'juniorrukundo@gmail.com' AS `Email`,'0789823' AS `PhoneNumber` ;

-- --------------------------------------------------------

--
-- Structure for view `restaurantmanagementview`
--
DROP TABLE IF EXISTS `restaurantmanagementview`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `restaurantmanagementview`  AS  select `r`.`RestaurantID` AS `RestaurantID_R`,`r`.`Name` AS `RestaurantName`,`r`.`Address` AS `RestaurantAddress`,`r`.`Phone` AS `RestaurantPhone`,`r`.`Email` AS `RestaurantEmail`,`r`.`CuisineType` AS `RestaurantCuisineType`,`r`.`AverageRating` AS `RestaurantAverageRating`,`m`.`MenuID` AS `MenuID_M`,`m`.`ItemName` AS `MenuItemName`,`m`.`Description` AS `MenuItemDescription`,`m`.`Price` AS `MenuItemPrice`,`m`.`Category` AS `MenuItemCategory`,`m`.`Availability` AS `MenuItemAvailability`,`m`.`Ingredients` AS `MenuItemIngredients`,`c`.`CustomerID` AS `CustomerID_C`,`c`.`FirstName` AS `CustomerFirstName`,`c`.`LastName` AS `CustomerLastName`,`c`.`Email` AS `CustomerEmail`,`c`.`PhoneNumber` AS `CustomerPhoneNumber`,`c`.`DeliveryAddress` AS `CustomerDeliveryAddress`,`c`.`PaymentInfo` AS `CustomerPaymentInfo`,`o`.`OrderID` AS `OrderID_O`,`o`.`CustomerID` AS `OrderCustomerID`,`o`.`RestaurantID` AS `OrderRestaurantID`,`o`.`OrderDateTime` AS `OrderDateTime`,`o`.`Status` AS `OrderStatus`,`o`.`TotalAmount` AS `OrderTotalAmount`,`s`.`StaffID` AS `StaffID_S`,`s`.`RestaurantID` AS `StaffRestaurantID`,`s`.`FirstName` AS `StaffFirstName`,`s`.`LastName` AS `StaffLastName`,`s`.`Role` AS `StaffRole`,`s`.`ContactInfo` AS `StaffContactInfo`,`s`.`WorkSchedule` AS `StaffWorkSchedule`,`rv`.`ReviewID` AS `ReviewID_RV`,`rv`.`CustomerID` AS `ReviewCustomerID`,`rv`.`RestaurantID` AS `ReviewRestaurantID`,`rv`.`Rating` AS `ReviewRating`,`rv`.`ReviewText` AS `ReviewText`,`rv`.`DateTime` AS `ReviewDateTime`,`tr`.`ReservationID` AS `ReservationID_TR`,`tr`.`CustomerID` AS `ReservationCustomerID`,`tr`.`RestaurantID` AS `ReservationRestaurantID`,`tr`.`ReservationDateTime` AS `ReservationDateTime`,`tr`.`NumGuests` AS `ReservationNumGuests`,`tr`.`SpecialRequests` AS `ReservationSpecialRequests`,`p`.`PromotionID` AS `PromotionID_P`,`p`.`RestaurantID` AS `PromotionRestaurantID`,`p`.`PromotionName` AS `PromotionName`,`p`.`Description` AS `PromotionDescription`,`p`.`StartDate` AS `PromotionStartDate`,`p`.`EndDate` AS `PromotionEndDate`,`p`.`DiscountPercentage` AS `PromotionDiscountPercentage`,`i`.`InventoryID` AS `InventoryID_I`,`i`.`RestaurantID` AS `InventoryRestaurantID`,`i`.`ItemName` AS `InventoryItemName`,`i`.`QuantityInStock` AS `InventoryQuantityInStock`,`i`.`ReorderPoint` AS `InventoryReorderPoint`,`i`.`SupplierInfo` AS `InventorySupplierInfo`,`pt`.`TransactionID` AS `TransactionID_PT`,`pt`.`OrderID` AS `TransactionOrderID`,`pt`.`CustomerID` AS `TransactionCustomerID`,`pt`.`PaymentDateTime` AS `TransactionPaymentDateTime`,`pt`.`PaymentMethod` AS `TransactionPaymentMethod`,`pt`.`Amount` AS `TransactionAmount` from (((((((((`restaurant` `r` left join `menu` `m` on(`r`.`RestaurantID` = `m`.`RestaurantID`)) left join `customer` `c` on(1 = 1)) left join `foodorder` `o` on(`c`.`CustomerID` = `o`.`CustomerID`)) left join `staff` `s` on(`r`.`RestaurantID` = `s`.`RestaurantID`)) left join `review` `rv` on(`r`.`RestaurantID` = `rv`.`RestaurantID`)) left join `tablereservation` `tr` on(`c`.`CustomerID` = `tr`.`CustomerID`)) left join `promotion` `p` on(`r`.`RestaurantID` = `p`.`RestaurantID`)) left join `inventory` `i` on(`r`.`RestaurantID` = `i`.`RestaurantID`)) left join `paymenttransaction` `pt` on(`o`.`OrderID` = `pt`.`OrderID`)) ;

-- --------------------------------------------------------

--
-- Structure for view `topcustomersview`
--
DROP TABLE IF EXISTS `topcustomersview`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `topcustomersview`  AS  select `c`.`CustomerID` AS `CustomerID`,`c`.`FirstName` AS `FirstName`,`c`.`LastName` AS `LastName`,`c`.`Email` AS `Email`,`c`.`PhoneNumber` AS `PhoneNumber`,`co`.`TotalAmount` AS `HighestTotalOrderAmount` from ((`customer` `c` join (select `foodorder`.`CustomerID` AS `CustomerID`,max(`foodorder`.`TotalAmount`) AS `HighestTotalAmount` from `foodorder` group by `foodorder`.`CustomerID`) `maxtotalamounts` on(`c`.`CustomerID` = `maxtotalamounts`.`CustomerID`)) join `foodorder` `co` on(`c`.`CustomerID` = `co`.`CustomerID` and `co`.`TotalAmount` = `maxtotalamounts`.`HighestTotalAmount`)) ;

-- --------------------------------------------------------

--
-- Structure for view `top_customers_view`
--
DROP TABLE IF EXISTS `top_customers_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `top_customers_view`  AS  select `c`.`CustomerID` AS `CustomerID`,`c`.`FirstName` AS `FirstName`,`c`.`LastName` AS `LastName`,`c`.`Email` AS `Email`,`c`.`PhoneNumber` AS `PhoneNumber`,`co`.`TotalAmount` AS `HighestTotalOrderAmount` from ((`customer` `c` join (select `foodorder`.`CustomerID` AS `CustomerID`,max(`foodorder`.`TotalAmount`) AS `HighestTotalAmount` from `foodorder` group by `foodorder`.`CustomerID`) `max_total_amounts` on(`c`.`CustomerID` = `max_total_amounts`.`CustomerID`)) join `foodorder` `co` on(`c`.`CustomerID` = `co`.`CustomerID` and `co`.`TotalAmount` = `max_total_amounts`.`HighestTotalAmount`)) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `customer`
--
ALTER TABLE `customer`
  ADD PRIMARY KEY (`CustomerID`);

--
-- Indexes for table `foodorder`
--
ALTER TABLE `foodorder`
  ADD PRIMARY KEY (`OrderID`),
  ADD KEY `CustomerID` (`CustomerID`),
  ADD KEY `RestaurantID` (`RestaurantID`);

--
-- Indexes for table `inventory`
--
ALTER TABLE `inventory`
  ADD PRIMARY KEY (`InventoryID`),
  ADD KEY `RestaurantID` (`RestaurantID`);

--
-- Indexes for table `menu`
--
ALTER TABLE `menu`
  ADD PRIMARY KEY (`MenuID`),
  ADD KEY `RestaurantID` (`RestaurantID`);

--
-- Indexes for table `paymenttransaction`
--
ALTER TABLE `paymenttransaction`
  ADD PRIMARY KEY (`TransactionID`),
  ADD KEY `OrderID` (`OrderID`),
  ADD KEY `CustomerID` (`CustomerID`);

--
-- Indexes for table `promotion`
--
ALTER TABLE `promotion`
  ADD PRIMARY KEY (`PromotionID`),
  ADD KEY `RestaurantID` (`RestaurantID`);

--
-- Indexes for table `restaurant`
--
ALTER TABLE `restaurant`
  ADD PRIMARY KEY (`RestaurantID`);

--
-- Indexes for table `review`
--
ALTER TABLE `review`
  ADD PRIMARY KEY (`ReviewID`),
  ADD KEY `CustomerID` (`CustomerID`),
  ADD KEY `RestaurantID` (`RestaurantID`);

--
-- Indexes for table `staff`
--
ALTER TABLE `staff`
  ADD PRIMARY KEY (`StaffID`),
  ADD KEY `RestaurantID` (`RestaurantID`);

--
-- Indexes for table `tablereservation`
--
ALTER TABLE `tablereservation`
  ADD PRIMARY KEY (`ReservationID`),
  ADD KEY `CustomerID` (`CustomerID`),
  ADD KEY `RestaurantID` (`RestaurantID`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `foodorder`
--
ALTER TABLE `foodorder`
  ADD CONSTRAINT `foodorder_ibfk_1` FOREIGN KEY (`CustomerID`) REFERENCES `customer` (`CustomerID`),
  ADD CONSTRAINT `foodorder_ibfk_2` FOREIGN KEY (`RestaurantID`) REFERENCES `restaurant` (`RestaurantID`);

--
-- Constraints for table `inventory`
--
ALTER TABLE `inventory`
  ADD CONSTRAINT `inventory_ibfk_1` FOREIGN KEY (`RestaurantID`) REFERENCES `restaurant` (`RestaurantID`);

--
-- Constraints for table `menu`
--
ALTER TABLE `menu`
  ADD CONSTRAINT `menu_ibfk_1` FOREIGN KEY (`RestaurantID`) REFERENCES `restaurant` (`RestaurantID`);

--
-- Constraints for table `paymenttransaction`
--
ALTER TABLE `paymenttransaction`
  ADD CONSTRAINT `paymenttransaction_ibfk_1` FOREIGN KEY (`OrderID`) REFERENCES `foodorder` (`OrderID`),
  ADD CONSTRAINT `paymenttransaction_ibfk_2` FOREIGN KEY (`CustomerID`) REFERENCES `customer` (`CustomerID`);

--
-- Constraints for table `promotion`
--
ALTER TABLE `promotion`
  ADD CONSTRAINT `promotion_ibfk_1` FOREIGN KEY (`RestaurantID`) REFERENCES `restaurant` (`RestaurantID`);

--
-- Constraints for table `review`
--
ALTER TABLE `review`
  ADD CONSTRAINT `review_ibfk_1` FOREIGN KEY (`CustomerID`) REFERENCES `customer` (`CustomerID`),
  ADD CONSTRAINT `review_ibfk_2` FOREIGN KEY (`RestaurantID`) REFERENCES `restaurant` (`RestaurantID`);

--
-- Constraints for table `staff`
--
ALTER TABLE `staff`
  ADD CONSTRAINT `staff_ibfk_1` FOREIGN KEY (`RestaurantID`) REFERENCES `restaurant` (`RestaurantID`);

--
-- Constraints for table `tablereservation`
--
ALTER TABLE `tablereservation`
  ADD CONSTRAINT `tablereservation_ibfk_1` FOREIGN KEY (`CustomerID`) REFERENCES `customer` (`CustomerID`),
  ADD CONSTRAINT `tablereservation_ibfk_2` FOREIGN KEY (`RestaurantID`) REFERENCES `restaurant` (`RestaurantID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

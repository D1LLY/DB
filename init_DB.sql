-- Delete database and create from scratch
DROP DATABASE IF EXISTS Caregivers;
CREATE DATABASE Caregivers;
USE Caregivers;

-- On insert, sets default balance, hourlyRate, rating, numParents, and memberID
CREATE TABLE member (
    memberID INT PRIMARY KEY AUTO_INCREMENT,
    balance FLOAT DEFAULT 2000.00,
    username CHAR(24),
    passwd VARCHAR(255),
    address VARCHAR(255),
    phoneNumber CHAR(10),
    availability INT,
    averageRating DECIMAL(2, 1) DEFAULT 0.0,
    hourlyRate DECIMAL(10, 2) DEFAULT 30.00,
    numParents INT DEFAULT 0
);

-- On insertion of a new contract, attempts to deduct balance from client
-- Updates the week table for the caretaker and initializes it with the available hours for each week from the contract
-- dailyHoursWorked is multiplied by however many parents the client has
CREATE TABLE contracts (
    contractID INT PRIMARY KEY AUTO_INCREMENT,
    caretakerID INT,
    clientID INT,
    startDate DATE,
    endDate DATE,
    dailyHoursWorked INT,
    status ENUM('pending', 'accepted', 'denied') DEFAULT 'pending',
    requestID INT,
    FOREIGN KEY (caretakerID) REFERENCES member(memberID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (clientID) REFERENCES member(memberID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- On inserting a review, updates the caretaker average rating
CREATE TABLE reviews (
    caretakerID INT, -- References member.memberID
    memberID INT,    -- References member.memberID
    contractID INT PRIMARY KEY AUTO_INCREMENT,  -- References contracts.contractID
    rating INT CHECK (rating BETWEEN 1 AND 5),
    dateOfCompletion DATE, -- the endDate of the contract.contractID
    FOREIGN KEY (caretakerID) REFERENCES member(memberID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (memberID) REFERENCES member(memberID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (contractID) REFERENCES contracts(contractID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Stores details of parents associated with members
CREATE TABLE parents (
    parentID INT AUTO_INCREMENT PRIMARY KEY,  -- Unique parent ID
    memberID INT,
    parentName VARCHAR(100),
    age INT,
    needs TEXT,
    FOREIGN KEY (memberID) REFERENCES member(memberID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- A 7-day range (Monday to Sunday) of the caretaker's week
CREATE TABLE weeks (
    startOfWeek DATE, -- Monday of the current week
    endOfWeek DATE, -- Sunday following this Monday
    caretakerID INT,
    totalHoursAvailable INT, -- How many hours a caretaker has available in this week range
    PRIMARY KEY (startOfWeek, caretakerID),
    FOREIGN KEY (caretakerID) REFERENCES member(memberID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Stores care requests by members
CREATE TABLE care_requests (
    requestID INT AUTO_INCREMENT PRIMARY KEY,
    memberID INT NOT NULL,
    parentID INT NOT NULL,
    startDate DATE NOT NULL,
    startTime TIME NOT NULL,
    endDate DATE NOT NULL,
    endTime TIME NOT NULL,
    FOREIGN KEY (memberID) REFERENCES member(memberID),
    FOREIGN KEY (parentID) REFERENCES parents(parentID)
);

-- Triggers
-- When inserting a contract, check if client has enough money, create new work weeks for caretaker if non-existent, pay the caretaker
DELIMITER //
CREATE TRIGGER updateBalanceAndActiveWeeksWorked
BEFORE INSERT ON contracts
FOR EACH ROW
BEGIN
    DECLARE totalPayment DECIMAL(10, 2);
    DECLARE clientBalance DECIMAL(10, 2);
    DECLARE currentDate DATE;
    DECLARE startOfWeek DATE;
    DECLARE endOfWeek DATE;

    -- Calculate the total amount for the contract (payment to caretaker)
    SET totalPayment = (DATEDIFF(NEW.endDate, NEW.startDate) + 1) * NEW.dailyHoursWorked * 
                        (SELECT m.hourlyRate FROM member m WHERE m.memberID = NEW.caretakerID) *
                        (SELECT m.numParents FROM member m WHERE m.memberID = NEW.clientID);

    -- Check the client's balance to ensure they have enough funds
    SELECT m.balance INTO clientBalance
    FROM member m
    WHERE m.memberID = NEW.clientID;

    -- If the client does not have enough balance, raise an error
    IF clientBalance < totalPayment THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Client does not have enough balance to pay for the contract';
    END IF;

    -- Update the caretaker's balance by adding the payment
    UPDATE member m
    SET m.balance = m.balance + totalPayment
    WHERE m.memberID = NEW.caretakerID;

    -- Deduct the total payment from the client's balance
    UPDATE member m
    SET m.balance = m.balance - totalPayment
    WHERE m.memberID = NEW.clientID;

    -- Get the start of the first week of working (Monday) for the start date of the contract
    SET currentDate = NEW.startDate;
    SET startOfWeek = DATE_SUB(currentDate, INTERVAL WEEKDAY(currentDate) DAY);  -- Get the Monday
    SET endOfWeek = DATE_ADD(startOfWeek, INTERVAL 6 DAY);  -- Get Sunday

    -- Loop through each week between startDate and endDate and ensure they exist in weeks table for updating available hours later
    WHILE startOfWeek <= NEW.endDate DO
        -- Check if the week already exists in the weeks table for this caretaker
        IF NOT EXISTS (SELECT 1 FROM weeks w WHERE w.caretakerID = NEW.caretakerID AND w.startOfWeek = startOfWeek) THEN
            -- Insert the missing week with the available hours from the caretaker
            INSERT INTO weeks (startOfWeek, endOfWeek, caretakerID, totalHoursAvailable)
            VALUES (startOfWeek, endOfWeek, NEW.caretakerID, (SELECT m.availability FROM member m WHERE m.memberID = NEW.caretakerID));
        END IF;

        -- Iterate to the next week
        SET startOfWeek = DATE_ADD(startOfWeek, INTERVAL 7 DAY);
        SET endOfWeek = DATE_ADD(endOfWeek, INTERVAL 7 DAY);
    END WHILE;
END;
//
DELIMITER ;

-- Compute the new average rating for caretaker when inserting a review
DELIMITER //
CREATE TRIGGER updateAverageRating
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    DECLARE avgRating DECIMAL(2,1);

    -- New average
    SELECT AVG(rating) INTO avgRating
    FROM reviews r
    WHERE r.caretakerID = NEW.caretakerID;

    -- Update the member's average rating
    UPDATE member m
    SET m.averageRating = avgRating
    WHERE m.memberID = NEW.caretakerID;
END;
//
DELIMITER ;

-- Set totalHoursAvailable to caretaker's availability when creating a new work week
DELIMITER //
CREATE TRIGGER setTotalHoursAvailableBeforeInsert
BEFORE INSERT ON weeks
FOR EACH ROW
BEGIN
    SET NEW.totalHoursAvailable = (SELECT m.availability FROM member m WHERE m.memberID = NEW.caretakerID);
END;
//
DELIMITER ;

-- Update the caretaker's available hours for each week after completing a contract
DELIMITER //
CREATE TRIGGER updateWeeksAvailability
AFTER INSERT ON contracts
FOR EACH ROW
BEGIN
    DECLARE currentDate DATE;
    DECLARE startOfWeek DATE;
    DECLARE endOfWeek DATE;
    DECLARE daysWorked INT;
    DECLARE hoursWorked INT;

    -- Get the start of the first week of working (Monday) for the start date of the contract
    SET currentDate = NEW.startDate;
    SET startOfWeek = DATE_SUB(currentDate, INTERVAL WEEKDAY(currentDate) DAY);

    -- Loop through each week between startDate and endDate
    WHILE startOfWeek <= NEW.endDate DO
        SET endOfWeek = DATE_ADD(startOfWeek, INTERVAL 6 DAY); -- Add 6 days to get Sunday

        -- Calculate the days worked in this week
        IF NEW.startDate >= startOfWeek AND NEW.endDate <= endOfWeek THEN
            SET daysWorked = DATEDIFF(NEW.endDate, NEW.startDate) + 1;
        ELSEIF NEW.startDate <= startOfWeek AND NEW.endDate >= endOfWeek THEN
            SET daysWorked = 7;
        ELSE
            SET daysWorked = DATEDIFF(LEAST(NEW.endDate, endOfWeek), GREATEST(NEW.startDate, startOfWeek)) + 1;
        END IF;

        -- Calculate the hours worked in this week
        SET hoursWorked = daysWorked * NEW.dailyHoursWorked;

        -- Update the total available hours for this week
        UPDATE weeks w
        SET w.totalHoursAvailable = w.totalHoursAvailable - hoursWorked
        WHERE w.caretakerID = NEW.caretakerID AND w.startOfWeek = startOfWeek;

        -- Move to the next week
        SET startOfWeek = DATE_ADD(startOfWeek, INTERVAL 7 DAY);
    END WHILE;
END;
//
DELIMITER ;

-- Ensure usernames are unique in the member table
DELIMITER //
CREATE TRIGGER makeUsernameUnique
BEFORE INSERT ON member
FOR EACH ROW
BEGIN
    DECLARE username_exists INT;

    SELECT COUNT(*) INTO username_exists
    FROM member
    WHERE username = NEW.username;

    IF username_exists > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Username already exists';
    END IF;
END;
//
DELIMITER ;

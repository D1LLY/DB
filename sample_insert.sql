USE Caregivers;

-- EXPECTED USAGE -- passwords HASHED HERE but == "123"
INSERT INTO member (username, passwd, address, phoneNumber, availability, numParents)
VALUES
('john', '$2y$10$jlOOz0s7TSHrLAbjAS/KP.u8E2J.NSmr3BFR57ABH3QNFf7DTm752', 'Orlando', '1234567890', 35, 1),
('jane', '$2y$10$eOpWkthQrB2YaGWmJYwr5euV90XwzHjWXtsh6AQIBXFt00Ol9owZy', 'Orlando', '9876543210', 44, 2),
('amy', '$2y$10$zVpjl13RoMkVSNAQd1a5NO9EqSbg57dWoucqY03dGjduea8cTap0i', 'Orlando', '1234567890', 35, 1),
('bryan', '$2y$10$7e.jjw1d3T01j7XDmo4Hxez69eNN0ClkIoGnvtsumxHii4CaoL8UK', 'Tampa', '1234567890', 35, 1),
('charlie', '$2y$10$qJtyW6A69eHaB8xCfZcMROdrff8grAoVAWhQOmS1CSHQozGAmXVMi', 'Miami', '1234567890', 35, 2),
('damian', '$2y$10$OFHko5We95b4Ec7bOYsWJO2yWmNwAvIPQr.3RQ14cPB7qhyHp9w6i', 'Tampa', '1234567890', 35, 2),
('esmeralda', '$2y$10$OFHko5We95b4Ec7bOYsWJO2yWmNwAvIPQr.3RQ14cPB7qhyHp9w6i', 'Gainsville', '1234567890', 0, 1),
('fiona', '$2y$10$OFHko5We95b4Ec7bOYsWJO2yWmNwAvIPQr.3RQ14cPB7qhyHp9w6i', 'Miami', '1234567890', 0, 1),
('german', '$2y$10$OFHko5We95b4Ec7bOYsWJO2yWmNwAvIPQr.3RQ14cPB7qhyHp9w6i', 'Orlando', '1234567890', 0, 2),
('hector', '$2y$10$OFHko5We95b4Ec7bOYsWJO2yWmNwAvIPQr.3RQ14cPB7qhyHp9w6i', 'Orlando', '1234567890', 0, 1),
('ignacio', '$2y$10$OFHko5We95b4Ec7bOYsWJO2yWmNwAvIPQr.3RQ14cPB7qhyHp9w6i', 'Orlando', '1234567890', 0, 1);

-- Insert contracts with updated schema
INSERT INTO contracts (caretakerID, clientID, startDate, endDate, dailyHoursWorked, status, requestID)
VALUES
(1, 2, '2010-11-04', '2010-11-15', 8, 'pending', 1),
(2, 1, '2023-11-15', '2023-12-06', 6, 'accepted', 2),
(1, 3, '2022-11-04', '2022-11-21', 5, 'denied', 3),
(4, 5, '2021-11-04', '2021-11-20', 7, 'pending', 4),
(5, 6, '2024-11-04', '2024-11-18', 4, 'accepted', 5),
(6, 7, '2027-11-04', '2027-11-26', 6, 'pending', 6);

-- Insert reviews
INSERT INTO reviews (caretakerID, memberID, contractID, rating, dateOfCompletion)
VALUES
(1, 2, 1, 4, '2010-11-15'),
(2, 1, 2, 5, '2023-12-06'),
(1, 3, 3, 2, '2022-11-21'),
(4, 5, 4, 5, '2021-11-20'),
(5, 6, 5, 3, '2024-11-18'),
(6, 7, 6, 4, '2027-11-26');

-- Insert parents
INSERT INTO parents (memberID, parentName, age, needs)
VALUES
(1, 'Mary Doe', 45, 'Help with daily activities'),
(2, 'Peter Smith', 60, 'Assistance with medication'),
(3, 'Jackie Baynes', 64, 'Feeding and mobility support'),
(4, 'Steven Baynes', 60, 'Daily health monitoring'),
(5, 'Ronald Washington', 55, 'Rehabilitation exercises'),
(6, 'Jamie Rivera', 64, 'Memory care activities'),
(7, 'Arup Guha', 54, 'General wellness and companionship');

-- Insert care requests with valid requestID
INSERT INTO care_requests (memberID, parentID, startDate, startTime, endDate, endTime)
VALUES
(2, 1, '2023-11-15', '08:00:00', '2023-12-06', '16:00:00'),
(3, 2, '2022-11-04', '09:00:00', '2022-11-21', '17:00:00'),
(4, 3, '2021-11-04', '10:00:00', '2021-11-20', '18:00:00'),
(5, 4, '2024-11-04', '08:00:00', '2024-11-18', '15:00:00'),
(6, 5, '2027-11-04', '07:00:00', '2027-11-26', '14:00:00');

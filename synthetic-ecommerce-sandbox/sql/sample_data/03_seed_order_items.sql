-- ============================================================
-- Sample Data: Order Items
-- Maps order_id → product_id with realistic product pairings
-- ============================================================

INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount_pct) VALUES
-- Order 1 (james.wilson - Jan 2022)
(1, 11, 1, 349.99, 0.00),
(1, 12, 1, 249.99, 0.00),
-- Order 2 (emma.johnson - Jan 2022)
(2, 6,  1, 1999.99, 0.00),
-- Order 3 (oliver.brown - Feb 2022)
(3, 1,  1, 1199.99, 0.00),
-- Order 4 (sophia.davis - Feb 2022)
(4, 29, 2, 150.00, 0.00),
(4, 31, 1, 70.00, 0.00),
-- Order 5 (liam.miller - Feb 2022)
(5, 33, 1, 399.99, 5.00),
-- Order 6 (ava.wilson - Mar 2022)
(6, 24, 2, 79.99, 0.00),
(6, 26, 1, 128.00, 0.00),
-- Order 7 (noah.moore - Mar 2022)
(7, 39, 3, 27.99, 0.00),
(7, 41, 2, 24.99, 0.00),
-- Order 8 (isabella.taylor - Mar 2022)
(8, 43, 2, 19.99, 0.00),
(8, 44, 1, 12.99, 0.00),
-- Order 9 (james.wilson - Apr 2022)
(9, 20, 3, 35.99, 0.00),
(9, 22, 1, 64.99, 0.00),
-- Order 10 (william.anderson - Apr 2022)
(10, 7,  1, 1799.99, 0.00),
-- Order 11 (mia.thomas - Apr 2022)
(11, 29, 1, 150.00, 0.00),
(11, 30, 1, 190.00, 0.00),
-- Order 12 (benjamin.jackson - Apr 2022)
(12, 13, 1, 329.99, 0.00),
-- Order 13 (emma.johnson - May 2022)
(13, 25, 1, 59.99, 0.00),
(13, 24, 1, 79.99, 0.00),
-- Order 14 (charlotte.white - May 2022)
(14, 11, 1, 349.99, 0.00),
-- Order 15 (oliver.brown - May 2022)
(15, 2,  1, 1299.99, 0.00),
-- Order 16 (elijah.harris - Jun 2022)
(16, 33, 1, 399.99, 0.00),
(16, 37, 1, 199.99, 0.00),
-- Order 17 (amelia.martin - Jun 2022)
(17, 39, 2, 27.99, 0.00),
(17, 40, 1, 19.99, 0.00),
-- Order 18 (lucas.thompson - Jun 2022)
(18, 43, 3, 19.99, 0.00),
(18, 45, 1, 34.99, 0.00),
-- Order 19 (james.wilson - Jun 2022)
(19, 19, 1, 89.99, 0.00),
(19, 20, 2, 35.99, 0.00),
-- Order 20 (sophia.davis - Jul 2022)
(20, 29, 2, 150.00, 0.00),
-- Order 21 (liam.miller - Jul 2022)
(21, 12, 1, 249.99, 0.00),
-- Order 22 (harper.garcia - Jul 2022)
(22, 38, 1, 599.99, 5.00),
-- Order 23 (ava.wilson - Jul 2022)
(23, 1,  1, 1199.99, 0.00),
-- Order 24 (mason.martinez - Aug 2022)
(24, 6,  1, 1999.99, 0.00),
-- Order 25 (evelyn.robinson - Aug 2022)
(25, 26, 2, 128.00, 0.00),
(25, 25, 1, 59.99, 0.00),
-- Order 26 (noah.moore - Aug 2022)
(26, 39, 2, 27.99, 0.00),
(26, 41, 3, 24.99, 0.00),
-- Order 27 (logan.clark - Sep 2022)
(27, 47, 1, 179.99, 10.00),
(27, 48, 2, 29.99, 0.00),
-- Order 28 (isabella.taylor - Sep 2022)
(28, 43, 2, 19.99, 0.00),
-- Order 29 (abigail.rodriguez - Sep 2022)
(29, 29, 1, 150.00, 0.00),
(29, 31, 1, 70.00, 0.00),
-- Order 30 (william.anderson - Sep 2022)
(30, 11, 1, 349.99, 0.00),
-- Order 31 (mia.thomas - Oct 2022)
(31, 7,  1, 1799.99, 0.00),
-- Order 32 (benjamin.jackson - Oct 2022)
(32, 33, 1, 399.99, 5.00),
(32, 36, 1, 2495.00, 0.00),
-- Order 33 (ethan.lewis - Oct 2022)
(33, 19, 2, 89.99, 5.00),
(33, 22, 1, 64.99, 0.00),
-- Order 34 (emily.lee - Oct 2022)
(34, 15, 1, 349.99, 0.00),
-- Order 35 (emma.johnson - Nov 2022)
(35, 6,  1, 1999.99, 0.00),
-- Order 36 (charlotte.white - Nov 2022)
(36, 12, 1, 249.99, 0.00),
(36, 11, 1, 349.99, 0.00),
-- Order 37 (daniel.walker - Nov 2022)
(37, 1,  1, 1199.99, 0.00),
-- Order 38 (james.wilson - Black Friday 2022)
(38, 7,  1, 1799.99, 0.00),
(38, 11, 1, 349.99, 0.00),
-- Order 39 (oliver.brown - Black Friday 2022)
(39, 2,  1, 1299.99, 0.00),
-- Order 40 (liam.miller - Black Friday 2022)
(40, 33, 1, 399.99, 0.00),
(40, 37, 1, 199.99, 0.00),
-- Order 41 (elijah.harris - Dec 2022)
(41, 39, 3, 27.99, 0.00),
(41, 40, 2, 19.99, 0.00),
-- Order 42 (amelia.martin - Dec 2022)
(42, 16, 1, 2499.99, 0.00),
-- Order 43 (madison.hall - Dec 2022)
(43, 29, 2, 150.00, 0.00),
(43, 30, 1, 190.00, 0.00),
-- Order 44 (ava.wilson - Dec 2022)
(44, 24, 2, 79.99, 0.00),
(44, 27, 1, 64.99, 0.00),
-- Order 45 (aiden.allen - Dec 2022)
(45, 12, 1, 249.99, 0.00),
-- Order 46 (scarlett.young - Jan 2023)
(46, 29, 2, 150.00, 0.00),
(46, 31, 1, 70.00, 0.00),
-- Order 47 (jackson.hernandez - Jan 2023)
(47, 11, 1, 349.99, 5.00),
-- Order 48 (james.wilson - Jan 2023)
(48, 1,  1, 1199.99, 0.00),
-- Order 49 (noah.moore - Jan 2023)
(49, 39, 2, 27.99, 0.00),
(49, 41, 1, 24.99, 0.00),
-- Order 50 (aria.king - Feb 2023)
(50, 6,  1, 1999.99, 0.00),
-- Order 51 (emma.johnson - Feb 2023)
(51, 26, 1, 128.00, 5.00),
(51, 25, 2, 59.99, 0.00),
-- Order 52 (sebastian.wright - Feb 2023)
(52, 14, 1, 449.99, 0.00),
-- Order 53 (isabella.taylor - Feb 2023)
(53, 29, 1, 150.00, 0.00),
(53, 32, 1, 70.00, 0.00),
-- Order 54 (luna.lopez - Mar 2023)
(54, 38, 1, 599.99, 0.00),
-- Order 55 (carter.hill - Mar 2023)
(55, 47, 1, 179.99, 10.00),
(55, 49, 1, 24.99, 0.00),
-- Order 56 (oliver.brown - Mar 2023)
(56, 3,  1, 999.99, 0.00),
-- Order 57 (chloe.scott - Mar 2023)
(57, 24, 2, 79.99, 0.00),
-- Order 58 (wyatt.green - Apr 2023)
(58, 11, 1, 349.99, 0.00),
-- Order 59 (william.anderson - Apr 2023)
(59, 33, 1, 399.99, 5.00),
-- Order 60 (penelope.adams - Apr 2023)
(60, 20, 3, 35.99, 0.00),
(60, 19, 1, 89.99, 0.00),
-- Order 61 (sophia.davis - Apr 2023)
(61, 29, 2, 150.00, 0.00),
-- Order 62 (julian.baker - May 2023)
(62, 7,  1, 1799.99, 0.00),
-- Order 63 (liam.miller - May 2023)
(63, 12, 1, 249.99, 0.00),
(63, 13, 1, 329.99, 0.00),
-- Order 64 (layla.gonzalez - May 2023)
(64, 43, 2, 19.99, 0.00),
(64, 45, 1, 34.99, 0.00),
-- Order 65 (mia.thomas - May 2023)
(65, 2,  1, 1299.99, 0.00),
-- Order 66 (grayson.nelson - Jun 2023)
(66, 37, 1, 199.99, 0.00),
-- Order 67 (ava.wilson - Jun 2023)
(67, 24, 1, 79.99, 0.00),
(67, 27, 1, 64.99, 0.00),
-- Order 68 (riley.carter - Jun 2023)
(68, 29, 2, 150.00, 5.00),
-- Order 69 (benjamin.jackson - Jul 2023)
(69, 12, 1, 249.99, 0.00),
-- Order 70 (zoey.perez - Jul 2023)
(70, 39, 3, 27.99, 0.00),
(70, 40, 2, 19.99, 0.00),
-- Order 71 (james.wilson - Jul 2023)
(71, 6,  1, 1999.99, 0.00),
-- Order 72 (ryan.perez - Jul 2023)
(72, 29, 1, 150.00, 0.00),
(72, 30, 1, 190.00, 0.00),
-- Order 73 (noah.moore - Aug 2023)
(73, 11, 1, 349.99, 0.00),
-- Order 74 (hannah.roberts - Aug 2023)
(74, 38, 1, 599.99, 0.00),
-- Order 75 (emma.johnson - Aug 2023)
(75, 1,  1, 1199.99, 5.00),
-- Order 76 (nora.turner - Aug 2023)
(76, 15, 1, 349.99, 0.00),
-- Order 77 (charlotte.white - Sep 2023)
(77, 7,  1, 1799.99, 0.00),
-- Order 78 (leo.phillips - Sep 2023)
(78, 39, 2, 27.99, 0.00),
(78, 41, 2, 24.99, 0.00),
-- Order 79 (isabella.taylor - Sep 2023)
(79, 29, 1, 150.00, 0.00),
-- Order 80 (william.anderson - Sep 2023)
(80, 3,  1, 999.99, 0.00),
-- Order 81 (zoe.campbell - Oct 2023)
(81, 2,  1, 1299.99, 0.00),
-- Order 82 (elijah.harris - Oct 2023)
(82, 11, 1, 349.99, 0.00),
(82, 12, 1, 249.99, 0.00),
-- Order 83 (luke.parker - Oct 2023)
(83, 38, 1, 599.99, 5.00),
-- Order 84 (william.anderson - Oct 2023)
(84, 33, 1, 399.99, 5.00),
-- Order 85 (amelia.martin - Nov 2023)
(85, 14, 1, 449.99, 0.00),
-- Order 86 (lily.evans - Nov 2023)
(86, 7,  1, 1799.99, 0.00),
-- Orders 87-90: Black Friday 2023
(87, 2,  1, 1299.99, 0.00),   -- sophia.davis
(87, 1,  1, 1199.99, 0.00),
(88, 6,  1, 1999.99, 0.00),   -- james.wilson
(89, 11, 1, 349.99,  0.00),   -- liam.miller
(89, 12, 1, 249.99,  0.00),
(90, 29, 2, 150.00,  0.00),   -- mia.thomas
(90, 30, 1, 190.00,  0.00),
-- Order 91 (isaac.edwards - Dec 2023)
(91, 47, 1, 179.99, 0.00),
(91, 48, 2, 29.99, 0.00),
-- Order 92 (lucas.thompson - Dec 2023)
(92, 16, 1, 2499.99, 0.00),
-- Order 93 (emma.johnson - Dec 2023)
(93, 24, 2, 79.99, 0.00),
(93, 26, 1, 128.00, 0.00),
-- Order 94 (eleanor.collins - Dec 2023)
(94, 29, 2, 150.00, 0.00),
-- Order 95 (ava.wilson - Dec 2023)
(95, 15, 1, 349.99, 0.00),
-- Order 96 (owen.stewart - Jan 2024)
(96, 38, 1, 599.99, 0.00),
-- Order 97 (violet.sanchez - Jan 2024)
(97, 29, 2, 150.00, 5.00),
(97, 31, 1, 70.00,  0.00),
-- Order 98 (james.wilson - Jan 2024)
(98, 1,  1, 1199.99, 0.00),
-- Order 99 (benjamin.jackson - Jan 2024)
(99, 11, 1, 349.99, 0.00),
-- Order 100 (josiah.morris - Feb 2024)
(100, 7,  1, 1799.99, 5.00),
-- Order 101 (oliver.brown - Feb 2024)
(101, 2,  1, 1299.99, 0.00),
-- Order 102 (stella.rogers - Feb 2024)
(102, 14, 1, 449.99, 0.00),
-- Order 103 (noah.moore - Feb 2024)
(103, 39, 2, 27.99, 10.00),
(103, 40, 2, 19.99, 0.00),
-- Order 104 (lincoln.reed - Mar 2024)
(104, 29, 2, 150.00, 0.00),
-- Order 105 (sophia.davis - Mar 2024)
(105, 38, 1, 599.99, 5.00),
-- Order 106 (hazel.cook - Mar 2024)
(106, 12, 1, 249.99, 0.00),
-- Order 107 (emma.johnson - Mar 2024)
(107, 24, 2, 79.99, 0.00),
(107, 25, 1, 59.99, 0.00),
-- Order 108 (jaxon.morgan - Apr 2024)
(108, 11, 1, 349.99, 0.00),
-- Order 109 (isabella.taylor - Apr 2024)
(109, 29, 1, 150.00, 0.00),
(109, 32, 1, 70.00,  0.00),
-- Order 110 (aurora.bell - Apr 2024)
(110, 15, 1, 349.99, 0.00),
-- Order 111 (liam.miller - Apr 2024)
(111, 6,  1, 1999.99, 0.00),
-- Order 112 (savannah.bailey - May 2024)
(112, 38, 1, 599.99, 0.00),
-- Order 113 (charlotte.white - May 2024)
(113, 7,  1, 1799.99, 0.00),
-- Order 114 (mateo.rivera - May 2024)
(114, 29, 2, 150.00, 5.00),
(114, 30, 1, 190.00, 0.00),
-- Order 115 (elijah.harris - May 2024)
(115, 11, 1, 349.99, 0.00),
(115, 13, 1, 329.99, 0.00),
-- Order 116 (sofia.cooper - Jun 2024)
(116, 2,  1, 1299.99, 0.00),
-- Order 117 (ava.wilson - Jun 2024)
(117, 1,  1, 1199.99, 0.00),
-- Order 118 (ezra.richardson - Jun 2024)
(118, 38, 1, 599.99, 5.00),
-- Order 119 (james.wilson - Jul 2024)
(119, 12, 1, 249.99, 0.00),
-- Order 120 (amelia.martin - Jul 2024)
(120, 16, 1, 2499.99, 0.00),
-- Order 121 (paisley.cox - Jul 2024)
(121, 39, 2, 27.99, 0.00),
(121, 40, 1, 19.99, 0.00),
-- Order 122 (william.anderson - Jul 2024)
(122, 11, 1, 349.99, 0.00),
-- Order 123 (ezekiel.howard - Aug 2024)
(123, 7,  1, 1799.99, 0.00),
-- Order 124 (lucas.thompson - Aug 2024)
(124, 15, 1, 349.99, 5.00),
-- Order 125 (emma.johnson - Aug 2024)
(125, 24, 2, 79.99, 0.00),
-- Order 126 (autumn.ward - Aug 2024)
(126, 29, 2, 150.00, 0.00),
(126, 31, 1, 70.00,  0.00),
-- Order 127 (mia.thomas - Sep 2024)
(127, 2,  1, 1299.99, 0.00),
-- Order 128 (oliver.brown - Sep 2024)
(128, 1,  1, 1199.99, 0.00),
-- Order 129 (hudson.torres - Sep 2024)
(129, 38, 1, 599.99, 0.00),
-- Order 130 (liam.miller - Sep 2024)
(130, 11, 1, 349.99, 5.00),
(130, 12, 1, 249.99, 0.00),
-- Order 131 (brooklyn.peterson - Oct 2024)
(131, 33, 1, 399.99, 0.00),
-- Order 132 (harper.garcia - Oct 2024)
(132, 7,  1, 1799.99, 0.00),
-- Order 133 (asher.gray - Oct 2024)
(133, 29, 2, 150.00, 5.00),
-- Orders 134-136: in-flight orders (Processing/Shipped)
(134, 1,  1, 1199.99, 0.00),
(135, 6,  1, 1999.99, 0.00),
(136, 12, 1, 249.99, 0.00);

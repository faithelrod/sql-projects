# SQL Projects

SQL-based data analysis projects completed during my Master of Science in Business Analytics at the University of Alabama.

---

## Projects

### Instacart Customer Behavior Analysis (`Final_Project.sql`)
**Course:** Database Management / Business Analytics, Fall 2025  
**Database:** MySQL (`instacart`)

A comprehensive analysis of the Instacart grocery dataset answering 16 business questions about customer ordering behavior, product performance, and purchasing patterns.

---

### Business Questions Answered

| # | Question |
|---|---------|
| 1 | How frequently do users place orders? (weekly, biweekly, monthly) |
| 2 | Average number of products per order — overall, weekly, and monthly users |
| 3 | Top 5 most reordered products by weekly purchasers |
| 4 | Relationship between reorder rate and add-to-cart position |
| 5 | User segmentation by reorder interval (5 segments) |
| 6 | Department with the most and fewest units ordered |
| 7 | Products that have never been ordered |
| 8 | Aisle with the most top-selling products |
| 9 | Products in the top-selling aisle that have never been reordered |
| 10 | Top 10 products most often added first to cart |
| 11 | Reorder likelihood of the top 10 most-ordered products |
| 12 | Organic vs. non-organic product sales comparison |
| 13 | Top 5 ordered products per department and per aisle |
| 14 | Day of the week with the highest and lowest order counts |
| 15 | Percentage of orders placed during daytime hours (8am–5pm) |
| 16 | Top 3 weekday/time combinations for reorders |

---

### Key Findings

- **Saturday** is the highest order day; most orders happen during **daytime hours**
- The **produce** department dominates in total units ordered
- Discounts and reorder behavior are closely tied to cart position
- Over **X%** of products in the top-selling aisle have never been reordered
- Organic products represent a significant share of total orders despite fewer SKUs

---

### SQL Techniques Used

- `CASE WHEN` for segmentation and conditional aggregation
- Window functions (`ROW_NUMBER() OVER PARTITION BY`)
- CTEs (`WITH` clauses) for multi-step logic
- Subqueries and correlated subqueries
- `LEFT JOIN` for identifying missing/unordered products
- `UNION ALL` for summary statistics

---

## How to Run

1. Set up a MySQL database and import the Instacart dataset
2. Select the database:
   ```sql
   USE instacart;
   ```
3. Run queries from `Final_Project.sql` sequentially or individually

> **Note:** The Instacart dataset is not included due to size. It can be found on [Kaggle](https://www.kaggle.com/datasets/psparks/instacart-market-basket-analysis).

---

## Author
**Faith Elrod** | MS Business Analytics, University of Alabama  
[LinkedIn](https://linkedin.com/in/faithelrod) | faith.elrod03@gmail.com

-- 1. Total salary expenditure and employee count per department (GROUP BY & JOIN)
SELECT 
    d.department_name,
    COUNT(e.employee_id) AS total_employees,
    SUM(e.salary) AS total_payroll,
    ROUND(AVG(e.salary), 2) AS average_salary
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_name
ORDER BY total_payroll DESC;

-- 2. Find employees earning above their department average (Subquery)
SELECT * 
FROM employees e
WHERE salary > (
    SELECT AVG(salary) 
    FROM employees 
    WHERE department_id = e.department_id
);

-- 3. Analyze execution plan for transaction lookups (EXPLAIN ANALYZE)
EXPLAIN ANALYZE
SELECT t.transaction_id, e.first_name, e.last_name, t.amount, t.transaction_date
FROM transactions t
JOIN employees e ON t.employee_id = e.employee_id
WHERE t.amount > 500.00;

-- 4. Active connections check (Database Administration view)
SELECT datname, usename, client_addr, state, query 
FROM pg_stat_activity 
WHERE datname = 'company_db';

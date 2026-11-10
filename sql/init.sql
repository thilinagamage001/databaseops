
-- 1. USER & PERMISSIONS MANAGEMENT

CREATE USER app_user WITH PASSWORD 'AppUserSecurePassword456!';

-- Grant connection and basic privileges on company_db
GRANT CONNECT ON DATABASE company_db TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;

-- 2. SCHEMA DEFINITION

DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    location VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    department_id INT REFERENCES departments(department_id) ON DELETE SET NULL,
    salary NUMERIC(10, 2) CHECK (salary > 0),
    hire_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(employee_id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL,
    transaction_type VARCHAR(20) CHECK (transaction_type IN ('BONUS', 'EXPENSE', 'SALARY_ADJUSTMENT')),
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- 3. INDEXING FOR PERFORMANCE

CREATE INDEX idx_employees_department ON employees(department_id);
CREATE INDEX idx_transactions_employee ON transactions(employee_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);

-- Grant table-level permissions to app_user
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;


-- 4. SEED SAMPLE DATA

INSERT INTO departments (department_name, location) VALUES
('Engineering', 'San Francisco'),
('DevOps & Infrastructure', 'Austin'),
('Cybersecurity', 'New York'),
('Finance', 'Chicago');

INSERT INTO employees (first_name, last_name, email, department_id, salary, hire_date) VALUES
('Alice', 'Vance', 'alice.vance@company.com', 1, 115000.00, '2023-01-15'),
('Bob', 'Martinez', 'bob.martinez@company.com', 1, 125000.00, '2022-05-10'),
('Charlie', 'Vane', 'charlie.vane@company.com', 2, 110000.00, '2023-03-01'),
('Diana', 'Prince', 'diana.prince@company.com', 3, 130000.00, '2021-11-20'),
('Ethan', 'Hunt', 'ethan.hunt@company.com', 4, 95000.00, '2024-02-10');

INSERT INTO transactions (employee_id, amount, transaction_type) VALUES
(1, 1500.00, 'BONUS'),
(2, 450.50, 'EXPENSE'),
(3, 1200.00, 'BONUS'),
(4, 3000.00, 'SALARY_ADJUSTMENT'),
(5, 250.00, 'EXPENSE'),
(1, 500.00, 'EXPENSE');

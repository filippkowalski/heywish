# PostgreSQL Style Guide for HeyWish

## General Principles
- Use lowercase for SQL reserved words
- Use consistent, descriptive identifiers
- Use white space and indentation for readability
- Store dates in ISO 8601 format with timezone
- Include comments for complex logic

## Naming Conventions
- Avoid SQL reserved words
- Use snake_case for tables and columns
- Prefer plural table names (users, collections, items)
- Use singular column names
- For foreign key references, use table name with '_id' suffix (user_id, collection_id)

## Table Guidelines
- Avoid prefixes like 'tbl_'
- Always add an 'id' column with 'uuid' primary key
- Add created_at and updated_at timestamps
- Create tables in 'public' schema
- Add comments describing the table purpose

## Column Best Practices
- Use singular names
- Use meaningful data types (uuid for ids, timestamptz for dates)
- Add NOT NULL constraints where appropriate
- Use CHECK constraints for data validation

## Security Guidelines
- Enable Row Level Security (RLS) on all tables
- Create granular policies for different user roles
- Separate policies for different actions (select, insert, update, delete)
- Include comments explaining policy rationale

## Query Formatting
- Keep short queries compact
- Use newlines for longer, more complex queries
- Add spaces for readability
- Use meaningful aliases
- Prefer Common Table Expressions (CTEs) for complex queries

## Migration Best Practices
- Name migrations: `YYYYMMDDHHMMSS_description.sql`
- Include header comments explaining purpose
- Add detailed comments for destructive commands
- Create indexes for foreign keys and frequently queried columns